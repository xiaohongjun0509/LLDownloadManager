//
//  LLDownloadOperation.m
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/21.
//  Copyright © 2016年 XHJ. All rights reserved.
//

/*
 自定义NSOperation实现下载的功能。
 */
#import <sys/xattr.h>
#import "LLDownloadOperation.h"
#include <sys/param.h>
#include <sys/mount.h>

@interface LLDownloadOperation ()<NSURLConnectionDataDelegate>
@property (nonatomic, weak) LLDownloadItem *downloadItem;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *bufferData;
@end


static inline NSString * LLKeyPathFromOperationState(LLDownloadState state) {
    switch (state) {
        case LLDownloadStateReady:
            return @"isReady";
        case LLDownloadStateDownloading:
            return @"isExecuting";
        case LLDownloadStateCompleted:
        case LLDownloadStatePause:
        case LLDownloadStateError:
            return @"isFinished";
        default: {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
            return @"state";
#pragma clang diagnostic pop
        }
    }
}

@implementation LLDownloadOperation

+ (NSThread *)downloadThread{
    static NSThread *_downloadThread;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloadThread = [[NSThread alloc] initWithTarget:self.class selector:@selector(setupRunLoop) object:nil];
        [_downloadThread setName:@"LLDownloadThread"];
        [_downloadThread start];
    });
    return _downloadThread;
}

+ (void)setupRunLoop{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSRunLoop *runloop = [NSRunLoop currentRunLoop];
        [runloop addPort:[NSPort port] forMode:NSRunLoopCommonModes];
        [runloop run];
    });
}

- (instancetype)initOperationWithItem:(LLDownloadItem *)item{
    if (self = [super init]) {
        _downloadItem = item;
        _cacheBufferSize = 1024 * 1024;
    }
    return self;
}

- (void)setState:(LLDownloadState)state {
    NSString *oldStateKey = LLKeyPathFromOperationState(self.downloadItem.state);
    NSString *newStateKey = LLKeyPathFromOperationState(state);
    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    self.downloadItem.state = state;
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];
}



/*
 将Operation加入到operationQueue之后，这个Operation并不会马上被调用，他的调度的顺序依赖优先级和当前的状态。
 为了避免在开始之前被取消了，先要判断是否取消掉了。
 */
- (void)start{
    if([self isCancelled]){
        return;
    }
    NSURLRequest *request = [self buildRequest:self.downloadItem];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [self.connection performSelector:@selector(start) onThread:[self.class downloadThread] withObject:nil waitUntilDone:NO];
    [self setState:LLDownloadStateDownloading];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kLLDownloadUpdateArchieveNotification object:nil userInfo:nil];
    });
}

- (void)pause{
    if ([self isCancelled]) {
        return;
    }
    [self.connection cancel];
    [self setState:LLDownloadStatePause];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kLLDownloadPauseNotification object:nil userInfo:@{kLLDownloadUserInfo : self.downloadItem}];
        [[NSNotificationCenter defaultCenter] postNotificationName:kLLDownloadUpdateArchieveNotification object:nil userInfo:nil];
    });
}

- (void)cancel{
    if ([self isCancelled]) {
        return;
    }
    [self.connection cancel];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kLLDownloadCancelNotification object:nil userInfo:@{kLLDownloadUserInfo : self.downloadItem}];
        [[NSNotificationCenter defaultCenter] postNotificationName:kLLDownloadUpdateArchieveNotification object:nil userInfo:nil];
    });
}

