//
//  LLDownloadOperation.h
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/21.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LLDownloadItem.h"

static NSString *const kLLDownloadPauseNotification = @"LLDownloadPauseNotification";
static NSString *const kLLDownloadStartNotification = @"LLDownloadStartNotification";
static NSString *const kLLDownloadCancelNotification = @"LLDownloadCancelNotification";
static NSString *const kLLDownloadCompletedNotification = @"LLDownloadCompletedNotification";
static NSString *const kLLDownloadErrorNotification = @"LLDownloadErrorNotification";

static NSString *const kLLDownloadUpdateArchieveNotification = @"LLDownloadUpdateArchieveNotification";


@class LLDownloadItem;
@interface LLDownloadOperation : NSOperation

@property (nonatomic, strong) NSString *cacheFolder;
@property (nonatomic, assign) long long cacheBufferSize;

- (instancetype)initOperationWithItem:(LLDownloadItem *)item;

- (void)pause;
@end
