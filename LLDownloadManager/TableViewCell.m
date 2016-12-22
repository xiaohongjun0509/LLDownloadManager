//
//  TableViewCell.m
//  LLDownloadManager
//
//  Created by hongjunxiao on 2016/12/20.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import "TableViewCell.h"
#import "LLDownloadItem.h"

@implementation TableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}
- (IBAction)start:(id)sender {
    self.startBlock(self.item);    
}
- (IBAction)pause:(id)sender {
    self.pauseBlock(self.item);
}
- (IBAction)cancel:(id)sender {
    self.cancelBlock(self.item);
}

- (void)setItem:(LLDownloadItem *)item{
    _item = item;
    self.progressLabel.text = [NSString stringWithFormat:@"已下载:%lld<---> 文件大小:%lld",item.downloadedFileSize,item.totalFileSize];
}
@end
