#import "TGAttachmentSheetWindow.h"

#import "TGNotificationWindow.h"

@interface TGAttachmentSheetController : TGOverlayWindowViewController
{
}

@property (nonatomic, weak) TGAttachmentSheetWindow *attachmentSheetWindow;
@property (nonatomic, strong, readonly) TGAttachmentSheetView *attachmentSheetView;

@end

@implementation TGAttachmentSheetController

- (void)loadView
{
    [super loadView];
    self.view.userInteractionEnabled = true;
    
    _attachmentSheetView = [[TGAttachmentSheetView alloc] initWithFrame:self.view.frame];
    _attachmentSheetView.attachmentSheetWindow = _attachmentSheetWindow;
    _attachmentSheetView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_attachmentSheetView];
}

@end

@implementation TGAttachmentSheetWindow

- (instancetype)init
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self != nil)
    {
        self.windowLevel = UIWindowLevelStatusBar + 0.01f;
        TGAttachmentSheetController *controller = [[TGAttachmentSheetController alloc] init];
        controller.attachmentSheetWindow = self;
        self.rootViewController = controller;
    }
    return self;
}

- (TGAttachmentSheetView *)view
{
    [((TGAttachmentSheetController *)self.rootViewController) view];
    return ((TGAttachmentSheetController *)self.rootViewController).attachmentSheetView;
}

- (void)showAnimated:(bool)animated
{
    self.hidden = false;
    
    if (animated)
    {
        [[self view] animateIn];
    }
}

- (void)dismissAnimated:(bool)animated
{
    if (animated)
    {
        [[self view] animateOut:^
        {
            self.hidden = true;
        }];
    }
    else
    {
        self.hidden = true;
    }
}

@end
