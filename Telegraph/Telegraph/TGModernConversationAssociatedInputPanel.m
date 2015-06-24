#import "TGModernConversationAssociatedInputPanel.h"

@implementation TGModernConversationAssociatedInputPanel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        self.clipsToBounds = true;
    }
    return self;
}

- (CGFloat)preferredHeight
{
    return 75.0f;
}

@end
