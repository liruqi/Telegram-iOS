#import "TGModernGalleryModel.h"

#import "TGWebSearchResultsGalleryInterfaceView.h"

@interface TGAssetGalleryModel : TGModernGalleryModel

@property (nonatomic, strong, readonly) TGWebSearchResultsGalleryInterfaceView *interfaceView;

- (instancetype)initWithItems:(NSArray *)items focusItem:(id<TGModernGalleryItem>)focusItem;

@end
