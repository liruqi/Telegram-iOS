#import "TGMediaPickerAsset.h"

#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "TGStringUtils.h"

@interface TGMediaPickerAsset ()
{
    PHAsset *_asset;
    ALAsset *_legacyAsset;
    
    NSString *_cachedUniqueId;
    NSURL *_cachedLegacyAssetUrl;
}
@end

@implementation TGMediaPickerAsset

- (instancetype)initWithPHAsset:(PHAsset *)asset
{
    self = [super init];
    if (self != nil)
    {
        _asset = asset;
    }
    return self;
}

- (instancetype)initWithALAsset:(ALAsset *)asset
{
    self = [super init];
    if (self != nil)
    {
        _legacyAsset = asset;
    }
    return self;
}

- (NSString *)uniqueId
{
    if (!_cachedUniqueId)
    {
        if (_asset)
            _cachedUniqueId = self.persistentId;
        else if (_legacyAsset)
            _cachedUniqueId = self.url.absoluteString;
    }
    
    return _cachedUniqueId;
}

- (NSString *)persistentId
{
    if (_asset)
        return _asset.localIdentifier;
    
    return nil;
}

- (NSURL *)url
{
    if (_legacyAsset)
    {
        if (!_cachedLegacyAssetUrl)
            _cachedLegacyAssetUrl = [_legacyAsset defaultRepresentation].url;
        
        return _cachedLegacyAssetUrl;
    }
    
    return nil;
}

- (CGSize)dimensions
{
    if (_asset)
        return CGSizeMake(_asset.pixelWidth, _asset.pixelHeight);
    else if (_legacyAsset)
        return _legacyAsset.defaultRepresentation.dimensions;
    
    return CGSizeZero;
}

- (NSDate *)date
{
    if (_asset)
        return _asset.creationDate;
    else if (_legacyAsset)
        return [_legacyAsset valueForProperty:ALAssetPropertyDate];
    
    return nil;
}

- (bool)isVideo
{
    if (_asset)
        return (_asset.mediaType == PHAssetMediaTypeVideo);
    else if (_legacyAsset)
        return ([[_legacyAsset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]);
    
    return false;
}

- (NSTimeInterval)videoDuration
{
    if (_asset)
        return _asset.duration;
    else if (_legacyAsset)
        return [[_legacyAsset valueForProperty:ALAssetPropertyDuration] doubleValue];
    
    return 0;
}

- (PHAsset *)backingAsset
{
    return _asset;
}

- (ALAsset *)backingLegacyAsset
{
    return _legacyAsset;
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[TGMediaPickerAsset class]] && [((TGMediaPickerAsset *)object).uniqueId isEqualToString:self.uniqueId];
}

@end
