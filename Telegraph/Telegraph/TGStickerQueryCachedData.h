#import <Foundation/Foundation.h>

@interface TGStickerQueryCachedData : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSString *queryHash;
@property (nonatomic, strong, readonly) NSArray *documents;

- (instancetype)initWithQueryHash:(NSString *)queryHash documents:(NSArray *)documents;

@end
