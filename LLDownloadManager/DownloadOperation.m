//
//  DownloadOperation.m
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/21.
//  Copyright © 2016年 XHJ. All rights reserved.
//

/*
 自定义NSOperation实现下载的功能。
 */

#import "DownloadOperation.h"

@interface DownloadOperation ()<NSURLConnectionDataDelegate>
@property (nonatomic, strong) LLDownloadItem *downloadItem;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *bufferData;
@end

@implementation DownloadOperation

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

- (instancetype)initOperationWithItem:(LLDownloadItem *)item{
    if (self = [super init]) {
        _downloadItem = item;
        _cacheBufferSize = 1024 * 1024;
    }
    return self;
}

- (void)start{
    NSURLRequest *request = [self buildRequest:self.downloadItem];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [self.connection performSelector:@selector(start) onThread:[self.class downloadThread] withObject:nil waitUntilDone:NO];
}


- (void)pause{
    [self.connection cancel];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kLLDownloadPauseNotification object:nil userInfo:@{kUserInfo : self.downloadItem}];
    });
}

- (void)cancel{
    [self.connection cancel];
    [self cleanDownloadItem:self.downloadItem];
    dispatch_async(dispatch_get_main_queue(), ^{
         [[NSNotificationCenter defaultCenter] postNotificationName:kLLDownloadCancelNotification object:nil userInfo:@{kUserInfo : self.downloadItem}];
    });
}

#pragma mark - delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"didReceiveResponse");
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.downloadItem.targetPath] == NO) {
        [[NSFileManager defaultManager] createFileAtPath:self.downloadItem.targetPath contents:nil attributes:nil];
    }
    self.bufferData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [self.bufferData appendData:data];
    if (self.bufferData.length > self.cacheBufferSize) {
        NSFileHandle *handler = [NSFileHandle fileHandleForWritingAtPath:self.downloadItem.targetPath];
        [handler seekToEndOfFile];
        [handler writeData:self.bufferData];
        NSLog(@"write data buffer length %lu ",(unsigned long)self.bufferData.length);
        self.bufferData = [NSMutableData data];
    }
    
    NSLog(@"---%@----%d",self.downloadItem.md5Id,data.length);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSFileHandle *handler = [NSFileHandle fileHandleForWritingAtPath:self.downloadItem.targetPath];
    if (self.bufferData.length > 0) {
        [handler seekToEndOfFile];
        [handler writeData:self.bufferData];
        NSLog(@"finish write data length %lu",(unsigned long)self.bufferData.length);
    }
    [handler closeFile];
    
#ifdef DEBUG
    NSData *data = [[NSData alloc] initWithContentsOfFile:self.downloadItem.targetPath];
    NSLog(@"写入的文件的总的字节数是%lu",(unsigned long)data.length);
#endif
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kLLDownloadCompletedNotification object:nil userInfo:@{kUserInfo : self.downloadItem}];
    });
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSFileHandle *handler = [NSFileHandle fileHandleForWritingAtPath:self.downloadItem.targetPath];
    [handler closeFile];
    dispatch_async(dispatch_get_main_queue(), ^{
        
    });
}



#pragma mark - private
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

- (void)cleanDownloadItem:(LLDownloadItem *)item{
    NSError *error = nil;
    NSFileHandle *handler = [NSFileHandle fileHandleForWritingAtPath:self.downloadItem.targetPath];
    if (handler) {
        [handler closeFile];
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:item.targetPath error:&error];
    if (error == nil) {
        NSLog(@"删除临时文件成功");
    }else{
        NSLog(@"删除临时文件失败");
    }
}

#pragma mark - getter
- (NSString *)cacheFolder{
    NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return cacheFolder;
}
@end
