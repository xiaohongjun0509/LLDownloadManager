
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
@property (nonatomic, strong) NSOperationQueue *downloadOperationQueue;
@property (nonatomic, strong) NSLock *lock;
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
        _lock = [NSLock new];
        if ([self restoreDownloadInfoFromLocal]) {//本地恢复任务
            [self.downloadItemArray addObjectsFromArray:[self restoreDownloadInfoFromLocal]];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateItemsArray:) name:kLLDownloadCompletedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDownloadItemsToLocal) name:kLLDownloadUpdateArchieveNotification object:nil];
    }
    return self;
}

- (void)dealloc{
    [self.downloadOperationQueue cancelAllOperations];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - operation
- (void)startDownloadWithItem:(LLDownloadItem *)downloadItem{
    NSAssert(downloadItem, @"参数不能为空");
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
        [self updateDownloadItemsToLocal];
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
    [self updateDownloadItemsToLocal];
}

- (void)pauseDownloadWithItem:(LLDownloadItem *)downloadItem{
    [downloadItem.downloadOperation pause];//只是取消了
    [self updateDownloadItemsToLocal];
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

- (NSArray *)restoreDownloadInfoFromLocal{
     return [NSKeyedUnarchiver unarchiveObjectWithFile:[[self cacheFolder]  stringByAppendingPathComponent:@"localDownload.archiver"]];
}

- (void)updateDownloadItemsToLocal{
    [self.lock lock];
    [NSKeyedArchiver archiveRootObject:self.downloadItemArray toFile:[[self cacheFolder] stringByAppendingPathComponent:@"localDownload.archiver"]];
    [self.lock unlock];
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
    NSError *error = [noti.userInfo objectForKey:kLLDownloadErrorInfo];
    if (error) {//错误的处理
        
    }else if(item){
        [self.downloadItemArray removeObject:item];
    }
    [self startNextDownload];
}


@end
