//
//  JKVideoInput.m
//  QCMobile
//
//  Created by Joris Kluivers on 5/18/13.
//  Copyright (c) 2013 Joris Kluivers. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "JKVideoInput.h"

/*!
 * Sample code related to video playback:
 * - Display link based
 *   http://developer.apple.com/library/ios/#samplecode/AVBasicVideoOutput/Listings/AVBasicVideoOutput_APLViewController_m.html#//apple_ref/doc/uid/DTS40013109-AVBasicVideoOutput_APLViewController_m-DontLinkElementID_8
 */

@interface JKVideoInput () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property(nonatomic, strong) CIImage *outputImage;

@property(nonatomic, strong) CIImage *latestFrame;
@end

@implementation JKVideoInput {
    dispatch_queue_t videoQueue;
    
    AVCaptureSession *session;
}

@dynamic inputCapture, outputImage;

- (id) initWithDictionary:(NSDictionary *)dict composition:(JKComposition *)composition
{
    self = [super initWithDictionary:dict composition:composition];
    if (self) {
        videoQueue = dispatch_queue_create("nl.kluivers.joris.VideoQueue", 0);
        
        session = [[AVCaptureSession alloc] init];
        session.sessionPreset = AVCaptureSessionPresetMedium;
        
        AVCaptureDevice *device = [AVCaptureDevice
                                   defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        [session addInput:input];
        
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        [output setSampleBufferDelegate:self queue:videoQueue];
        
        output.videoSettings = @{
            (id)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
        };
        
        [session addOutput:output];
    }
    return self;
}

- (void) startExecuting:(id<JKContext>)context
{
    [super startExecuting:context];
    
    [session startRunning];
}

- (void) execute:(id<JKContext>)context atTime:(NSTimeInterval)time
{
    __block CIImage *videoImage = nil;
    dispatch_sync(videoQueue, ^{
        videoImage = self.latestFrame;
    });
    self.outputImage = videoImage;
}

#pragma mark - Video handling

- (CGAffineTransform) transformForCurrentInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return CGAffineTransformMakeRotation(-M_PI_2);
        case UIInterfaceOrientationLandscapeLeft:
            return CGAffineTransformMakeRotation(M_PI);
        case UIInterfaceOrientationLandscapeRight:
            return CGAffineTransformIdentity;
        case UIInterfaceOrientationPortraitUpsideDown:
            return CGAffineTransformMakeRotation(M_PI_2);;
    }
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *frame = [CIImage imageWithCVPixelBuffer:imageBuffer];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    self.latestFrame = [frame imageByApplyingTransform:[self transformForCurrentInterfaceOrientation:orientation]];
}

@end
