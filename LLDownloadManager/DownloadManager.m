
//
//  DownloadManager.m
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/20.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import "DownloadManager.h"
#import "LLDownloadItem.h"

@interface DownloadManager ()<NSURLConnectionDelegate,NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSMutableDictionary *pathDictionary;
@property (nonatomic, strong) NSMutableDictionary *fileHandlerDictionary;
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

+ (instancetype)defaultManager{
    static dispatch_once_t onceToken;
    static DownloadManager *_manager;
    dispatch_once(&onceToken, ^{
        _manager = [[DownloadManager alloc] init];
    });
    return _manager;
}

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

- (NSString *)cacheFolder{
    NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return cacheFolder;
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
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    NSFileHandle *handler = self.fileHandlerDictionary[connection.description];
    [handler seekToEndOfFile];
    [handler writeData:data];
    NSLog(@"data length %d",data.length);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSString *key = connection.description;
    NSFileHandle *handler = self.fileHandlerDictionary[key];
    [handler closeFile];
    [self.pathDictionary removeObjectForKey:key];
    [self.fileHandlerDictionary removeObjectForKey:key];
    NSLog(@" finish");
}


#pragma mark - private

- (NSMutableDictionary *)pathDictionary
{
    if (_pathDictionary == nil) {
        _pathDictionary = [NSMutableDictionary dictionary];
    }
    return _pathDictionary;
}

- (NSMutableDictionary *)fileHandlerDictionary
{
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
@end
