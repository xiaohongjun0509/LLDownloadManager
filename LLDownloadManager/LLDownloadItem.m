//
//  LLDownloadItem.m
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/19.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import "LLDownloadItem.h"
#import "objc/runtime.h"

static float segmentLength = 100 * 1024;//分片的长度是100K

@interface LLDownloadItem ()<NSCoding>

@property (nonatomic, assign) float downloadedFileSize;
@property (nonatomic, assign) LLDownloadState state;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger totalSegment;

@end

@implementation LLDownloadItem

- (instancetype)initWithDownloadPath:(NSString *)urlPath{
    if (self = [super init]) {
        _urlPath = urlPath;
        _state = LLDownloadStateInit;
        _currentIndex = 0;
        _targetPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    }
    return self;
}

- (instancetype)initWithDownloadPath:(NSString *)path targetPath:(NSString *)targetPath{
    if (self = [self initWithDownloadPath:path]) {
        _targetPath = targetPath;
    }
    return self;
}

- (BOOL)isEqual:(id)object{
    if ([object isKindOfClass:self.class]) {
        LLDownloadItem *downloadItem = object;
        if ([downloadItem.urlPath isEqualToString:_urlPath]) {
            return YES;
        }
    }
    return NO;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder setValue:self.downloadOperation forKey:NSStringFromSelector(@selector(downloadOperation))];
    [aCoder setValue:@(self.currentIndex).stringValue forKey:NSStringFromSelector(@selector(currentIndex))];
    [aCoder setValue:@(self.totalSegment) forKey:NSStringFromSelector(@selector(totalSegment))];
    [aCoder setValue:self.urlPath forKey:NSStringFromSelector(@selector(urlPath))];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    LLDownloadItem *item = [[LLDownloadItem alloc] init];
    item.downloadOperation = [aDecoder valueForKey:NSStringFromSelector(@selector(downloadOperation))];
    item.currentIndex = [[aDecoder valueForKey:NSStringFromSelector(@selector(currentIndex))] integerValue];
    item.totalSegment = [[aDecoder valueForKey:NSStringFromSelector(@selector(totalSegment))] integerValue];
    item.urlPath = [[aDecoder valueForKey:NSStringFromSelector(@selector(urlPath))] stringValue];
    return item;
}
@end


