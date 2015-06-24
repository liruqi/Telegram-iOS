#import "TGModernGalleryItem.h"

#import "TGMediaPickerAsset.h"

@protocol TGGenericAssetGalleryItem <TGModernGalleryItem>

- (TGMediaPickerAsset *)asset;

@end
