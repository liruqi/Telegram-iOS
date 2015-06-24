#import "TGMediaPickerAssetsLibrary.h"

#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "ATQueue.h"
#import "TGTimer.h"

#import "TGMediaPickerAsset.h"
#import "TGMediaPickerAssetsGroup.h"

@interface TGMediaPickerAssetsLibrary () <PHPhotoLibraryChangeObserver>
{
    ALAssetsLibrary *_assetsLibrary;
    PHPhotoLibrary *_photoLibrary;
    
    ATQueue *_queue;
    
    TGTimer *_libraryChangeDelayTimer;
}
@end

@implementation TGMediaPickerAssetsLibrary

- (instancetype)initForAssetType:(TGMediaPickerAssetType)assetType
{
    self = [super init];
    if (self != nil)
    {
        _assetType = assetType;
        
        _queue = [[ATQueue alloc] init];
        
        [_queue dispatch:^
        {
            if (iosMajorVersion() >= 8)
            {
                _photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
                [_photoLibrary registerChangeObserver:self];
            }
            else
            {
                _assetsLibrary = [[ALAssetsLibrary alloc] init];
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(assetsLibraryDidChange:)
                                                             name:ALAssetsLibraryChangedNotification
                                                           object:nil];
            }
        }];
    }
    return self;
}

- (void)dealloc
{
    if (_photoLibrary)
        [_photoLibrary unregisterChangeObserver:self];
    else if (_assetsLibrary)
        [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
    
    if (_libraryChangeDelayTimer)
    {
        [_libraryChangeDelayTimer invalidate];
        _libraryChangeDelayTimer = nil;
    }
}

- (void)fetchGroupsWithCompletionBlock:(void (^)(NSArray *, TGMediaPickerAuthorizationStatus, NSError *))completionBlock
{
    [_queue dispatch:^
    {
        NSMutableArray *assetGroups = [NSMutableArray array];
        
        if (_photoLibrary != nil)
        {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status)
            {
                if (status != PHAuthorizationStatusAuthorized)
                {
                    if (completionBlock)
                        completionBlock(nil, [self _authorizationStatus], nil);
                    return;
                }
                
                PHFetchResult *collections = [PHAssetCollection fetchTopLevelUserCollectionsWithOptions:nil];
                for (PHAssetCollection *collection in collections)
                {
                    PHFetchResult *fetchResult;
                    NSArray *latestAssets = [self _fetchLatestAssetsInCollection:collection fetchResult:&fetchResult];
                    
                    [assetGroups addObject:[[TGMediaPickerAssetsGroup alloc] initWithPHAssetCollection:collection
                                                                                           fetchResult:fetchResult
                                                                                          latestAssets:latestAssets]];
                }
                
                [self _findCameraRollAssetsGroupWithCompletionBlock:^(TGMediaPickerAssetsGroup *cameraRollAssetsGroup, __unused NSError *error)
                {
                    [assetGroups insertObject:cameraRollAssetsGroup atIndex:0];
                }];
                
                [assetGroups sortUsingFunction:TGMediaPickerAssetsGroupComparator context:nil];
                
                if (completionBlock)
                    completionBlock(assetGroups, [self _authorizationStatus], nil);
            }];
        }
        else if (_assetsLibrary != nil)
        {
            [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, __unused BOOL *stop)
            {
                if (group != nil)
                {
                    [group setAssetsFilter:[TGMediaPickerAssetsLibrary _assetsFilterForAssetType:_assetType]];
                    
                    NSArray *latestAssets = [self _fetchLatestAssetsInGroup:group];
                    
                    [assetGroups addObject:[[TGMediaPickerAssetsGroup alloc] initWithALAssetsGroup:group
                                                                                      latestAssets:latestAssets]];
                }
                else
                {
                    [assetGroups sortUsingFunction:TGMediaPickerAssetsGroupComparator context:nil];
                    
                    if (completionBlock)
                        completionBlock(assetGroups, [self _authorizationStatus], nil);
                }
            } failureBlock:^(NSError *error)
            {
                if (completionBlock)
                    completionBlock(nil, [self _authorizationStatus], error);
            }];
        }
    }];
}

