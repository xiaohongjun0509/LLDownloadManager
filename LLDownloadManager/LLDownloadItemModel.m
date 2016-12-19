//
//  LLDownloadItemModel.m
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/19.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import "LLDownloadItemModel.h"

@interface LLDownloadItemModel ()

@property (nonatomic, assign) float downloadedFileSize;
@property (nonatomic, copy, readonly) NSString *urlPath;

@end

@implementation LLDownloadItemModel

- (instancetype)initWithDownloadPath:(NSString *)urlPath{
    if (self = [super init]) {
        _urlPath = urlPath;
    }
    return self;
}



@end


