//
//  HZTwinkleStar.m
//  TwinkleStarExample
//
//  Created by Hector Zarate on 5/22/13.
//  Copyright (c) 2013 Hector Zarate. All rights reserved.
//

#import "HZTwinkleStar.h"
#import <AVFoundation/AVFoundation.h>

#pragma mark - Constants

CGFloat kDefaultFrequency = 0.0;


#pragma mark - Other Functions Headers

NSTimeInterval TimeIntervalForFrequency(CGFloat frequency_in_hz);


@interface HZTwinkleStar ()

@property (nonatomic, weak) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) NSTimer *frequencyTimer;
@property (nonatomic, unsafe_unretained) BOOL flashLEDOn;

-(void)setTorchMode:(AVCaptureTorchMode)paramTorchMode;

@end


@implementation HZTwinkleStar

#pragma mark - Initializers

-(id)init
{
    // Discussion: Enforce the single instance in init?
    
    self = [super init];
    
    if (self)
    {
        _flashFrequency = kDefaultFrequency;
        _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    return self;
}

+(HZTwinkleStar *)sharedTwinkleStar
{
    static HZTwinkleStar *_StaticTwinkleStar = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _StaticTwinkleStar = [[self alloc] init];
    });
    
    return _StaticTwinkleStar;
}

#pragma mark - Flash LED operations

-(void)turnFlashLEDOn
{
    self.flashLEDOn = YES;
    
    if ([self isFlashLEDAvailable])
    {
        [self setTorchMode:AVCaptureTorchModeOn];
        
        [self startTimer];  
    }
}

-(void)turnFlashLEDOff
{
    [self stopTimer];
    
    self.flashLEDOn = NO;
    
    if ([self isFlashLEDAvailable])
    {
        [self setTorchMode:AVCaptureFlashModeOff];
    }
}


#pragma mark - Private Methods

-(void)startTimer
{    
    if (!self.frequencyTimer &&
        self.flashFrequency != 0.0)
    {
        self.frequencyTimer = [NSTimer timerWithTimeInterval:TimeIntervalForFrequency(self.flashFrequency)
                                                      target:self
                                                    selector:@selector(toggleTorchModeWithTimer:)
                                                    userInfo:nil
                                                     repeats:YES];
        
        [[NSRunLoop mainRunLoop] addTimer:self.frequencyTimer forMode:NSRunLoopCommonModes];
    }
}

-(void)stopTimer
{
    // Discussion: Ensure call is made from same thread as -startTimer ?
    
    [self.frequencyTimer invalidate];
    self.frequencyTimer = nil;
}

-(void)restartTimer
{
    [self stopTimer];
    [self startTimer];
}

-(void)setTorchMode:(AVCaptureTorchMode)paramTorchMode
{
    [self.captureDevice lockForConfiguration:nil];
    
    [self.captureDevice setTorchMode:paramTorchMode];
    
    [self.captureDevice unlockForConfiguration];
}

-(void)toggleTorchModeWithTimer:(NSTimer *)paramTimer
{
    if ([self.captureDevice isTorchActive])
    {
        [self setTorchMode:AVCaptureTorchModeOff];
    }
    else
    {
        [self setTorchMode:AVCaptureTorchModeOn];
    }
}

-(void)toggleTorchModeToMatchFlashLEDFlag
{
    if (self.flashLEDOn != [self.captureDevice isTorchActive])
    {
        [self toggleTorchModeWithTimer:nil];
    }
}

#pragma mark - Custom Accessors

-(void)setFlashFrequency:(CGFloat)paramFlashFrequency
{
    _flashFrequency = paramFlashFrequency;
    
    if (self.flashLEDOn)    
    {
        [self restartTimer];
    }
    
    if (_flashFrequency == 0.0)
    {
        [self toggleTorchModeToMatchFlashLEDFlag];
    }
}

-(BOOL)isFlashLEDAvailable
{
    BOOL result = ([self.captureDevice hasTorch] &&
                   [self.captureDevice isTorchAvailable]);
    
    return result;
}

@end


#pragma mark - Other Functions

NSTimeInterval TimeIntervalForFrequency(CGFloat frequency_in_hz)
{
    /*  period[s] = 1 / frequency[hz]   */
    
    if (frequency_in_hz == 0.0)
    {
        return DBL_MAX;
    }
    
    NSTimeInterval periodInterval = 1.0 / fabs(frequency_in_hz);
    
    return periodInterval;
}