- (void)fetchAssetsOfAssetsGroup:(TGMediaPickerAssetsGroup *)assetsGroup withCompletionBlock:(void (^)(NSArray *, TGMediaPickerAuthorizationStatus, NSError *))completionBlock
{
    [_queue dispatch:^
    {
        NSMutableArray *assets = [NSMutableArray array];
        
        if (_photoLibrary != nil)
        {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status)
            {
                if (status != PHAuthorizationStatusAuthorized)
                {
                    if (completionBlock)
                        completionBlock(nil, [self _authorizationStatus], nil);
                    return;
                }
                
                void (^enumerateAssetsInFetchResult)(PHFetchResult *, bool) = ^(PHFetchResult *fetchResult, bool isCameraRoll)
                {
                    for (PHAsset *asset in fetchResult)
                    {
                        if (iosMajorVersion() == 8 && iosMinorVersion() < 1)
                        {
                            //that's the only way to filter out stream photos on iOS < 8.1
                            if (!isCameraRoll || [[asset valueForKey:@"assetSource"] isEqualToNumber:@3] || _assetType == TGMediaPickerAssetVideoType)
                            {
                                [assets addObject:[[TGMediaPickerAsset alloc] initWithPHAsset:asset]];
                            }
                        }
                        else
                        {
                            [assets addObject:[[TGMediaPickerAsset alloc] initWithPHAsset:asset]];
                        }
                    }
                
                    if (completionBlock)
                        completionBlock(assets, [self _authorizationStatus], nil);
                };
                
                if (assetsGroup)
                {
                    enumerateAssetsInFetchResult(assetsGroup.backingFetchResult, assetsGroup.isCameraRoll);
                }
                else
                {
                    [self _findCameraRollAssetsGroupWithCompletionBlock:^(TGMediaPickerAssetsGroup *cameraRollAssetsGroup, NSError *error)
                    {
                        if (cameraRollAssetsGroup && error == nil)
                            enumerateAssetsInFetchResult(cameraRollAssetsGroup.backingFetchResult, true);
                    }];
                }
            }];
        }
        else if (_assetsLibrary != nil)
        {
            void (^enumerateAssetsInGroup)(ALAssetsGroup *) = ^(ALAssetsGroup *assetsGroup)
            {
                [assetsGroup enumerateAssetsUsingBlock:^(ALAsset *asset, __unused NSUInteger index, __unused BOOL *stop)
                {
                    if (asset != nil)
                        [assets addObject:[[TGMediaPickerAsset alloc] initWithALAsset:asset]];
                }];
                
                if (completionBlock)
                    completionBlock(assets, [self _authorizationStatus], nil);
            };
            
            if (assetsGroup)
            {
                enumerateAssetsInGroup(assetsGroup.backingAssetsGroup);
            }
            else
            {
                [self _findCameraRollAssetsGroupWithCompletionBlock:^(TGMediaPickerAssetsGroup *cameraRollAssetsGroup, NSError *error)
                {
                    if (cameraRollAssetsGroup && error == nil)
                    {
                        enumerateAssetsInGroup(cameraRollAssetsGroup.backingAssetsGroup);
                    }
                    else
                    {
                        if (completionBlock)
                            completionBlock(nil, [self _authorizationStatus], error);
                    }
                }];
            }
        }
    }];
}

- (void)saveAssetWithImage:(UIImage *)image completionBlock:(void (^)(bool, NSError *))completionBlock
{
    if (_photoLibrary != nil)
    {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status)
        {
            if (status != PHAuthorizationStatusAuthorized)
            {
                if (completionBlock)
                    completionBlock(false, nil);
                return;
            }
            
            [_photoLibrary performChanges:^
            {
                [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            } completionHandler:^(BOOL success, NSError *error)
            {
                if (completionBlock)
                    completionBlock(success, error);
            }];
        }];
    }
    else if (_assetsLibrary != nil)
    {
        [_assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage
                                         orientation:(ALAssetOrientation)image.imageOrientation
                                     completionBlock:^(NSURL *assetURL, NSError *error)
        {
            if (completionBlock)
                completionBlock(assetURL != nil, error);
        }];
    }
}

- (void)saveAssetWithImageData:(NSData *)data completionBlock:(void (^)(bool, NSError *))completionBlock
{
    if (_photoLibrary != nil)
    {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status)
        {
            if (status != PHAuthorizationStatusAuthorized)
            {
                if (completionBlock)
                    completionBlock(false, nil);
                return;
            }
            
            [_photoLibrary performChanges:^
            {
                 [PHAssetChangeRequest creationRequestForAssetFromImage:[UIImage imageWithData:data]];
            } completionHandler:^(BOOL success, NSError *error)
            {
                if (completionBlock)
                    completionBlock(success, error);
            }];
        }];
    }
    else if (_assetsLibrary != nil)
    {
        [_assetsLibrary writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error)
        {
            if (completionBlock)
                completionBlock(assetURL != nil, error);
        }];
    }
}

