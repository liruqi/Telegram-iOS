#import <UIKit/UIKit.h>

@interface TGAttachmentSheetRecentCameraView : UIView

@property (nonatomic, copy) void (^pressed)();

- (void)startPreview;
- (void)stopPreview;

@end
