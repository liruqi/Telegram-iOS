#import "TGAttachmentSheetRecentItemView.h"

#import "TGAttachmentSheetRecentLayout.h"
#import "TGAttachmentSheetRecentAssetCell.h"

#import "TGAttachmentSheetRecentCameraView.h"

#import "TGMediaPickerAssetsLibrary.h"
#import "TGMediaPickerAssetsGroup.h"
#import "TGMediaPickerAsset.h"

#import "TGModernGalleryController.h"
#import "TGAssetGalleryImageItem.h"
#import "TGAssetGalleryModel.h"
#import "TGOverlayControllerWindow.h"

#import "TGAttachmentSheetRecentControlledButtonItemView.h"

@interface TGAttachmentSheetRecentItemView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
{
    UICollectionView *_collectionView;
    TGAttachmentSheetRecentLayout *_layout;
    
    TGMediaPickerAssetsLibrary *_assetsLibrary;
    NSArray *_assets;
    
    NSSet *_selectedAssetIds;
    
    bool (^_isAssetSelected)(TGMediaPickerAsset *);
    bool (^_isAssetHidden)(TGMediaPickerAsset *);
    void (^_changeAssetSelection)(TGMediaPickerAsset *);
    void (^_openAsset)(TGMediaPickerAsset *);
    
    TGAttachmentSheetRecentControlledButtonItemView *_multifunctionButtonView;
    TGAttachmentSheetRecentCameraView *_cameraView;
    
    TGAssetGalleryModel *_galleryModel;
    TGMediaPickerAsset *_hiddenAsset;
    
    __weak TGViewController *_parentController;
}

@end

@implementation TGAttachmentSheetRecentItemView

- (instancetype)initWithParentController:(TGViewController *)controller
{
    self = [super init];
    if (self != nil)
    {
        _parentController = controller;
        
        _layout = [[TGAttachmentSheetRecentLayout alloc] init];
        _layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
        _collectionView.backgroundColor = nil;
        _collectionView.opaque = false;
        _collectionView.showsHorizontalScrollIndicator = false;
        _collectionView.showsVerticalScrollIndicator = false;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.delaysContentTouches = false;
        
        __weak TGAttachmentSheetRecentItemView *weakSelf = self;
        
        _cameraView = [[TGAttachmentSheetRecentCameraView alloc] initWithFrame:CGRectMake(5.0f, 5.0f, 78.0f, 78.0f)];
        _cameraView.pressed = ^
        {
            __strong TGAttachmentSheetRecentItemView *strongSelf = weakSelf;
            if (strongSelf.openCamera)
                strongSelf.openCamera();
        };
        [_collectionView addSubview:_cameraView];
        
        [_collectionView registerClass:[TGAttachmentSheetRecentAssetCell class] forCellWithReuseIdentifier:@"TGAttachmentSheetRecentAssetCell"];
        [self addSubview:_collectionView];
        
        _isAssetSelected = ^bool (TGMediaPickerAsset *asset)
        {
            __strong TGAttachmentSheetRecentItemView *strongSelf = weakSelf;
            if (strongSelf != nil)
                return [strongSelf->_selectedAssetIds containsObject:asset.uniqueId];
            return false;
        };
        
        _isAssetHidden = ^bool (TGMediaPickerAsset *asset)
        {
            __strong TGAttachmentSheetRecentItemView *strongSelf = weakSelf;
            if (strongSelf != nil)
                return [strongSelf->_hiddenAsset isEqual:asset];
            return false;
        };
        
        _changeAssetSelection = ^(TGMediaPickerAsset *asset)
        {
            __strong TGAttachmentSheetRecentItemView *strongSelf = weakSelf;
            if (strongSelf != nil)
            {
                if (![strongSelf->_selectedAssetIds containsObject:asset.uniqueId])
                {
                    NSMutableSet *selectedAssetIds = [[NSMutableSet alloc] initWithSet:strongSelf->_selectedAssetIds];
                    [selectedAssetIds addObject:asset.uniqueId];
                    strongSelf->_selectedAssetIds = selectedAssetIds;
                    [strongSelf _updateCellSelections];
                }
                else
                {
                    NSMutableSet *selectedAssetIds = [[NSMutableSet alloc] initWithSet:strongSelf->_selectedAssetIds];
                    [selectedAssetIds removeObject:asset.uniqueId];
                    strongSelf->_selectedAssetIds = selectedAssetIds;
                    [strongSelf _updateCellSelections];
                }
            }
        };
        
        _openAsset = ^(TGMediaPickerAsset *asset)
        {
            __strong TGAttachmentSheetRecentItemView *strongSelf = weakSelf;
            if (strongSelf != nil)
                [strongSelf _openGalleryWithAsset:asset];
        };
        
        _assetsLibrary = [[TGMediaPickerAssetsLibrary alloc] initForAssetType:TGMediaPickerAssetPhotoType];
        [_assetsLibrary fetchGroupsWithCompletionBlock:^(NSArray *groups, __unused TGMediaPickerAuthorizationStatus status, __unused NSError *error)
        {
            for (TGMediaPickerAssetsGroup *group in groups)
            {
                if ([group isCameraRoll])
                {
                    [_assetsLibrary fetchAssetsOfAssetsGroup:group withCompletionBlock:^(NSArray *assets, __unused TGMediaPickerAuthorizationStatus status, __unused NSError *error)
                    {
                        TGDispatchOnMainThread(^
                        {
                            __strong TGAttachmentSheetRecentItemView *strongSelf = weakSelf;
                            if (strongSelf != nil)
                            {
                                NSMutableArray *reversedAssets = [[NSMutableArray alloc] init];
                                for (id asset in assets.reverseObjectEnumerator)
                                {
                                    [reversedAssets addObject:asset];
                                }
                                [strongSelf setAssets:reversedAssets];
                            }
                        });
                    }];
                    
                    break;
                }
            }
        }];
    }
    return self;
}

