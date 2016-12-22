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
#import "TableViewCell.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSMutableArray *urls;
@property (nonatomic, strong) NSMutableArray *items;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) LLDownloadItem *currentItem;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"TableViewCell" bundle:nil] forCellReuseIdentifier:@"TableViewCell"];
//    self.urls = [NSMutableArray array];
//    [self.urls addObject:@"http://jaist.dl.sourceforge.net/project/machoview/MachOView-2.4.9200.dmg"];
//    [self.urls addObject:@"http://m4.pc6.com/xuh3/BaiduNetdisk200.dmg"];
//    [self.urls addObject:@"http://sw.bos.baidu.com/sw-search-sp/software/5062682326178/Baiduyun_mac_2.0.0.dmg"];
//    self.items = [NSMutableArray array];
//    for (int i = 0; i < self.urls.count; i ++) {
//        LLDownloadItem *item = [[LLDownloadItem alloc] initWithDownloadPath:self.urls[i]];
//        [self.items addObject:item];
//    }    
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableViewCell"];
    LLDownloadItem *item = [LLDownloadManager defaultManager].downloadItemArray[indexPath.row];
    cell.item = item;
    __weak typeof(cell) wsCell = cell;
    item.progressBlock = ^(LLDownloadItem *item, long long read, long long total){
        wsCell.progressLabel.text = [NSString stringWithFormat:@"--%lld--%lld",read,total];
    };
    cell.startBlock = ^(LLDownloadItem *item){
        [[LLDownloadManager defaultManager] startDownloadWithItem:item];
    };
    
    cell.pauseBlock = ^(LLDownloadItem *item){
        [[LLDownloadManager defaultManager] pauseDownloadWithItem:item];
    };
    
    cell.cancelBlock = ^(LLDownloadItem *item){
        [[LLDownloadManager defaultManager] cancelDownloadWithItem:item];
    };
    
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 88;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [LLDownloadManager defaultManager].downloadItemArray.count;
}

@end
