
//
//  DownloadManager.m
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/20.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import "DownloadManager.h"
#import "LLDownloadItem.h"
#import <CommonCrypto/CommonDigest.h>
#include <fcntl.h>

@interface DownloadManager ()<NSURLConnectionDelegate,NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSMutableDictionary *pathDictionary;
@property (nonatomic, strong) NSMutableDictionary *fileHandlerDictionary;
@property (nonatomic, strong) NSMutableDictionary *dataBufferDictionary;
@property (nonatomic, strong) NSMutableArray *downloadArray;

@end


@implementation DownloadManager

+ (NSThread *)downloadThread{
    static NSThread *_downloadThread;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloadThread = [[NSThread alloc] initWithBlock:^{
            NSRunLoop *runloop = [NSRunLoop currentRunLoop];
            [runloop addPort:[NSPort port] forMode:NSRunLoopCommonModes];
            [runloop run];
        }];
        [_downloadThread setName:@"LLDownloadThread"];
        [_downloadThread start];
    });
    return _downloadThread;
}

#pragma mark - life cycle
+ (instancetype)defaultManager{
    static dispatch_once_t onceToken;
    static DownloadManager *_manager;
    dispatch_once(&onceToken, ^{
        _manager = [[DownloadManager alloc] init];
    });
    return _manager;
}

- (instancetype)init{
    if (self = [super init]) {
        _concurrentCount = 1;//默认只能下载一个任务。
        _cacheBufferSize = 1024 * 1024;//默认开启1M的memory cache。
    }
    return self;
}

#pragma mark - operation
- (void)startDownloadWithItem:(LLDownloadItem *)downloadItem{
    NSURLRequest *request = [self buildRequest:downloadItem];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    //在子线程开启下载
    [connection performSelector:@selector(start) onThread:[self.class downloadThread] withObject:nil waitUntilDone:NO];
    downloadItem.connection = connection;
    self.pathDictionary[connection.description] = downloadItem.targetPath;
    [self.downloadArray addObject:downloadItem];
}

- (NSMutableURLRequest *)buildRequest:(LLDownloadItem *)downloadItem{
    NSString *downloadUrl = downloadItem.urlPath;
    NSString *fileName = [downloadUrl lastPathComponent];
    NSString *fullPath = [[self cacheFolder] stringByAppendingPathComponent:fileName];
    if (downloadItem.targetPath == nil) {
        downloadItem.targetPath = fullPath;
    }
    long long offset = 0;
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
       offset = [NSData dataWithContentsOfFile:fullPath].length;
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:downloadItem.urlPath] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:6];
    if (offset > 0) {
        NSString *range = [NSString stringWithFormat:@"bytes=%llu-",offset];
        [request addValue:range forHTTPHeaderField:@"Range"];
    }
    return request;
}


- (void)cancelDownloadWithItem:(LLDownloadItem *)downloadItem{
    [self.downloadArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        LLDownloadItem *item = obj;
        if ([item isEqual:downloadItem]) {
            *stop = YES;
            [item.connection cancel];
            [self cleanDownloadItem:downloadItem];
            NSLog(@"------cancel------");
        }
    }];
}

- (void)pauseDownloadWithItem:(LLDownloadItem *)downloadItem{
    [self.downloadArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        LLDownloadItem *item = obj;
        if ([item isEqual:downloadItem]) {
            *stop = YES;
            [item.connection cancel];//只是取消了
            NSLog(@"-----pause------");
        }
    }];
    
    [self.downloadArray removeObject:downloadItem];
}

- (void)cleanDownloadItem:(LLDownloadItem *)item{
    NSError *error = nil;
    NSFileHandle *handler = self.fileHandlerDictionary[item.connection.description];
    if (handler) {
        [handler closeFile];
        [self.fileHandlerDictionary removeObjectForKey:item.connection.description];
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:item.targetPath error:&error];
    if (error == nil) {
        NSLog(@"删除临时文件成功");
    }else{
        NSLog(@"删除临时文件失败");
    }
    [self.pathDictionary removeObjectForKey:item.connection.description];
    [self.downloadArray removeObject:item];
}



#pragma mark - delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"didReceiveResponse");
    NSString *downloadPath = self.pathDictionary[connection.description];
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadPath] == NO) {
        [[NSFileManager defaultManager] createFileAtPath:downloadPath contents:nil attributes:nil];
    }
    NSFileHandle *handler = [NSFileHandle fileHandleForWritingAtPath:downloadPath];
    self.fileHandlerDictionary[connection.description] = handler;
    self.dataBufferDictionary[connection.description] = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    
    NSMutableData *bufferData = self.dataBufferDictionary[connection.description];
    [bufferData appendData:data];
    if (bufferData.length > self.cacheBufferSize) {
        NSFileHandle *handler = self.fileHandlerDictionary[connection.description];
        [handler seekToEndOfFile];
        [handler writeData:bufferData];
        self.dataBufferDictionary[connection.description] = [NSMutableData data];
        NSLog(@"write data buffer length %lu ",(unsigned long)bufferData.length);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSString *key = connection.description;
    NSFileHandle *handler = self.fileHandlerDictionary[key];
    NSMutableData *bufferData = self.dataBufferDictionary[connection.description];
    if (bufferData.length > 0) {
        [handler seekToEndOfFile];
        [handler writeData:bufferData];
        [self.dataBufferDictionary removeObjectForKey:connection.description];
        NSLog(@"finish write data length %lu",(unsigned long)bufferData.length);
    }
    [handler closeFile];
    
#ifdef DEBUG
    NSData *data = [[NSData alloc] initWithContentsOfFile:self.pathDictionary[key]];
    NSLog(@"写入的文件的总的字节数是%lu",(unsigned long)data.length);
#endif
    
    [self.pathDictionary removeObjectForKey:key];
    [self.fileHandlerDictionary removeObjectForKey:key];
}


#pragma mark - private
- (NSString *)cacheFolder{
    NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return cacheFolder;
}

- (BOOL)canExecuteMoreDownloadItem{
#warning 任务先放在这里
    return YES;
}


#pragma mark - getter
- (NSMutableDictionary *)pathDictionary{
    if (_pathDictionary == nil) {
        _pathDictionary = [NSMutableDictionary dictionary];
    }
    return _pathDictionary;
}

- (NSMutableDictionary *)fileHandlerDictionary{
    if (_fileHandlerDictionary == nil) {
        _fileHandlerDictionary = [NSMutableDictionary dictionary];
    }
    return _fileHandlerDictionary;
}


-  (NSMutableArray *)downloadArray{
    if (_downloadArray == nil) {
        _downloadArray = [NSMutableArray array];
    }
    return _downloadArray;
}


- (NSMutableDictionary *)dataBufferDictionary{
    if (_dataBufferDictionary == nil) {
        _dataBufferDictionary = [NSMutableDictionary dictionary];
    }
    return _dataBufferDictionary;
}

#pragma mark - helper
+ (NSString *)md5StringForString:(NSString *)string {
    const char *str = [string UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (uint32_t)strlen(str), r);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    }
@end
