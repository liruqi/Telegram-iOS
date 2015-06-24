#import "TGAttachmentSheetView.h"

@interface TGAttachmentSheetWindow : UIWindow

- (void)showAnimated:(bool)animated;
- (void)dismissAnimated:(bool)animated;

- (TGAttachmentSheetView *)view;

@end
