#import "TGStickerQueryCachedData.h"

@implementation TGStickerQueryCachedData

- (instancetype)initWithQueryHash:(NSString *)queryHash documents:(NSArray *)documents
{
    self = [super init];
    if (self != nil)
    {
        _queryHash = queryHash;
        _documents = documents;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self != nil)
    {
        _queryHash = [aDecoder decodeObjectForKey:@"queryHash"];
        _documents = [aDecoder decodeObjectForKey:@"documents"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_queryHash forKey:@"queryHash"];
    [aCoder encodeObject:_documents forKey:@"documents"];
}

@end
