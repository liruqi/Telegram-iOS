#import <UIKit/UIKit.h>

@interface TGChangePhoneNumberHelpView : UIView

@property (nonatomic, copy) void (^changePhonePressed)();

- (void)setInsets:(UIEdgeInsets)insets;

@end
