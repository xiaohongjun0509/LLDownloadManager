//
//  LLDownloadItem.m
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/19.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import "LLDownloadItem.h"
#import "objc/runtime.h"



@interface LLDownloadItem ()



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

/*
 这里不能用setValue：forKey在这种方式 这种会报错
 */
- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.downloadOperation forKey:/*NSStringFromSelector(@selector(downloadOperation))*/@"downloadOperation"];
    [aCoder encodeInteger:self.currentIndex forKey:NSStringFromSelector(@selector(currentIndex))];
    [aCoder encodeInteger:self.totalSegment forKey:NSStringFromSelector(@selector(totalSegment))];
    [aCoder encodeObject:self.urlPath forKey:NSStringFromSelector(@selector(urlPath))];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super init]){
        self.downloadOperation = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(downloadOperation))];
        self.currentIndex = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(currentIndex))];
        self.totalSegment = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(totalSegment))];
        self.urlPath = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(urlPath))];
    }
    return self;
}
@end


