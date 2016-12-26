//
//  DownloadManager.h
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/20.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LLDownloadItem.h"

@interface LLDownloadManager : NSObject

@property (nonatomic, assign) NSInteger concurrentCount;
@property (nonatomic, assign) long long cacheBufferSize;
@property (nonatomic, assign) BOOL allowDownloadViaWWAN;
@property (nonatomic, strong) NSMutableArray *downloadItemArray;

+ (instancetype)defaultManager;
- (void)startDownloadWithItem:(LLDownloadItem *)downloadItem;
- (void)pauseDownloadWithItem:(LLDownloadItem *)downloadItem;
- (void)cancelDownloadWithItem:(LLDownloadItem *)downloadItem;

@end