- (void)saveAssetWithImageAtURL:(NSURL *)url completionBlock:(void (^)(bool, NSError *))completionBlock
{
    [self _saveAssetWithURL:url isVideo:false completionBlock:completionBlock];
}

- (void)saveAssetWithVideoAtURL:(NSURL *)url completionBlock:(void (^)(bool, NSError *))completionBlock
{
    [self _saveAssetWithURL:url isVideo:true completionBlock:completionBlock];
}

- (void)_saveAssetWithURL:(NSURL *)url isVideo:(bool)isVideo completionBlock:(void (^)(bool, NSError *))completionBlock
{
    if (_photoLibrary != nil)
    {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status)
        {
            if (status != PHAuthorizationStatusAuthorized)
            {
                if (completionBlock)
                    completionBlock(false, nil);
                return;
            }
             
            [_photoLibrary performChanges:^
            {
                if (!isVideo)
                    [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:url];
                else
                    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
            } completionHandler:^(BOOL success, NSError *error)
            {
                if (completionBlock)
                    completionBlock(success, error);
            }];
        }];
    }
    else if (_assetsLibrary != nil)
    {
        void (^writeCompletionBlock)(NSURL *, NSError *) = ^(NSURL *assetURL, NSError *error)
        {
            if (completionBlock)
                completionBlock(assetURL != nil, error);
        };
        
        if (!isVideo)
        {
            NSData *data = [[NSData alloc] initWithContentsOfURL:url];
            [_assetsLibrary writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:writeCompletionBlock];
        }
        else
        {
            [_assetsLibrary writeVideoAtPathToSavedPhotosAlbum:url completionBlock:writeCompletionBlock];
        }
    }
}

- (void)assetsLibraryDidChange:(NSNotification *) __unused notification
{
    [self _libraryDidChange];
}

- (void)photoLibraryDidChange:(PHChange *) __unused changeInstance
{
    [self _libraryDidChange];
}

- (void)_libraryDidChange
{
    if (self.libraryChanged == nil)
        return;
    
    [_queue dispatch:^
    {
        if (_libraryChangeDelayTimer != nil)
        {
            [_libraryChangeDelayTimer invalidate];
            _libraryChangeDelayTimer = nil;
        }
 
        __weak TGMediaPickerAssetsLibrary *weakSelf = self;
        _libraryChangeDelayTimer = [[TGTimer alloc] initWithTimeout:1.0f repeat:false completion:^
        {
            __strong TGMediaPickerAssetsLibrary *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            if (strongSelf.libraryChanged)
                strongSelf.libraryChanged();
        } queue:_queue.nativeQueue];
        [_libraryChangeDelayTimer start];
    }];
}

NSInteger TGMediaPickerAssetsGroupComparator(TGMediaPickerAssetsGroup *group1, TGMediaPickerAssetsGroup *group2, __unused void *context)
{
    if (group1.isCameraRoll)
        return NSOrderedAscending;
    else if (group2.isCameraRoll)
        return NSOrderedDescending;
    
    return [group1.title compare:group2.title];
}

- (NSArray *)_fetchLatestAssetsInGroup:(ALAssetsGroup *)assetsGroup
{
    NSMutableArray *latestAssets = [[NSMutableArray alloc] init];
    [assetsGroup enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *asset, __unused NSUInteger index, BOOL *stop)
    {
        if (asset != nil)
            [latestAssets addObject:[[TGMediaPickerAsset alloc] initWithALAsset:asset]];
        if (latestAssets.count == 3 && stop != NULL)
            *stop = true;
    }];
    
    return latestAssets;
}

- (NSArray *)_fetchLatestAssetsInCollection:(PHAssetCollection *)assetCollection fetchResult:(out PHFetchResult **)fetchResult
{
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %i", [TGMediaPickerAssetsLibrary _assetMediaTypeForAssetType:_assetType]];

    PHFetchResult *assetFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
    
    bool isCameraRoll = false;
    if (assetCollection.assetCollectionType == PHAssetCollectionTypeSmartAlbum &&
        assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary)
    {
        isCameraRoll = true;
    }
    
    NSArray *latestAssets = [self _fetchLatestAssetsInFetchResult:assetFetchResult reverse:isCameraRoll];
    
    if (fetchResult != NULL)
        *fetchResult = assetFetchResult;
    
    return latestAssets;
}

- (NSArray *)_fetchLatestAssetsInFetchResult:(PHFetchResult *)fetchResult reverse:(bool)reverse
{
    NSMutableArray *latestAssets = [[NSMutableArray alloc] init];
    [fetchResult enumerateObjectsWithOptions:(reverse ? NSEnumerationReverse : 0) usingBlock:^(PHAsset *asset, __unused NSUInteger index, BOOL *stop)
    {
        if (asset != nil)
            [latestAssets addObject:[[TGMediaPickerAsset alloc] initWithPHAsset:asset]];
        if (latestAssets.count == 3 && stop != NULL)
            *stop = true;
    }];
    return latestAssets;
}

