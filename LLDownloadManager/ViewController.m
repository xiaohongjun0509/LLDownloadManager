//
//  ViewController.m
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/19.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import "ViewController.h"
#import "LLDownloadItem.h"
#import "LLDownloadManager.h"

#define PATH @"http://sw.bos.baidu.com/sw-search-sp/software/5062682326178/Baiduyun_mac_2.0.0.dmg"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)control:(id)sender {
    LLDownloadItem *item = [[LLDownloadItem alloc] initWithDownloadPath:PATH];
    item.progressBlock = ^(NSString *target, NSInteger readSize, NSInteger totalSize){
        NSLog(@"----%@---- %@-----%@", @"",@(readSize).stringValue, @(totalSize).stringValue);
    };
    [[LLDownloadManager defaultManager] startDownloadWithItem:item];
}
- (IBAction)pause:(id)sender {
     LLDownloadItem *item = [[LLDownloadItem alloc] initWithDownloadPath:PATH];
    [[LLDownloadManager defaultManager] pauseDownloadWithItem:item];
}

@end
