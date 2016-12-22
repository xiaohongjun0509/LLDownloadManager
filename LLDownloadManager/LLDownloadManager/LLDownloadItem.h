//
//  LLDownloadItem.h
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/19.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const kLLDownloadUserInfo = @"kLLDownloadUserInfo";
static NSString *const kLLDownloadErrorInfo = @"kLLDownloadNotificationErrorInfo";

/*
 * 当前任务执行的状态
 */
typedef NS_ENUM(NSInteger,LLDownloadState){
    LLDownloadStateReady,
    LLDownloadStateWaiting,
    LLDownloadStateDownloading,
    LLDownloadStatePause,
    LLDownloadStateCompleted
};


@class LLDownloadItem;
typedef void(^LLDownloadProgressBlock)(LLDownloadItem *downloadItem, long long downloadedSize, long long totalSize);
typedef void(^LLDownloadComplitionBlock)(LLDownloadItem *downloadItem, NSError *error);


@class LLDownloadOperation;
@interface LLDownloadItem : NSObject

@property (nonatomic, strong, readonly) LLDownloadOperation *downloadOperation;
@property (nonatomic, assign) LLDownloadState state;

@property (nonatomic, assign) long long downloadedFileSize;
@property (nonatomic, assign) long long totalFileSize;
@property (nonatomic, copy) NSString *urlPath;
@property (nonatomic, copy) NSString *targetPath;
@property (nonatomic, copy) LLDownloadProgressBlock progressBlock;
@property (nonatomic, copy) LLDownloadComplitionBlock complitionBlock;

- (instancetype)initWithDownloadPath:(NSString *)path;

@end
