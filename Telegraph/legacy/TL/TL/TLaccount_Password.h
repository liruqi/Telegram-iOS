#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLaccount_Password : NSObject <TLObject>

@property (nonatomic, retain) NSData *n_new_salt;

@end

@interface TLaccount_Password$account_noPassword : TLaccount_Password


@end

@interface TLaccount_Password$account_password : TLaccount_Password

@property (nonatomic, retain) NSData *current_salt;
@property (nonatomic, retain) NSString *hint;

@end

