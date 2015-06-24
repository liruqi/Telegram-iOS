#import <UIKit/UIKit.h>

@class TGAttachmentSheetWindow;

@interface TGAttachmentSheetView : UIView

@property (nonatomic, weak) TGAttachmentSheetWindow *attachmentSheetWindow;

@property (nonatomic, strong) NSArray *items;

- (void)animateIn;
- (void)animateOut:(void (^)())completion;

@end
