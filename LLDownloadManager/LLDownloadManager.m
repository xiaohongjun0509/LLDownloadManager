//
//  LLDownloadManager.m
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/19.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import "LLDownloadManager.h"
#import "AFNetworking.h"
#import "AFDownloadRequestOperation.h"
#import "LLDownloadItem.h"

@interface LLDownloadManager ()
@property (nonatomic, strong) NSMutableArray *downloadTasks;

@end

@implementation LLDownloadManager
+ (instancetype)defaultManager{
    static dispatch_once_t onceToken;
    static LLDownloadManager *_manager;
    dispatch_once(&onceToken, ^{
        _manager = [[LLDownloadManager alloc] init];
    });
    return _manager;
}

+ (NSOperationQueue *)LLDownloadOperationQueue{
    static dispatch_once_t onceToken;
    static NSOperationQueue *_downloadQueue;
    dispatch_once(&onceToken, ^{
        _downloadQueue = [[NSOperationQueue alloc] init];
        _downloadQueue.maxConcurrentOperationCount = 1;//只支持同时下载一个。
    });
    return _downloadQueue;
}

#pragma mark - download related operation
- (void)startDownloadWithItem:(LLDownloadItem *)downloadItem{
        if ([self validToStartDownload:downloadItem]) {
                NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:downloadItem.urlPath] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5];
                AFDownloadRequestOperation *operation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:downloadItem.targetPath shouldResume:YES];
                [operation setProgressiveDownloadProgressBlock:^(AFDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
                    if (downloadItem.fileSize == 0) {
                        downloadItem.fileSize = totalBytesExpected;
                        downloadItem.totalSegment = totalBytesExpected % segmentLength == 0 ? totalBytesExpected / segmentLength : totalBytesExpected / segmentLength + 1;
                    }
                    if (downloadItem.progressBlock) {
                        downloadItem.progressBlock(operation.targetPath,totalBytesRead,totalBytesExpected);
                    }
                }];
            
                [operation setCompletionBlock:^{
                    [self.downloadTasks removeObject:downloadItem];
                }];
                downloadItem.downloadOperation = operation;
                [[LLDownloadManager LLDownloadOperationQueue] addOperation:operation];
                downloadItem.state = LLDownloadStateDownloading;
                [self.downloadTasks addObject:downloadItem];
        }else{
            __block LLDownloadItem *exitItem = nil;
            [self.downloadTasks enumerateObjectsUsingBlock:^(LLDownloadItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isEqual:downloadItem]) {
                    exitItem = obj;
                    *stop = YES;
                }
            }];
            if (exitItem) {
                  [exitItem.downloadOperation resume];
                  exitItem.state = LLDownloadStateDownloading;
            }
        }
}


- (void)pauseDownloadWithItem:(LLDownloadItem *)downloadItem{
    [self.downloadTasks enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        LLDownloadItem *item = obj;
        if ([downloadItem isEqual:item]) {
            [item.downloadOperation pause];
            item.state = LLDownloadStatePause;
            *stop = YES;
        }
    }];

    [self updateDownloadTasksState];
}

- (void)cancelDownloadWithItem:(LLDownloadItem *)downloadItem{
    [downloadItem.downloadOperation cancel];
    [self.downloadTasks removeObject:downloadItem];
    [self updateDownloadTasksState];
}

- (void)pauseAllDownloadTask{
    [self.downloadTasks enumerateObjectsUsingBlock:^(LLDownloadItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.downloadOperation pause];
    }];
    [self updateDownloadTasksState];
}
- (void)startAllDownloadTask{
    [self.downloadTasks enumerateObjectsUsingBlock:^(LLDownloadItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.downloadOperation resume];
    }];
    [self updateDownloadTasksState];
}
#pragma mark - 更新任务队列的状态。
- (void)updateDownloadTasksState{
    if ([NSKeyedArchiver archiveRootObject:self.downloadTasks toFile:[self downloadTasksStateSavePath]] == NO) {
        NSLog(@"update state fail");
    }else{
        NSLog(@"update state successful");
    }
    [self restoreDownloadTasksState];
}

- (void)restoreDownloadTasksState{
    NSData *data = [NSData dataWithContentsOfFile:[self downloadTasksStateSavePath]];
    self.downloadTasks = [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

#pragma mark - private
-(BOOL)validToStartDownload:(LLDownloadItem *)downloadItem{
    __block BOOL vaildToStart = YES;
    [self.downloadTasks enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        LLDownloadItem *downloadedItem = obj;
        if ([downloadItem isEqual:downloadedItem]) {
            vaildToStart = NO;
            *stop = YES;
            NSLog(@"当前的任务已经在下载中，无需重复下载");
        }
    }];
    return vaildToStart;
}


- (NSMutableArray *)downloadTasks{
    if (_downloadTasks == nil) {
        _downloadTasks = [NSMutableArray array];
    }
    return _downloadTasks;
}


- (NSString *)downloadTasksStateSavePath{
    NSString *savePathDict = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fileName = @"downloadTasksStateFile.archiver";
    NSString *fullName = [savePathDict stringByAppendingPathComponent:fileName];
    if(![[NSFileManager defaultManager] fileExistsAtPath:fullName]){
        [[NSFileManager defaultManager] createFileAtPath:fullName contents:nil attributes:nil];
    }
    return fullName;
}
@end
