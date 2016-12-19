//
//  LLDownloadManager.h
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/19.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LLDownloadItem;

@interface LLDownloadManager : NSObject
+ (instancetype)defaultManager;
- (void)startDownloadWithItem:(LLDownloadItem *)downloadItem;
- (void)pauseDownloadWithItem:(LLDownloadItem *)downloadItem;
- (void)cancelDownloadWithItem:(LLDownloadItem *)downloadItem;
- (void)pauseAllDownloadTask;
- (void)startAllDownloadTask;
@end
