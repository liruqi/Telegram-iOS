#import "TGAssetImageView.h"

#import "TGAssetImageManager.h"

#import <MTProtoKit/MTTime.h>

@interface TGImageView (Private)

- (void)_commitImage:(UIImage *)image partial:(bool)partial loadTime:(NSTimeInterval)loadTime;

@end

@implementation TGAssetImageView
{
    NSUInteger _loadToken;
    volatile NSInteger _version;
}

- (void)loadWithAsset:(TGMediaPickerAsset *)asset imageType:(TGAssetImageType)imageType size:(CGSize)size
{
    [self loadWithAsset:asset imageType:imageType size:size completionBlock:nil];
}

- (void)loadWithAsset:(TGMediaPickerAsset *)asset imageType:(TGAssetImageType)imageType size:(CGSize)size completionBlock:(void (^)(UIImage *))completionBlock
{
    [self _maybeCancelOngoingRequest];
    
    __weak TGAssetImageView *weakSelf = self;
    NSInteger version = _version;
    
    _loadToken = [TGAssetImageManager requestImageWithAsset:asset
                                                  imageType:imageType
                                                       size:size
                                                synchronous:false
                                            completionBlock:^(UIImage *image, __unused NSError *error)
    {
        __strong TGAssetImageView *strongSelf = weakSelf;
        if (strongSelf != nil && strongSelf->_version == version)
        {
            strongSelf->_loadToken = 0;
            [strongSelf _commitImage:image partial:false loadTime:0.0];
          
            if (completionBlock != nil)
                completionBlock(image);
        }
    }];
}

- (void)reset
{
    [self _maybeCancelOngoingRequest];
    
    [self _commitImage:nil partial:false loadTime:0.0];
}

- (void)_maybeCancelOngoingRequest
{
    _version++;
    
    if (_loadToken != 0)
    {
        [TGAssetImageManager cancelRequestWithToken:_loadToken];
        _loadToken = 0;
    }
}

@end
