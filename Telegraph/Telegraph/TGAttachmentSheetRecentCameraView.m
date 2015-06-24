#import "TGAttachmentSheetRecentCameraView.h"

#import <AVFoundation/AVFoundation.h>

#import "ATQueue.h"

@interface TGAttachmentSheetRecentCameraView ()
{
    UIImageView *_iconView;
    AVCaptureSession *_session;
    AVCaptureVideoPreviewLayer *_videoLayer;
    UIView *_fadeView;
}

@end

@implementation TGAttachmentSheetRecentCameraView

+ (ATQueue *)cameraQueue
{
    static ATQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        queue = [[ATQueue alloc] init];
    });
    
    return queue;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        self.backgroundColor = [UIColor blackColor];
        
        _session = [[AVCaptureSession alloc] init];
        _session.sessionPreset = AVCaptureSessionPreset352x288;
        _videoLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
        _videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _videoLayer.frame = CGRectMake(0.0f, 0.0f, 78.0f, 78.0f);
        [self.layer insertSublayer:_videoLayer atIndex:0];
        
        _fadeView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 78.0f, 78.0f)];
        _fadeView.backgroundColor = [UIColor blackColor];
        [self addSubview:_fadeView];
        
        _iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AttachmentMenuInteractiveCameraIcon.png"]];
        [self addSubview:_iconView];
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)]];
        
        [self startPreview];
    }
    return self;
}

- (void)dealloc
{
    [self stopPreview];
}

- (void)tapGesture:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        [self stopPreviewSync];
        
        if (_pressed)
            _pressed();
    }
}

- (void)startPreview
{
    [[TGAttachmentSheetRecentCameraView cameraQueue] dispatch:^
    {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        if (input == nil)
            TGLog(@"ERROR: trying to open camera: %@", error);
        else
        {
            [_session addInput:input];
            [_session startRunning];
            
            TGDispatchOnMainThread(^
            {
                [UIView animateWithDuration:0.3 animations:^
                {
                    _fadeView.alpha = 0.5f;
                }];
            });
        }
    }];
}

- (void)stopPreview
{
    AVCaptureSession *session = _session;
    _session = nil;
    [[TGAttachmentSheetRecentCameraView cameraQueue] dispatch:^
    {
        [session stopRunning];
    }];
}

- (void)stopPreviewSync
{
    [[TGAttachmentSheetRecentCameraView cameraQueue] dispatch:^{
        [self stopPreview];
    } synchronous:true];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _iconView.frame = (CGRect){{CGFloor((self.frame.size.width - _iconView.frame.size.width) / 2.0f), CGFloor((self.frame.size.height - _iconView.frame.size.height) / 2.0f)}, _iconView.frame.size};
}

@end
