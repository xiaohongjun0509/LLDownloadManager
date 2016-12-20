
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
@end


@implementation DownloadManager
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
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    [connection start];
    downloadItem.connection = connection;
    self.pathDictionary[connection.description] = downloadItem.targetPath;
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

@end
