#import "TGStickerAssociatedInputPanel.h"

#import "TGStickerAssociatedPanelCollectionLayout.h"
#import "TGStickerAssociatedInputPanelCell.h"

#import "TGImageUtils.h"

@interface TGStickerAssociatedInputPanel () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
{
    UIView *_stripeView;
    
    UICollectionView *_collectionView;
    TGStickerAssociatedPanelCollectionLayout *_layout;
    
    NSArray *_documentList;
}

@end

@implementation TGStickerAssociatedInputPanel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        self.backgroundColor = UIColorRGBA(0xfafafa, 0.97f);
        
        _stripeView = [[UIView alloc] init];
        _stripeView.backgroundColor = UIColorRGBA(0xb3aab2, 0.4f);
        [self addSubview:_stripeView];
        
        _layout = [[TGStickerAssociatedPanelCollectionLayout alloc] init];
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        _layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView.delaysContentTouches = false;
        _collectionView.showsHorizontalScrollIndicator = false;
        _collectionView.showsVerticalScrollIndicator = false;
        [_collectionView registerClass:[TGStickerAssociatedInputPanelCell class]
            forCellWithReuseIdentifier:@"TGStickerAssociatedInputPanelCell"];
        [self addSubview:_collectionView];
    }
    return self;
}

- (CGFloat)preferredHeight
{
    return 75.0f;
}

- (NSArray *)documentList
{
    return _documentList;
}

- (void)setDocumentList:(NSArray *)documentList
{
    if (!TGObjectCompare(_documentList, documentList))
    {
        _documentList = documentList;
        [_collectionView reloadData];
        [_collectionView layoutSubviews];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat separatorHeight = TGIsRetina() ? 0.5f : 1.0f;
    _stripeView.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, separatorHeight);
    
    _collectionView.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, [self preferredHeight]);
}

- (NSInteger)collectionView:(UICollectionView *)__unused collectionView numberOfItemsInSection:(NSInteger)__unused section
{
    return _documentList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TGStickerAssociatedInputPanelCell *cell = (TGStickerAssociatedInputPanelCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"TGStickerAssociatedInputPanelCell" forIndexPath:indexPath];
    
    [cell setDocument:_documentList[indexPath.row]];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)__unused collectionView layout:(UICollectionViewLayout *)__unused collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)__unused indexPath
{
    return CGSizeMake(75.0f, 75.0f);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)__unused collectionView layout:(UICollectionViewLayout *)__unused collectionViewLayout insetForSectionAtIndex:(NSInteger)__unused section
{
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)__unused collectionView layout:(UICollectionViewLayout *)__unused collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)__unused section
{
    return 0.0f;
}

- (CGFloat)collectionView:(UICollectionView *)__unused collectionView layout:(UICollectionViewLayout *)__unused collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)__unused section
{
    return 0.0f;
}

- (void)collectionView:(UICollectionView *)__unused collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_documentSelected)
        _documentSelected(_documentList[indexPath.row]);
}

@end
