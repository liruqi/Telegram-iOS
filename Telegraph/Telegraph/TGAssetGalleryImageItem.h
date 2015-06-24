#import "TGModernGalleryImageItem.h"

#import "TGGenericAssetGalleryItem.h"
#import "TGMediaPickerAsset.h"

@interface TGAssetGalleryImageItem : TGModernGalleryImageItem <TGGenericAssetGalleryItem>

- (instancetype)initWithAsset:(TGMediaPickerAsset *)asset;

@end
