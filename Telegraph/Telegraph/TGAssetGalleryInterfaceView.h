#import <UIKit/UIKit.h>

#import "TGModernGalleryInterfaceView.h"

@interface TGAssetGalleryInterfaceView : UIView <TGModernGalleryInterfaceView>

@property (nonatomic, copy) void (^itemSelected)(id<TGModernGalleryItem>);
@property (nonatomic, copy) bool (^isItemSelected)(id<TGModernGalleryItem>);
@property (nonatomic, copy) void (^donePressed)(id<TGModernGalleryItem>);

- (void)updateSelectionInterface:(NSUInteger)selectedCount animated:(bool)animated;

@end
