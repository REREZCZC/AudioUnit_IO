//
//  AudioTools.m
//  AudioUnit_IO
//
//  Created by ren zhicheng on 2017/11/23.
//  Copyright © 2017年 renzhicheng. All rights reserved.
//

#import "AudioTools.h"

@implementation AudioTools
#define CheckError(result, operation) (_CheckError((result), (operation),strrchr(__FILE__, '/') +1,__LINE__))
static inline BOOL _CheckError(OSStatus error, const char *operation, const char *file, int line) {
    if (error != noErr) {
        int fourCC = CFSwapInt32HostToBig(error);
        if (isascii(((char *)&fourCC)[0]) && isascii(((char *)&fourCC)[1]) && isascii(((char *)&fourCC)[2])) {
            NSLog(@"%s:%d: %s: '%4.4s' (%d)",file,line,operation,(char*)&fourCC,(int)error);
        }else {
            NSLog(@"%s:%d: %s: %d",file, line,operation,(int)error);
        }
    }
    return YES;
}


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
    
    //find component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    CheckError(AudioComponentInstanceNew(inputComponent, &audioUnit), "audio component instance new failed");
    
    UInt32 flag = 1;
    //Set audioUnit IO
    CheckError(AudioUnitSetProperty(audioUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Input,
                                    kInputBus,
                                    &flag,
                                    sizeof(flag)),
               "set enable IO inputBus failed.");
    CheckError(AudioUnitSetProperty(audioUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Output,
                                    kOutputBus,
                                    &flag,
                                    sizeof(flag)),
               "set enable IO outputBus failed.");
    
    //create inputBus format
    //input is mono, headphone
    AudioStreamBasicDescription inBusFormat = [self setAudioFormatDescWithChannelCount:1];
    
    //set inputBus format
    //out from intput Unit (inputBus)
    CheckError(AudioUnitSetProperty(audioUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    kInputBus,
                                    &inBusFormat,
                                    sizeof(inBusFormat)),
               "set audio inputBus streamFormat failed");
    
    //create outputBus format
    //channelCount may be two, may be interleaved data.
    AudioStreamBasicDescription outBusFormat = [self setAudioFormatDescWithChannelCount:2];
}



- (AudioStreamBasicDescription) setAudioFormatDescWithChannelCount:(int )channelCount {
    AudioStreamBasicDescription audioFormat;
    
    audioFormat.mSampleRate = HWSampleRate;
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags = kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mChannelsPerFrame = channelCount;
    audioFormat.mBytesPerFrame = audioFormat.mChannelsPerFrame * 2;
    audioFormat.mBytesPerPacket = audioFormat.mFramesPerPacket * audioFormat.mBytesPerFrame;
    audioFormat.mBitsPerChannel = 16;
    
    return audioFormat;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        HWSampleRate = [self getCurrentHardwareSamplerate];
    }
    return self;
}
@end




























