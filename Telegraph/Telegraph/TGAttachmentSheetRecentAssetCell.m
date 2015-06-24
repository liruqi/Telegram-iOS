#import "TGAttachmentSheetRecentAssetCell.h"

#import "TGImageView.h"
#import "TGImagePickerCellCheckButton.h"

#import "TGMediaPickerAsset.h"
#import "TGAssetImageManager.h"

#import "TGImageUtils.h"

@interface TGAttachmentSheetRecentAssetCell ()
{
    TGImageView *_imageView;
    TGImagePickerCellCheckButton *_checkButton;
    NSUInteger _loadToken;
    int32_t _requestId;
    
    TGMediaPickerAsset *_asset;
    bool (^_isAssetSelected)(TGMediaPickerAsset *);
    bool (^_isAssetHidden)(TGMediaPickerAsset *);
    void (^_changeAssetSelection)(TGMediaPickerAsset *);
    void (^_openAsset)(TGMediaPickerAsset *);
}

@end

@implementation TGAttachmentSheetRecentAssetCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {        
        _imageView = [[TGImageView alloc] initWithFrame:self.bounds];
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = true;
        [_imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapGesture:)]];
        [self.contentView addSubview:_imageView];
        
        _checkButton = [[TGImagePickerCellCheckButton alloc] initWithFrame:CGRectMake(frame.size.width - 33.0f - 0.0f, frame.size.height - 33.0f + 1.0f, 33.0f, 33.0f)];
        _checkButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [_checkButton setChecked:false animated:false];
        [_checkButton addTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_checkButton];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint(_checkButton.frame, point))
        return _checkButton;
    if (CGRectContainsPoint(_imageView.frame, point))
        return _imageView;
    
    return [super hitTest:point withEvent:event];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    if (_loadToken != 0)
    {
        [TGAssetImageManager cancelRequestWithToken:_loadToken];
        _loadToken = 0;
    }
}

- (void)imageTapGesture:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        if (_openAsset)
            _openAsset(_asset);
    }
}

- (void)checkButtonPressed
{
    if (_changeAssetSelection)
        _changeAssetSelection(_asset);
    if (_isAssetSelected)
        [_checkButton setChecked:_isAssetSelected(_asset) animated:true];
}

- (void)setAsset:(TGMediaPickerAsset *)asset isAssetSelected:(bool (^)(TGMediaPickerAsset *))isAssetSelected isAssetHidden:(bool (^)(TGMediaPickerAsset *))isAssetHidden changeAssetSelection:(void (^)(TGMediaPickerAsset *))changeAssetSelection openAsset:(void (^)(TGMediaPickerAsset *))openAsset
{
    _isAssetSelected = [isAssetSelected copy];
    _isAssetHidden = [isAssetHidden copy];
    _changeAssetSelection = [changeAssetSelection copy];
    _openAsset = [openAsset copy];
    _asset = asset;
    
    if (_isAssetSelected)
        [_checkButton setChecked:_isAssetSelected(_asset) animated:false];
    if (_isAssetHidden)
        _imageView.hidden = _isAssetHidden(_asset);
    else
        _imageView.hidden = false;
    
    _requestId++;
    int32_t requestId = _requestId;
    __weak TGAttachmentSheetRecentAssetCell *weakSelf = self;
    CGSize requestedSize = CGSizeMake(157, 157);
    _loadToken = [TGAssetImageManager requestImageWithAsset:asset imageType:TGAssetImageTypeThumbnail size:requestedSize synchronous:false completionBlock:^(UIImage *image, __unused NSError *error)
    {
        TGDispatchOnMainThread(^
        {
            __strong TGAttachmentSheetRecentAssetCell *strongSelf = weakSelf;
            if (strongSelf != nil)
            {
                if (strongSelf->_requestId == requestId)
                {
                    [strongSelf->_imageView loadUri:@"embedded://" withOptions:@{TGImageViewOptionEmbeddedImage: image}];
                    strongSelf->_loadToken = 0;
                }
            }
        });
    }];
}

- (UIView *)referenceViewForAsset:(TGMediaPickerAsset *)asset
{
    if ([asset isEqual:_asset])
        return _imageView;
    
    return nil;
}

- (void)updateSelection
{
    if (_isAssetSelected)
    {
        bool checked = _isAssetSelected(_asset);
        if (checked != _checkButton.checked)
            [_checkButton setChecked:_isAssetSelected(_asset) animated:false];
    }
}

- (void)updateHidden:(bool)animated
{
    if (_isAssetHidden)
    {
        bool hidden = _isAssetHidden(_asset);
        if (hidden != _imageView.hidden)
        {
            _imageView.hidden = hidden;
            
            if (animated)
            {
                if (!hidden)
                    _checkButton.alpha = 0.0f;
                [UIView animateWithDuration:0.2 animations:^
                {
                    if (!hidden)
                        _checkButton.alpha = 1.0f;
                }];
            }
            else
            {
                _imageView.hidden = hidden;
            }
        }
    }
}

@end
