//
//  TableViewCell.h
//  LLDownloadManager
//
//  Created by hongjunxiao on 2016/12/20.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LLDownloadItem;
@interface TableViewCell : UITableViewCell
@property (nonatomic, copy) void (^startBlock)(LLDownloadItem *);
@property (nonatomic, copy) void (^pauseBlock)(LLDownloadItem *);
@property (nonatomic, copy) void (^cancelBlock)(LLDownloadItem *);
@property (nonatomic, strong) LLDownloadItem *item;
@end
