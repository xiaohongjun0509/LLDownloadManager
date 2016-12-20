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


static long long segmentLength = 100 * 1024;//分片的长度是100K

@class AFDownloadRequestOperation;

@interface LLDownloadItem : NSObject<NSCoding>
@property (nonatomic, strong) AFDownloadRequestOperation *downloadOperation;
@property (nonatomic, assign) long long downloadedFileSize;
@property (nonatomic, assign) long long fileSize;
@property (nonatomic, copy) NSString *urlPath;
@property (nonatomic, assign) LLDownloadState state;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger totalSegment;
@property (nonatomic, copy) NSString *targetPath;
@property (nonatomic, copy) void (^progressBlock)(NSString *targetPath, NSInteger downloadedSize, NSInteger    totalSize);

- (instancetype)initWithDownloadPath:(NSString *)path;





#pragma mark - used for Download Manager
@property (nonatomic, strong) NSURLConnection *connection;

@end
