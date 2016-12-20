//
//  TableViewCell.m
//  LLDownloadManager
//
//  Created by hongjunxiao on 2016/12/20.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import "TableViewCell.h"

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

@end
