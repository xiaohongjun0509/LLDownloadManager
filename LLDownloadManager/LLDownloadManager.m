//
//  LLDownloadManager.m
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/19.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import "LLDownloadManager.h"

@implementation LLDownloadManager
+ (instancetype)defaultManager{
    static dispatch_once_t onceToken;
    static LLDownloadManager *_manager;
    dispatch_once(&onceToken, ^{
        _manager = [[LLDownloadManager alloc] init];
    });
    return _manager;
}

+ (NSOperationQueue *) LLDownloadOperationQueue{
    static dispatch_once_t onceToken;
    static NSOperationQueue *_downloadQueue;
    dispatch_once(&onceToken, ^{
        _downloadQueue = [[NSOperationQueue alloc] init];
    });
    return _downloadQueue;
}


@end
