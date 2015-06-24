#import "TGAssetGalleryImageItem.h"

#import "TGImageView.h"
#import "TGAssetImageManager.h"
#import "TGImageUtils.h"

@interface TGAssetGalleryImageItem ()

@property (nonatomic, strong) TGMediaPickerAsset *asset;

@end

@implementation TGAssetGalleryImageItem

- (instancetype)initWithAsset:(TGMediaPickerAsset *)asset
{
    self = [super initWithLoader:^dispatch_block_t (TGImageView *imageView, bool synchronous)
    {
        CGSize screenSize = TGFitSize(asset.dimensions, CGSizeMake(1280, 1280));
        NSUInteger token = [TGAssetImageManager requestImageWithAsset:asset imageType:TGAssetImageTypeScreen size:screenSize synchronous:synchronous completionBlock:^(UIImage *image, __unused NSError *error)
        {
            if (image != nil)
                [imageView loadUri:@"embedded://" withOptions:@{TGImageViewOptionEmbeddedImage: image}];
        }];
        
        return ^
        {
            [TGAssetImageManager cancelRequestWithToken:token];
        };
    } imageSize:asset.dimensions];
    if (self != nil)
    {
        _asset = asset;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    return [super isEqual:object] && [object isKindOfClass:[TGAssetGalleryImageItem class]] && TGObjectCompare(_asset, ((TGAssetGalleryImageItem *)object)->_asset);
}

@end
