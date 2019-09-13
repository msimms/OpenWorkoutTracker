//  Created by Michael Simms on 7/28/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

#import "WatchSessionManager.h"
#import "WatchMessages.h"
#import "Notifications.h"

@interface WatchSessionManager ()

@end


@implementation WatchSessionManager

- (void)startWatchSession
{
	self->watchSession = [WCSession defaultSession];
	self->watchSession.delegate = self;
	[self->watchSession activateSession];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityStopped:) name:@NOTIFICATION_NAME_ACTIVITY_STOPPED object:nil];
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
	if ([message objectForKey:@WATCH_MSG_CHECK_ACTIVITY]) {
	}
	else if ([message objectForKey:@WATCH_MSG_REQUEST_ACTIVITY]) {
	}
	else if ([message objectForKey:@WATCH_MSG_ACTIVITY]) {
	}
}

- (void)session:(nonnull WCSession*)session didReceiveMessage:(NSDictionary<NSString*,id> *)message
{
	if ([message objectForKey:@WATCH_MSG_CHECK_ACTIVITY]) {
	}
	else if ([message objectForKey:@WATCH_MSG_REQUEST_ACTIVITY]) {
	}
	else if ([message objectForKey:@WATCH_MSG_ACTIVITY]) {
	}
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

- (void)activityStopped:(NSNotification*)notification
{
}

@end
