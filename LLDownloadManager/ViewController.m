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
#import "DownloadManager.h"
#import "TableViewCell.h"

#define PATH @"http://sw.bos.baidu.com/sw-search-sp/software/5062682326178/Baiduyun_mac_2.0.0.dmg"



@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (nonatomic, strong) NSMutableArray *urls;
@property (nonatomic, strong) NSMutableArray *items;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) LLDownloadItem *currentItem;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.urls = [NSMutableArray array];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"TableViewCell" bundle:nil] forCellReuseIdentifier:@"TableViewCell"];
    [self.urls addObject:@"http://jaist.dl.sourceforge.net/project/machoview/MachOView-2.4.9200.dmg"];
    [self.urls addObject:@"http://m4.pc6.com/xuh3/BaiduNetdisk200.dmg"];
    [self.urls addObject:@"http://sw.bos.baidu.com/sw-search-sp/software/5062682326178/Baiduyun_mac_2.0.0.dmg"];
    self.items = [NSMutableArray array];
    for (int i = 0; i < self.urls.count; i ++) {
        [self.items addObject:[[LLDownloadItem alloc] initWithDownloadPath:self.urls[i]]];
    }
}

- (IBAction)control:(id)sender {
    LLDownloadItem *item = [[LLDownloadItem alloc] initWithDownloadPath:PATH];
//    item.progressBlock = ^(NSString *target, NSInteger readSize, NSInteger totalSize){
//        self.sizeLabel.text = [[NSString alloc] initWithFormat:@"--read:%d--total:%d",readSize,totalSize];
//    };
    [[DownloadManager defaultManager] startDownloadWithItem:item];
    self.currentItem = item;
}
- (IBAction)cancel:(id)sender {
    [[DownloadManager defaultManager] cancelDownloadWithItem:self.currentItem];
}
- (IBAction)pause:(id)sender {
    
    [[DownloadManager defaultManager] pauseDownloadWithItem:self.currentItem];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableViewCell"];
    cell.item = self.items[indexPath.row];
    cell.startBlock = ^(LLDownloadItem *item){
        [[DownloadManager defaultManager] startDownloadWithItem:item];
    };
    
    cell.pauseBlock = ^(LLDownloadItem *item){
        [[DownloadManager defaultManager] pauseDownloadWithItem:item];
    };
    
    cell.cancelBlock = ^(LLDownloadItem *item){
        [[DownloadManager defaultManager] cancelDownloadWithItem:item];
    };
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.urls.count;
}

@end
