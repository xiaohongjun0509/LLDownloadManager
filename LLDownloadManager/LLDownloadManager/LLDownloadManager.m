
//
//  LLDownloadManager.m
//  LLLLDownloadManager
//
//  Created by xiaohongjun on 2016/12/20.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import "LLDownloadManager.h"
#import "LLDownloadItem.h"
#import "LLDownloadOperation.h"

@interface LLDownloadManager ()<NSURLConnectionDelegate,NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSMutableArray *downloadItemArray;
@property (nonatomic, strong) NSOperationQueue *downloadOperationQueue;
@end


@implementation LLDownloadManager

#pragma mark - life cycle
+ (instancetype)defaultManager{
    static dispatch_once_t onceToken;
    static LLDownloadManager *_manager;
    dispatch_once(&onceToken, ^{
        _manager = [[LLDownloadManager alloc] init];
    });
    return _manager;
}

- (instancetype)init{
    if (self = [super init]) {
        _concurrentCount = 1;//默认只能下载一个任务。
        _cacheBufferSize = 1024 * 1024;//默认开启1M的memory cache。
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateItemsArray:) name:kLLDownloadCompletedNotification object:nil];
    }
    return self;
}

- (void)dealloc{
    [self.downloadOperationQueue cancelAllOperations];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark - operation
- (void)startDownloadWithItem:(LLDownloadItem *)downloadItem{    
    __block BOOL existInArray = NO;
    [self.downloadItemArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        LLDownloadItem *item = obj;
        if ([item isEqual:downloadItem]) {
            *stop = YES;
            existInArray = YES;
        }
    }];
    if (!existInArray) {
        [self.downloadItemArray addObject:downloadItem];
        if([self canStartMoreDownloadItem]){
            [self startNextDownload];
        }
    }else{
        if([self canStartMoreDownloadItem]){
            [self startNextDownload];
        }
    }
}

- (void)startNextDownload{
    LLDownloadItem *currentItem = [self.downloadItemArray firstObject];
    if (currentItem) {
        if (currentItem.state == LLDownloadStateReady || currentItem.state == LLDownloadStateWaiting) {
            LLDownloadOperation *operation = [[LLDownloadOperation alloc] initOperationWithItem:currentItem];
            [self.downloadOperationQueue addOperation:operation];
        }
    }
}


- (void)cancelDownloadWithItem:(LLDownloadItem *)downloadItem{
    [downloadItem.downloadOperation cancel];
    [self.downloadItemArray removeObject:downloadItem];
}

- (void)pauseDownloadWithItem:(LLDownloadItem *)downloadItem{
   [downloadItem.downloadOperation pause];//只是取消了
}

#pragma mark - private
- (NSString *)cacheFolder{
    NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return cacheFolder;
}

- (BOOL)canStartMoreDownloadItem{
    __block BOOL canStart = YES;
    [self.downloadItemArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        LLDownloadItem *item = obj;
        if (item.state == LLDownloadStateDownloading) {
            canStart = NO;
            *stop = YES; //目前只允许一个任务来进行下载，目前主流的app都是同时只能进行一个任务来进行下载。
        }
    }];
    return canStart;
}


#pragma mark - getter
- (NSMutableArray *)downloadItemArray{
    if (_downloadItemArray == nil) {
        _downloadItemArray = [NSMutableArray array];
    }
    return _downloadItemArray;
}

- (NSOperationQueue *)downloadOperationQueue{
    if (_downloadOperationQueue == nil) {
        _downloadOperationQueue = [[NSOperationQueue alloc] init];
        _downloadOperationQueue.maxConcurrentOperationCount = self.concurrentCount;
        _downloadOperationQueue.name = @"LLLLDownloadOperationQueue";
    }
    return _downloadOperationQueue;
}

#pragma mark - observer
- (void)updateItemsArray:(NSNotification *)noti{
    LLDownloadItem *item = noti.userInfo[kLLDownloadUserInfo];
    __block NSInteger index = NSNotFound;
    [self.downloadItemArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        LLDownloadItem *downloadItem = obj;
        if([item isEqual:downloadItem]){
            index = idx;
            *stop = YES;
        }
    }];
    if (index != NSNotFound) {
        [self.downloadItemArray removeObjectAtIndex:index];
    }
    [self startNextDownload];
}

@end
