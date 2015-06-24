/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import <UIKit/UIKit.h>

extern NSString *TGImageViewOptionKeepCurrentImageAsPlaceholder;
extern NSString *TGImageViewOptionEmbeddedImage;
extern NSString *TGImageViewOptionSynchronous;

@interface TGImageView : UIImageView

@property (nonatomic) bool expectExtendedEdges;

- (void)loadUri:(NSString *)uri withOptions:(NSDictionary *)options;
- (void)reset;

- (void)performTransitionToImage:(UIImage *)image partial:(bool)partial duration:(NSTimeInterval)duration;
- (void)performProgressUpdate:(float)progress;

@end