- (id<TGModernGalleryItem>)galleryItemForAsset:(TGMediaPickerAsset *)asset
{
    if ([asset isVideo])
        return nil;
    else
    {
        return [[TGAssetGalleryImageItem alloc] initWithAsset:asset];
    }
}

- (void)_openGalleryWithAsset:(TGMediaPickerAsset *)asset
{
    for (UIView *sibling in self.superview.subviews.reverseObjectEnumerator)
    {
        if ([sibling isKindOfClass:[TGAttachmentSheetItemView class]])
        {
            if (sibling != self)
            {
                [self.superview exchangeSubviewAtIndex:[self.superview.subviews indexOfObject:self] withSubviewAtIndex:[self.superview.subviews indexOfObject:sibling]];
            }
            break;
        }
    }
    
    NSMutableArray *galleryItems = [[NSMutableArray alloc] init];
    id<TGModernGalleryItem> focusItem = nil;
    for (TGMediaPickerAsset *listAsset in _assets)
    {
        id<TGModernGalleryItem> galleryItem = [self galleryItemForAsset:listAsset];
        if (galleryItem != nil)
        {
            if ([listAsset isEqual:asset])
                focusItem = galleryItem;
            [galleryItems addObject:galleryItem];
        }
    }
    
    TGModernGalleryController *modernGallery = [[TGModernGalleryController alloc] init];
    
    __weak TGAttachmentSheetRecentItemView *weakSelf = self;
    
    TGAssetGalleryModel *model = [[TGAssetGalleryModel alloc] initWithItems:galleryItems focusItem:focusItem];
    model.interfaceView.showStatusBar = true;
    [model.interfaceView updateSelectionInterface:_selectedAssetIds.count animated:false];
    model.interfaceView.itemSelected = ^(id<TGGenericAssetGalleryItem> item)
    {
        __strong TGAttachmentSheetRecentItemView *strongSelf = weakSelf;
        if (strongSelf != nil)
            strongSelf->_changeAssetSelection([item asset]);
        
        [strongSelf updateSelectionInterface:true];
    };
    model.interfaceView.isItemSelected = ^bool (id<TGGenericAssetGalleryItem> item)
    {
        __strong TGAttachmentSheetRecentItemView *strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            return strongSelf->_isAssetSelected([item asset]);
        }
        
        return false;
    };
    model.interfaceView.donePressed = ^(__unused id<TGGenericAssetGalleryItem> item)
    {
        __strong TGAttachmentSheetRecentItemView *strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            if (![strongSelf->_selectedAssetIds containsObject:[item asset].uniqueId])
                strongSelf->_changeAssetSelection([item asset]);
            
            if (strongSelf->_galleryModel.dismiss)
                strongSelf->_galleryModel.dismiss(true, false);
            
            if (strongSelf->_done)
                strongSelf->_done();
        }
    };
    _galleryModel = model;
    modernGallery.model = model;
    
    modernGallery.itemFocused = ^(id<TGGenericAssetGalleryItem> item)
    {
        __strong TGAttachmentSheetRecentItemView *strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            strongSelf->_hiddenAsset = [item asset];
            [strongSelf updateHiddenItem:false];
        }
    };
    
    modernGallery.beginTransitionIn = ^UIView *(id<TGGenericAssetGalleryItem> item, __unused TGModernGalleryItemView *itemView)
    {
        __strong TGAttachmentSheetRecentItemView *strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            return [strongSelf referenceViewForAsset:[item asset]];
        }
        
        return nil;
    };
    
    modernGallery.beginTransitionOut = ^UIView *(id<TGGenericAssetGalleryItem> item)
    {
        __strong TGAttachmentSheetRecentItemView *strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            return [strongSelf referenceViewForAsset:[item asset]];
        }
        
        return nil;
    };
    
    modernGallery.completedTransitionOut = ^
    {
        __strong TGAttachmentSheetRecentItemView *strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            strongSelf->_hiddenAsset = nil;
            [strongSelf updateHiddenItem:true];
        }
    };
    
    TGOverlayControllerWindow *controllerWindow = [[TGOverlayControllerWindow alloc] initWithParentController:_parentController contentController:modernGallery];
    controllerWindow.windowLevel = self.window.windowLevel + 0.1f;
    controllerWindow.hidden = false;
}

