//  Created by Michael Simms on 7/28/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

#import "WatchSessionManager.h"
#import "WatchMessages.h"
#import "ExtensionDelegate.h"
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
//	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	NSString* msgType = [message objectForKey:@WATCH_MSG_TYPE];
	if ([msgType isEqualToString:@WATCH_MSG_CHECK_ACTIVITY]) {
		// The phone app wants to know if we have an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REQUEST_ACTIVITY]) {
		// The phone app is requesting an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_ACTIVITY]) {
		// The phone app is sending an activity.
	}
}

- (void)session:(nonnull WCSession*)session didReceiveMessage:(NSDictionary<NSString*,id> *)message
{
//	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	NSString* msgType = [message objectForKey:@WATCH_MSG_TYPE];
	if ([msgType isEqualToString:@WATCH_MSG_CHECK_ACTIVITY]) {
		// The phone app wants to know if we have an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REQUEST_ACTIVITY]) {
		// The phone app is requesting an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_ACTIVITY]) {
		// The phone app is sending an activity.
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
	if (self->watchSession)
	{
		NSMutableDictionary* msgData = [[notification object] mutableCopy];
		[msgData setObject:@WATCH_MSG_CHECK_ACTIVITY forKey:@WATCH_MSG_TYPE];
		[self->watchSession sendMessage:msgData replyHandler:nil errorHandler:nil];
	}
}

@end
