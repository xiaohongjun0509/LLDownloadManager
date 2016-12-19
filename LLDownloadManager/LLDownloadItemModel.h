//
//  LLDownloadItemModel.h
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/19.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LLDownloadItemModel : NSObject
@property (nonatomic, assign, readonly) float downloadedFileSize;


- (instancetype)initWithDownloadPath:(NSString *)path;


@end
