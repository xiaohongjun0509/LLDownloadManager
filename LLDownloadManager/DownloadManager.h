//
//  DownloadManager.h
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/20.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LLDownloadItem.h"

@interface DownloadManager : NSObject
+ (instancetype)defaultManager;
- (void)startDownloadWithItem:(LLDownloadItem *)downloadItem;
@end
