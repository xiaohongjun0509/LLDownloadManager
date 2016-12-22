//
//  TestOperation.m
//  LLDownloadManager
//
//  Created by xiaohongjun on 2016/12/22.
//  Copyright © 2016年 XHJ. All rights reserved.
//

#import "TestOperation.h"

@implementation TestOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (void)start{
    if([self isCancelled]){
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    for (int i = 0; i < 10; i++) {
        [NSThread sleepForTimeInterval:1];
        NSLog(@"%d - /n",i);
    }
    
}
@end
