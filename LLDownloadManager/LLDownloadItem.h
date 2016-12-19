//
//  LLDownloadItem.h
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/19.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * 当前任务执行的状态
 * xhj
 */
typedef NS_ENUM(NSInteger,LLDownloadState){
    LLDownloadStateInit,
    LLDownloadStateWaiting,
    LLDownloadStateDownloading,
    LLDownloadStatePause,
    LLDownloadStateError
};

@class AFDownloadRequestOperation;
@interface LLDownloadItem : NSObject
@property (nonatomic, strong) AFDownloadRequestOperation *downloadOperation;
@property (nonatomic, assign, readonly) float downloadedFileSize;
@property (nonatomic, copy) NSString *urlPath;
@property (nonatomic, assign, readonly) LLDownloadState state;
@property (nonatomic, assign, readonly) NSInteger currentIndex;
@property (nonatomic, copy) NSString *targetPath;
@property (nonatomic, copy) void (^progressBlock)(NSString *targetPath, NSInteger downloadedSize, NSInteger    totalSize);

- (instancetype)initWithDownloadPath:(NSString *)path;

@end
