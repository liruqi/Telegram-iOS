#import "TGResolveDomainActor.h"

#import "ActionStage.h"
#import "TGTelegramNetworking.h"
#import "TGProgressWindow.h"

#import "TL/TLMetaScheme.h"

#import <MTProtoKit/MTRequest.h>

#import "TGUserDataRequestBuilder.h"
#import "TGUser+Telegraph.h"

#import "TGInterfaceManager.h"

@interface TGResolveDomainActor ()
{
    TGProgressWindow *_progressWindow;
    NSString *_domain;
}

@end

@implementation TGResolveDomainActor

+ (void)load
{
    [ASActor registerActorClass:self];
}

+ (NSString *)genericPath
{
    return @"/resolveDomain/@";
}

- (void)dealloc
{
    TGProgressWindow *progressWindow = _progressWindow;
    TGDispatchOnMainThread(^
    {
        [progressWindow dismiss:true];
    });
}

- (void)execute:(NSDictionary *)options
{
    TGDispatchOnMainThread(^
    {
        _progressWindow = [[TGProgressWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [_progressWindow show:true];
    });
    
    _domain = options[@"domain"];
    
    MTRequest *request = [[MTRequest alloc] init];
    
    TLRPCcontacts_resolveUsername$contacts_resolveUsername *resolveUsername = [[TLRPCcontacts_resolveUsername$contacts_resolveUsername alloc] init];
    resolveUsername.username = _domain;
    request.body = resolveUsername;
    
    __weak TGResolveDomainActor *weakSelf = self;
    [request setCompleted:^(TLUser *result, __unused NSTimeInterval timestamp, id error)
    {
        [ActionStageInstance() dispatchOnStageQueue:^
        {
            __strong TGResolveDomainActor *strongSelf = weakSelf;
            if (strongSelf != nil)
            {
                if (error == nil)
                    [strongSelf resolveSuccess:result];
                else
                    [strongSelf resolveFailed];
            }
        }];
    }];
    
    self.cancelToken = request.internalId;
    [[TGTelegramNetworking instance] addRequest:request];
}

- (void)resolveSuccess:(TLUser *)foundUser
{
    TGDispatchOnMainThread(^
    {
        [_progressWindow dismiss:true];
        _progressWindow = nil;
    });
    
    TGUser *user = [[TGUser alloc] initWithTelegraphUserDesc:foundUser];
    if (user.uid != 0)
    {
        [TGUserDataRequestBuilder executeUserObjectsUpdate:@[user]];
        TGDispatchOnMainThread(^
        {
            [[TGInterfaceManager instance] navigateToConversationWithId:user.uid conversation:nil];
        });
    }
    
    [ActionStageInstance() actionCompleted:self.path result:nil];
}

- (void)resolveFailed
{
    TGDispatchOnMainThread(^
    {
        [_progressWindow dismiss:true];
        _progressWindow = nil;
    });

    [ActionStageInstance() actionFailed:self.path reason:-1];
}

@end
