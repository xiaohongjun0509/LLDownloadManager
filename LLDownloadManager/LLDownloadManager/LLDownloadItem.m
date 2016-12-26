//
//  LLDownloadItem.m
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/19.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import "LLDownloadItem.h"
#import "objc/runtime.h"
#import <CommonCrypto/CommonDigest.h>

@interface LLDownloadItem ()
@property (nonatomic, copy) NSString *md5Id;
@end

@implementation LLDownloadItem

- (instancetype)initWithDownloadPath:(NSString *)urlPath{
    if (self = [super init]) {
        _urlPath = urlPath;
        _state = LLDownloadStateReady;
//        _targetPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
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
        if ([downloadItem.md5Id isEqualToString:self.md5Id]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)md5Id{
    return [LLDownloadItem md5StringForString:self.urlPath];
}




#pragma mark - helper
+ (NSString *)md5StringForString:(NSString *)string {
    const char *str = [string UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (uint32_t)strlen(str), r);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
}
@end


