//
//  AudioTools.h
//  AudioUnit_IO
//
//  Created by ren zhicheng on 2017/11/23.
//  Copyright © 2017年 renzhicheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define kOutputBus 0
#define kInputBus 1

@interface AudioTools : NSObject {
    AudioComponentInstance audioUnit;
    float64 HWSampleRate;
}

@end