- (void)_findCameraRollAssetsGroupWithCompletionBlock:(void (^)(TGMediaPickerAssetsGroup *cameraRollAssetsGroup, NSError *error))completionBlock
{
    if (_photoLibrary != nil)
    {
        if (iosMajorVersion() == 8 && iosMinorVersion() < 1)
        {
            // on iOS 8.0.x "simulate" camera roll group, as there's no one
            PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:[TGMediaPickerAssetsLibrary _assetMediaTypeForAssetType:_assetType]
                                                                   options:nil];
            
            NSArray *latestAssets = [self _fetchLatestAssetsInFetchResult:fetchResult reverse:true];
            
            if (completionBlock)
            {
                completionBlock([[TGMediaPickerAssetsGroup alloc] initWithPHFetchResult:fetchResult
                                                                           latestAssets:latestAssets], nil);
            }
        }
        else
        {
            PHFetchResult *collectionsFetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                                             subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                                                                             options:nil];
            PHAssetCollection *cameraRollCollection;
            PHFetchResult *fetchResult;
            NSArray *latestAssets;
            if (collectionsFetchResult.count > 0)
            {
                cameraRollCollection = collectionsFetchResult.firstObject;
                latestAssets = [self _fetchLatestAssetsInCollection:cameraRollCollection fetchResult:&fetchResult];
            }

            if (completionBlock)
            {
                completionBlock([[TGMediaPickerAssetsGroup alloc] initWithPHAssetCollection:cameraRollCollection
                                                                                fetchResult:fetchResult
                                                                               latestAssets:latestAssets], nil);
            }
        }
    }
    else if (_assetsLibrary != nil)
    {
        [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, __unused BOOL *stop)
        {
            if (group != nil)
            {
                if (stop != NULL)
                    *stop = true;
                
                [group setAssetsFilter:[TGMediaPickerAssetsLibrary _assetsFilterForAssetType:_assetType]];
                
                if (completionBlock)
                    completionBlock([[TGMediaPickerAssetsGroup alloc] initWithALAssetsGroup:group latestAssets:nil], nil);
            }
        } failureBlock:^(NSError *error)
        {
            if (completionBlock)
                completionBlock(nil, error);
        }];
    }
}

+ (PHAssetMediaType)_assetMediaTypeForAssetType:(TGMediaPickerAssetType)assetType
{
    switch (assetType)
    {
        case TGMediaPickerAssetPhotoType:
            return PHAssetMediaTypeImage;
            
        case TGMediaPickerAssetVideoType:
            return PHAssetMediaTypeVideo;
            
        default:
            return PHAssetMediaTypeUnknown;
    }
}

+ (ALAssetsFilter *)_assetsFilterForAssetType:(TGMediaPickerAssetType)assetType
{
    switch (assetType)
    {
        case TGMediaPickerAssetPhotoType:
            return [ALAssetsFilter allPhotos];
        
        case TGMediaPickerAssetVideoType:
            return [ALAssetsFilter allVideos];
        
        default:
            return [ALAssetsFilter allAssets];
    }
}

- (TGMediaPickerAuthorizationStatus)_authorizationStatus
{
    if (_photoLibrary != nil)
    {
        switch ([PHPhotoLibrary authorizationStatus])
        {
            case PHAuthorizationStatusRestricted:
                return TGMediaPickerAuthorizationStatusRestricted;
                
            case PHAuthorizationStatusDenied:
                return TGMediaPickerAuthorizationStatusDenied;
                
            case PHAuthorizationStatusAuthorized:
                return TGMediaPickerAuthorizationStatusAuthorized;
                
            default:
                return TGMediaPickerAuthorizationStatusNotDetermined;
        }
    }
    else if (_assetsLibrary != nil)
    {
        switch ([ALAssetsLibrary authorizationStatus])
        {
            case ALAuthorizationStatusRestricted:
                return TGMediaPickerAuthorizationStatusRestricted;
                
            case ALAuthorizationStatusDenied:
                return TGMediaPickerAuthorizationStatusDenied;
                
            case ALAuthorizationStatusAuthorized:
                return TGMediaPickerAuthorizationStatusAuthorized;
                
            default:
                return TGMediaPickerAuthorizationStatusNotDetermined;
        }
    }
    
    return TGMediaPickerAuthorizationStatusNotDetermined;
}

@end