#pragma mark - delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
    if (self.downloadItem.fileName.length == 0) {
        self.downloadItem.fileName = res.suggestedFilename ? res.suggestedFilename : [self.downloadItem.targetPath lastPathComponent];
    }
    
    self.downloadItem.targetPath = [[self cacheFolder] stringByAppendingPathComponent:self.downloadItem.fileName];
    //获得当前下载内容的字节数。直接通过content-length来获取是有问题的。
    long long desireSize = 0;
    if([res.allHeaderFields.allKeys containsObject:@"Content-Range"]){
        NSString *contentRange = res.allHeaderFields[@"Content-Range"];
        NSUInteger index = [contentRange rangeOfString:@"/"].location;
        self.downloadItem.totalFileSize = [[contentRange substringFromIndex:index + 1] longLongValue];
        desireSize = [res.allHeaderFields[@"Content-Length"] longLongValue];
    }else{
        self.downloadItem.totalFileSize = [res.allHeaderFields[@"Content-Length"] longLongValue];
        desireSize = [res.allHeaderFields[@"Content-Length"] longLongValue];
    }
    if(![self checkSpace:desireSize]){
        [connection cancel];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kLLDownloadSpaceInfo object:nil];
        });
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.downloadItem.targetPath] == NO) {
        [[NSFileManager defaultManager] createFileAtPath:self.downloadItem.targetPath contents:nil attributes:nil];
    }
    self.bufferData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [self.bufferData appendData:data];
    if(self.downloadItem.downloadedFileSize < self.downloadItem.totalFileSize){
        self.downloadItem.downloadedFileSize += data.length;
    }
    if (self.bufferData.length > self.cacheBufferSize) {
        NSFileHandle *handler = [NSFileHandle fileHandleForWritingAtPath:self.downloadItem.targetPath];
        [handler seekToEndOfFile];
        [handler writeData:self.bufferData];
        NSLog(@"write data buffer length %lu ",(unsigned long)self.bufferData.length);
        self.bufferData = [NSMutableData data];
        //更新持久化的内容到本地
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kLLDownloadUpdateArchieveNotification object:nil];
        });
    }
    if (self.downloadItem.progressBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
           self.downloadItem.progressBlock(self.downloadItem,self.downloadItem.downloadedFileSize,self.downloadItem.totalFileSize); 
        });
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSFileHandle *handler = [NSFileHandle fileHandleForWritingAtPath:self.downloadItem.targetPath];
    NSData *downloadedData = [NSData dataWithContentsOfFile:self.downloadItem.targetPath];
    if (downloadedData.length < self.downloadItem.totalFileSize) {
        if (self.bufferData.length > 0) {
            [handler seekToEndOfFile];
            [handler writeData:self.bufferData];
            NSLog(@"finish write data length %lu",(unsigned long)self.bufferData.length);
        }
        [handler closeFile];
    }
#ifdef DEBUG
    NSData *data = [[NSData alloc] initWithContentsOfFile:self.downloadItem.targetPath];
    NSLog(@"写入的文件的总的字节数是%lu",(unsigned long)data.length);
#endif
    [self setState:LLDownloadStateCompleted];
    [super cancel];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kLLDownloadCompletedNotification object:nil userInfo:@{kLLDownloadUserInfo : self.downloadItem}];
        [[NSNotificationCenter defaultCenter] postNotificationName:kLLDownloadUpdateArchieveNotification object:nil];
    });
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSFileHandle *handler = [NSFileHandle fileHandleForWritingAtPath:self.downloadItem.targetPath];
    [handler closeFile];
    NSLog(@"error occur---->%@",error);
    [super cancel];
    [self setState:LLDownloadStateError];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kLLDownloadCompletedNotification object:nil userInfo:@{kLLDownloadUserInfo : self.downloadItem,kLLDownloadErrorInfo : error}];
         [[NSNotificationCenter defaultCenter] postNotificationName:kLLDownloadUpdateArchieveNotification object:nil];
    });
}

#pragma mark - private
- (NSMutableURLRequest *)buildRequest:(LLDownloadItem *)downloadItem{
    if (!downloadItem.targetPath) {
        downloadItem.targetPath = [[self cacheFolder] stringByAppendingPathComponent:downloadItem.fileName];
    }
    long long offset = 0;
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadItem.targetPath]) {
        offset = [NSData dataWithContentsOfFile:downloadItem.targetPath].length;
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:downloadItem.urlPath] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    if (offset > 0) {
        NSString *range = [NSString stringWithFormat:@"bytes=%llu-",offset];
        [request addValue:range forHTTPHeaderField:@"Range"];
    }
    downloadItem.downloadedFileSize = offset;
    return request;
}



- (BOOL)checkSpace:(long long)space{
    struct statfs buf;
    if(statfs("/var", &buf) >= 0){
        UInt64 fSize = (UInt64)buf.f_bsize * buf.f_bfree;
        return (fSize > 200 * pow(1024, 2)) ? YES : NO;//为了保护系统，所以预留200M的系统空间
    }
    return YES;
}

- (NSString *)cacheFolder{
    NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return cacheFolder;
}

#pragma mark - getter （和NSOperation执行相关的变量）
- (BOOL)isFinished{
    return self.downloadItem.state == LLDownloadStateCompleted || self.downloadItem.state == LLDownloadStatePause || [self isCancelled];
}

- (BOOL)isExecuting {
    return self.downloadItem.state == LLDownloadStateDownloading;
}

@end
