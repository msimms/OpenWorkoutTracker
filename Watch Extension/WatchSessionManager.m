//  Created by Michael Simms on 7/28/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

#import "WatchSessionManager.h"

@interface WatchSessionManager ()

@end


@implementation WatchSessionManager

- (void)startWatchSession
{
	self->watchSession = [WCSession defaultSession];
	self->watchSession.delegate = self;
	[self->watchSession activateSession];
}

- (void)session:(nonnull WCSession*)session didReceiveApplicationContext:(NSDictionary<NSString*, id>*)applicationContext
{
}

- (void)session:(nonnull WCSession*)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError*)error
{
}

- (void)sessionReachabilityDidChange:(nonnull WCSession*)session
{
}

- (void)session:(nonnull WCSession*)session didReceiveMessage:(nonnull NSDictionary<NSString*,id> *)message replyHandler:(nonnull void (^)(NSDictionary<NSString*,id> * __nonnull))replyHandler
{
}

- (void)session:(nonnull WCSession*)session didReceiveMessage:(NSDictionary<NSString*,id> *)message
{
}

- (void)session:(nonnull WCSession*)session didReceiveMessageData:(NSData*)messageData
{
}

- (void)session:(nonnull WCSession*)session didReceiveMessageData:(NSData*)messageData replyHandler:(void (^)(NSData *replyMessageData))replyHandler
{
}

- (void)session:(nonnull WCSession*)session didReceiveFile:(WCSessionFile*)file
{
}

- (void)session:(nonnull WCSession*)session didReceiveUserInfo:(NSDictionary<NSString *,id> *)userInfo
{
}

- (void)session:(nonnull WCSession*)session didFinishUserInfoTransfer:(WCSessionUserInfoTransfer *)userInfoTransfer error:(NSError *)error
{
}
@end
