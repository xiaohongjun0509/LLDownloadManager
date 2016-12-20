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

#define PATH @"http://sw.bos.baidu.com/sw-search-sp/software/5062682326178/Baiduyun_mac_2.0.0.dmg"



@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (nonatomic, strong) NSMutableArray *urls;
@property (nonatomic, strong) LLDownloadItem *currentItem;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.urls = [NSMutableArray array];
    [self.urls addObject:@"http://nj02all01.baidupcs.com/file/f53ed1b592629a4ab8db9e14f353cd17?bkt=p3-000054ecfdf32a134c50bb26b07d628a0fc6&fid=1847281134-250528-142752429379424&time=1482201478&sign=FDTAXGERLBH-DCb740ccc5511e5e8fedcff06b081203-99jkUccMtVEP60yk88UI2bR5big%3D&to=nj2hb&fm=Nan,B,T,nc&sta_dx=123674022&sta_cs=&sta_ft=ccc&sta_ct=6&sta_mt=6&fm2=Nanjing02,B,T,nc&newver=1&newfm=1&secfm=1&flow_ver=3&pkey=000054ecfdf32a134c50bb26b07d628a0fc6&sl=81723471&expires=8h&rt=pr&r=497902716&mlogid=8220534862221085061&vuk=1847281134&vbdid=741220362&fin=04-racmulticastconnection.ccc&fn=04-racmulticastconnection.ccc&slt=pm&uta=0&rtype=1&iv=0&isw=0&dp-logid=8220534862221085061&dp-callid=0.1.1&csl=256&csign=T6ZYIp6GCquM%2FFzdvRi%2BmeMm9mM%3D"];
    [self.urls addObject:@"http://nj02all01.baidupcs.com/file/80bdbbeaf7303e708c086ac49535bc55?bkt=p3-00003f5e71ce413be8d2f4abcf9ee12b6163&fid=1847281134-250528-520260786882400&time=1482201488&sign=FDTAXGERLBH-DCb740ccc5511e5e8fedcff06b081203-zT%2FIOV156Mzh2aEks8x7MBcyBo8%3D&to=nj2hb&fm=Nan,B,T,nc&sta_dx=76146008&sta_cs=&sta_ft=ccc&sta_ct=6&sta_mt=6&fm2=Nanjing02,B,T,nc&newver=1&newfm=1&secfm=1&flow_ver=3&pkey=00003f5e71ce413be8d2f4abcf9ee12b6163&sl=81723471&expires=8h&rt=pr&r=626743103&mlogid=8220537448044037339&vuk=1847281134&vbdid=741220362&fin=08-rac%E6%93%8D%E4%BD%9C%E6%96%B9%E6%B3%95%E4%B9%8B%E6%98%A0%E5%B0%84.ccc&fn=08-rac%E6%93%8D%E4%BD%9C%E6%96%B9%E6%B3%95%E4%B9%8B%E6%98%A0%E5%B0%84.ccc&slt=pm&uta=0&rtype=1&iv=0&isw=0&dp-logid=8220537448044037339&dp-callid=0.1.1&csl=256&csign=T6ZYIp6GCquM%2FFzdvRi%2BmeMm9mM%3D"];
    
    [self.urls addObject:@"http://sw.bos.baidu.com/sw-search-sp/software/5062682326178/Baiduyun_mac_2.0.0.dmg"];
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

@end
