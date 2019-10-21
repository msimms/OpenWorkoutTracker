//  Created by Michael Simms on 7/28/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "WatchSessionManager.h"
#import "WatchMessages.h"
#import "ExtensionDelegate.h"
#import "Notifications.h"
#import "Preferences.h"

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

- (void)sendSyncPrefsMsg
{
	NSMutableDictionary* msgData = [[NSMutableDictionary alloc] init];

	[msgData setObject:@WATCH_MSG_SYNC_PREFS forKey:@WATCH_MSG_TYPE];
	[self->watchSession sendMessage:msgData replyHandler:nil errorHandler:nil];
}

- (void)sendRegisterDeviceMsg
{
	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	NSMutableDictionary* msgData = [[NSMutableDictionary alloc] init];

	[msgData setObject:@WATCH_MSG_REGISTER_DEVICE forKey:@WATCH_MSG_TYPE];
	[msgData setObject:[extDelegate getDeviceId] forKey:@WATCH_MSG_DEVICE_ID];
	[self->watchSession sendMessage:msgData replyHandler:nil errorHandler:nil];
}

- (void)session:(nonnull WCSession*)session didReceiveApplicationContext:(NSDictionary<NSString*, id>*)applicationContext
{
}

- (void)session:(nonnull WCSession*)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError*)error
{
	switch (activationState)
	{
		case WCSessionActivationStateNotActivated:
			break;
		case WCSessionActivationStateInactive:
			break;
		case WCSessionActivationStateActivated:
			[self sendSyncPrefsMsg];
			[self sendRegisterDeviceMsg];
			break;
	}
}

- (void)sessionReachabilityDidChange:(nonnull WCSession*)session
{
	if (session.reachable)
	{
		[self sendRegisterDeviceMsg];
	}
}

- (void)session:(nonnull WCSession*)session didReceiveMessage:(nonnull NSDictionary<NSString*,id> *)message replyHandler:(nonnull void (^)(NSDictionary<NSString*,id> * __nonnull))replyHandler
{
	NSString* msgType = [message objectForKey:@WATCH_MSG_TYPE];
	if ([msgType isEqualToString:@WATCH_MSG_SYNC_PREFS])
	{
		// The phone app wants to sync preferences.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REGISTER_DEVICE])
	{
		// The phone app is asking the watch to register itself.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_INTERVAL_WORKOUTS])
	{
		// The phone app is sending interval workouts.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_CHECK_ACTIVITY])
	{
		// The phone app wants to know if we have an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REQUEST_ACTIVITY])
	{
		// The phone app is requesting an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_ACTIVITY])
	{
		// The phone app is sending an activity.
	}
}

- (void)session:(nonnull WCSession*)session didReceiveMessage:(NSDictionary<NSString*,id> *)message
{
	NSString* msgType = [message objectForKey:@WATCH_MSG_TYPE];
	if ([msgType isEqualToString:@WATCH_MSG_SYNC_PREFS])
	{
		// The phone app wants to sync preferences.
		[Preferences importPrefs:message];
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REGISTER_DEVICE])
	{
		// The phone app is asking the watch to register itself.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_INTERVAL_WORKOUTS])
	{
		// The phone app is sending interval workouts.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_CHECK_ACTIVITY])
	{
		// The phone app wants to know if we have an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REQUEST_ACTIVITY])
	{
		// The phone app is requesting an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_ACTIVITY])
	{
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
