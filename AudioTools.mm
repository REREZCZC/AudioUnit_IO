//
//  AudioTools.m
//  AudioUnit_IO
//
//  Created by ren zhicheng on 2017/11/23.
//  Copyright © 2017年 renzhicheng. All rights reserved.
//

#import "AudioTools.h"

AudioBufferList micInputBufferList;

@implementation AudioTools
@synthesize audioBuffer, audioUnit;

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

- (void) manageMicInputBuffer {
    micInputBufferList.mNumberBuffers = 1;
    micInputBufferList.mBuffers[0].mNumberChannels = 1;
    micInputBufferList.mBuffers[0].mDataByteSize = 1024 * sizeof(SInt16);
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
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
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
    
    CheckError(AudioUnitSetProperty(audioUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    kOutputBus,
                                    &outBusFormat,
                                    sizeof(outBusFormat)),
               "set audio outputBus streamFormat failed");
    
    //Set callback for input and output.
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = micInputCallback;
    callbackStruct.inputProcRefCon = (__bridge void*)self;
    
    CheckError(AudioUnitSetProperty(audioUnit,
                                    kAudioOutputUnitProperty_SetInputCallback,
                                    kAudioUnitScope_Global,
                                    kInputBus,
                                    &callbackStruct,
                                    sizeof(callbackStruct)),
               "set inputbus rendercallback failed");
    
    
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = (__bridge void*)self;
    
    CheckError(AudioUnitSetProperty(audioUnit,
                                    kAudioUnitProperty_SetRenderCallback,
                                    kAudioUnitScope_Global,
                                    kOutputBus,
                                    &callbackStruct,
                                    sizeof(callbackStruct)),
               "set output rendecallback failed");
    CheckError(AudioUnitSetProperty(audioUnit,
                                    kAudioUnitProperty_ShouldAllocateBuffer,
                                    kAudioUnitScope_Output,
                                    kInputBus,
                                    &flag,
                                    sizeof(flag)),
               "set audio unit should alloc buffer failed");
    //Create buffer for pass micphone data to play callback
    audioBuffer.mNumberChannels = 1;
    audioBuffer.mDataByteSize = 1024;
    audioBuffer.mData = malloc(1024);
    
    //init audioUint
    CheckError(AudioUnitInitialize(audioUnit), "initialize audio unit failed");
    
}

static OSStatus micInputCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    printf("lalalla\n");
    AudioTools *audioTools = (__bridge AudioTools*)inRefCon;
    SInt16 samples[inNumberFrames];
    memset(&samples, 0, sizeof(samples));
    micInputBufferList.mBuffers[0].mData = samples;

    CheckError(AudioUnitRender([audioTools audioUnit], ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &micInputBufferList), "micInput callback render failed");
               
//    [audioTools passBuffer:&micInputBufferList];
    
    return noErr;
}

- (void) passBuffer:(AudioBufferList *)audioBufferList {
    AudioBuffer sourceBuffer = audioBufferList->mBuffers[0];
    if (audioBuffer.mDataByteSize != sourceBuffer.mDataByteSize) {
        free(audioBuffer.mData);
        audioBuffer.mDataByteSize = sourceBuffer.mDataByteSize;
        audioBuffer.mData = malloc(sourceBuffer.mDataByteSize);
    }
    memcpy(audioBuffer.mData, audioBufferList->mBuffers[0].mData, audioBufferList->mBuffers[0].mDataByteSize);
}

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    
//    AudioTools *audioTools = (__bridge AudioTools*)inRefCon;
//    SInt16 micInterleavedBuffer[inNumberFrames * 2];
//    SInt16 *micBuffer = (SInt16 *)[audioTools audioBuffer].mData;
//
//
//    for (int i = 0; i < inNumberFrames ; i++) {
//        micInterleavedBuffer[2 * i] = micBuffer[i];
//        micInterleavedBuffer[2 * i + 1] = micBuffer[i];
//    }

//    for (int i = 0; i < ioData->mNumberBuffers ; i++) {
//        AudioBuffer buffer = ioData->mBuffers[i];
//        UInt32 size = MAX(buffer.mDataByteSize, [audioTools audioBuffer].mDataByteSize);
//        memcpy(buffer.mData, micInterleavedBuffer, size);
//        buffer.mDataByteSize = size;
//    }
    printf("play\n");
    return noErr;
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
        [self manageMicInputBuffer];
        [self initializeAudioUnit];
    }
    return self;
}


- (void)start {
    CheckError(AudioOutputUnitStart(audioUnit), "Audio unit start failed");
}

- (void)stop {
    CheckError(AudioOutputUnitStop(audioUnit), "Audiuo unit stop failed");
}
@end




























