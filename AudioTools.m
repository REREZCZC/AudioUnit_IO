//
//  AudioTools.m
//  AudioUnit_IO
//
//  Created by ren zhicheng on 2017/11/23.
//  Copyright © 2017年 renzhicheng. All rights reserved.
//

#import "AudioTools.h"

@implementation AudioTools

- (Float64)getCurrentHardwareSamplerate {
    Float64 currentDeviceSampleRate;
    //get hardware sample rate from avaudiosession.
    AVAudioSession *session = [AVAudioSession sharedInstance];
    return currentDeviceSampleRate = session.sampleRate;
}

- (void) initializeAudioUnit {
    //Audio component
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentFlags = 0;//must be zero
    desc.componentFlagsMask = 0;//must be zero s
}

@end




























