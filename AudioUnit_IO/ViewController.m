//
//  ViewController.m
//  AudioUnit_IO
//
//  Created by ren zhicheng on 2017/11/23.
//  Copyright © 2017年 renzhicheng. All rights reserved.
//

#import "ViewController.h"
#import "AudioTools.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    AudioTools *tools = [[AudioTools alloc] init];
    [tools start];
}



@end
