#import "TGAttachmentSheetItemView.h"

@class TGViewController;
@class TGAttachmentSheetRecentControlledButtonItemView;

@interface TGAttachmentSheetRecentItemView : TGAttachmentSheetItemView

@property (nonatomic, copy) void (^openCamera)();
@property (nonatomic, copy) void (^done)();

- (instancetype)initWithParentController:(TGViewController *)controller;

- (void)setMultifunctionButtonView:(TGAttachmentSheetRecentControlledButtonItemView *)multifunctionButtonView;
- (NSArray *)selectedAssets;

@end