- (UIView *)referenceViewForAsset:(TGMediaPickerAsset *)asset
{
    for (TGAttachmentSheetRecentAssetCell *cell in _collectionView.visibleCells)
    {
        UIView *result = [cell referenceViewForAsset:asset];
        if (result != nil)
            return result;
    }
    
    return nil;
}

- (void)updateSelectionInterface:(bool)__unused animated
{
    NSUInteger selectedCount = _selectedAssetIds.count;
    
    TGAssetGalleryModel *galleryModel = _galleryModel;
    if (galleryModel != nil)
        [galleryModel.interfaceView updateSelectionInterface:selectedCount animated:true];
}

- (void)updateHiddenItem:(bool)animated
{
    for (TGAttachmentSheetRecentAssetCell *cell in _collectionView.visibleCells)
    {
        [cell updateHidden:animated];
    }
}

- (void)setMultifunctionButtonView:(TGAttachmentSheetRecentControlledButtonItemView *)multifunctionButtonView
{
    _multifunctionButtonView = multifunctionButtonView;
}

- (NSArray *)selectedAssets
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    for (TGMediaPickerAsset *asset in _assets)
    {
        if ([_selectedAssetIds containsObject:asset.uniqueId])
            [result addObject:asset];
    }
    
    return result;
}

- (CGFloat)preferredHeight
{
    return 88.0f;
}

- (bool)wantsFullSeparator
{
    return true;
}

- (void)sheetDidAppear
{
    [super sheetDidAppear];
}

- (void)sheetWillDisappear
{
    [super sheetWillDisappear];
    
    [_cameraView stopPreview];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _collectionView.frame = self.bounds;
}

- (void)_updateCellSelections
{
    for (id cell in _collectionView.visibleCells)
    {
        if ([cell isKindOfClass:[TGAttachmentSheetRecentAssetCell class]])
        {
            [(TGAttachmentSheetRecentAssetCell *)cell updateSelection];
        }
    }
    
    if (_selectedAssetIds.count != 0)
        [_multifunctionButtonView setAlternateWithTitle:[self stringForSendPhotos:_selectedAssetIds.count]];
    else
        [_multifunctionButtonView setDefault];
}

- (NSString *)stringForSendPhotos:(NSUInteger)count
{
    NSString *format = TGLocalized(@"QuickSend.Photos_any");
    if (count == 1)
        format =  TGLocalized(@"QuickSend.Photos_1");
    else if (count == 2)
        format =  TGLocalized(@"QuickSend.Photos_2");
    else if (count >= 3 && count <= 10)
        format =  TGLocalized(@"QuickSend.Photos_3_10");
    
    return [[NSString alloc] initWithFormat:format, [[NSString alloc] initWithFormat:@"%d", (int)count]];
}

- (CGSize)collectionView:(UICollectionView *)__unused collectionView layout:(UICollectionViewLayout *)__unused collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)__unused indexPath
{
    return CGSizeMake(78.0f, 78.0f);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)__unused collectionView layout:(UICollectionViewLayout *)__unused collectionViewLayout insetForSectionAtIndex:(NSInteger)__unused section
{
    return UIEdgeInsetsMake(5.0f, 5.0f + 78.0f + 5.0f, 5.0f, 5.0f);
}

- (CGFloat)collectionView:(UICollectionView *)__unused collectionView layout:(UICollectionViewLayout *)__unused collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)__unused section
{
    return 0.0f;
}

- (CGFloat)collectionView:(UICollectionView *)__unused collectionView layout:(UICollectionViewLayout *)__unused collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)__unused section
{
    return 5.0f;
}

- (NSInteger)collectionView:(UICollectionView *)__unused collectionView numberOfItemsInSection:(NSInteger)section
{
    if (section == 0)
        return _assets.count;
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TGAttachmentSheetRecentAssetCell *cell = (TGAttachmentSheetRecentAssetCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"TGAttachmentSheetRecentAssetCell" forIndexPath:indexPath];
    [cell setAsset:_assets[indexPath.row] isAssetSelected:_isAssetSelected isAssetHidden:_isAssetHidden changeAssetSelection:_changeAssetSelection openAsset:_openAsset];
    return cell;
}

- (void)setAssets:(NSArray *)assets
{
    bool fadeIn = _assets.count == 0;
    _assets = assets;
    [_collectionView reloadData];
    [_collectionView layoutSubviews];
    
    if (fadeIn)
    {
        for (UIView *cell in _collectionView.visibleCells)
        {
            cell.alpha = 0.0f;
        }
        
        [UIView animateWithDuration:0.1 animations:^
        {
            for (UIView *cell in _collectionView.visibleCells)
            {
                cell.alpha = 1.0f;
            }
        }];
    }
}

@end
