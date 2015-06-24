#import "TGImageView.h"
#import "TGAssetImageManager.h"

@class TGMediaPickerAsset;

@interface TGAssetImageView : TGImageView

- (void)loadWithAsset:(TGMediaPickerAsset *)asset imageType:(TGAssetImageType)imageType size:(CGSize)size;
- (void)loadWithAsset:(TGMediaPickerAsset *)asset imageType:(TGAssetImageType)imageType size:(CGSize)size completionBlock:(void (^)(UIImage *result))completionBlock;

@end
