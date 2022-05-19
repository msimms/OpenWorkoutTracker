//  Created by Michael Simms on 7/28/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "WatchSessionManager.h"
#import "WatchMessages.h"
#import "Cookies.h"
#import "ExtensionDelegate.h"
#import "FileUtils.h"
#import "Notifications.h"
#import "Params.h"
#import "Preferences.h"

@interface WatchSessionManager ()

@end


@implementation WatchSessionManager

- (void)startWatchSession
{
	self->watchSession = [WCSession defaultSession];
	self->watchSession.delegate = self;
	[self->watchSession activateSession];
	self->timeOfLastPhoneMsg = 0;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityStopped:) name:@NOTIFICATION_NAME_ACTIVITY_STOPPED object:nil];
}

/// @brief Requests the user's preferences from the phone.
- (void)sendSyncPrefsMsg
{
	NSDictionary* msgData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@WATCH_MSG_SYNC_PREFS, @WATCH_MSG_TYPE, nil];
	[self->watchSession sendMessage:msgData replyHandler:nil errorHandler:nil];
}

/// @brief Sends our unique identifier to the phone.
- (void)sendRegisterDeviceMsg
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
	NSDictionary* msgData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@WATCH_MSG_REGISTER_DEVICE,
							 @WATCH_MSG_TYPE,
							 [extDelegate getDeviceId], @WATCH_MSG_PARAM_DEVICE_ID,
							 nil];
	[self->watchSession sendMessage:msgData replyHandler:nil errorHandler:nil];
}

/// @brief Called to request a new session key from the phone. The session key is needed for sending to the (optional) server (from an LTE-enabled watch)
/// and has be be requested from the phone since the watch doesn't have a good way to enter a username and password.
- (void)sendRequestSessionKeyMsg
{
	NSDictionary* msgData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@WATCH_MSG_REQUEST_SESSION_KEY, @WATCH_MSG_TYPE, nil];
	[self->watchSession sendMessage:msgData replyHandler:^(NSDictionary<NSString *,id>* replyMessage) {
		NSString* sessionCookieStr = [replyMessage objectForKey:@WATCH_MSG_PARAM_SESSION_KEY];
		NSDate* expiryDate = [replyMessage objectForKey:@WATCH_MSG_PARAM_SESSION_KEY_EXPIRY];

		// Dictionary containing the cookie and the associated expiry date.
		NSMutableDictionary* cookieProperties = [NSMutableDictionary dictionary];
		[cookieProperties setObject:@SESSION_COOKIE_NAME forKey:NSHTTPCookieName];
		[cookieProperties setObject:sessionCookieStr forKey:NSHTTPCookieValue];
		[cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
		[cookieProperties setObject:[Preferences broadcastHostName] forKey:NSHTTPCookieDomain];
		[cookieProperties setObject:expiryDate forKey:NSHTTPCookieExpires];
		[cookieProperties setObject:@"TRUE" forKey:NSHTTPCookieSecure];

		// Add the cookie to the local cookie store.
		NSHTTPCookie* cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];

		// Force sync - necessary in case of an abrupt shutdown.
		[[NSUserDefaults standardUserDefaults] synchronize];

	} errorHandler:^(NSError* error) {
		NSLog(@"Failed to request a session key from the phone.");
	}];
}

/// @brief Called when connecting to the phone so we can determine which activities to send.
- (void)checkIfActivitiesAreUploadedToPhone
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
	size_t numHistoricalActivities = [extDelegate getNumHistoricalActivities];
	size_t numRequestedSyncs = 0; // Keeps track of how many activities we are currently trying to sync, don't want to overwhelm ourselves.

	// Only reload the historical activities list if we really have to as it's rather
	// computationally expensive for something running on a watch.
	if (numHistoricalActivities == 0)
	{
		numHistoricalActivities = [extDelegate initializeHistoricalActivityList];
	}

	if (numHistoricalActivities > 0)
	{
		// Check each activity. Loop in reverse order because the most recent activities are probably the most interesting.
		for (size_t i = numHistoricalActivities - 1; i > 0 && numRequestedSyncs < 1; i--)
		{
			NSString* activityId = [extDelegate getActivityIdFromActivityIndex:i];

			// If it's already been synched then skip it. Otherwise, offer up the activity.
			if ([extDelegate isSyncedToPhone:activityId] == FALSE)
			{
				[self sendActivityFileToPhone:activityId];
				++numRequestedSyncs;
			}
		}
	}
}

/// @brief Asks the watch to send interval workouts.
- (void)requestIntervalWorkoutsFromPhone
{
	NSDictionary* msgData = [[NSDictionary alloc] initWithObjectsAndKeys: @WATCH_MSG_DOWNLOAD_INTERVAL_WORKOUTS, @WATCH_MSG_TYPE, nil];

	[self->watchSession sendMessage:msgData replyHandler:^(NSDictionary<NSString*, id>* replyMessage) {
		[self loadIntervalWorkout:replyMessage];
	} errorHandler:^(NSError* error) {
		NSLog(@"Failed to request the interval workouts from the phone.");
	}];
}

/// @brief Asks the phone to send pace plans.
- (void)requestPacePlansFromPhone
{
	NSDictionary* msgData = [[NSDictionary alloc] initWithObjectsAndKeys:@WATCH_MSG_DOWNLOAD_PACE_PLANS, @WATCH_MSG_TYPE, nil];

	[self->watchSession sendMessage:msgData replyHandler:^(NSDictionary<NSString*, id>* replyMessage) {
		[self loadPacePlan:replyMessage];
	} errorHandler:^(NSError* error) {
		NSLog(@"Failed to request the pace plans from the phone.");
	}];
}

/// @brief Called when the phone sends an interval workout to the watch.
- (void)loadIntervalWorkout:(nonnull NSDictionary<NSString*,id> *)message
{
}

/// @brief Called when the phone sends a pace plan to the watch.
- (void)loadPacePlan:(nonnull NSDictionary<NSString*,id> *)message
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;

	NSString* planId = [message objectForKey:@PARAM_PACE_PLAN_ID];
	NSString* planName = [message objectForKey:@PARAM_PACE_PLAN_NAME];
	NSString* targetPaceInMinKm = [message objectForKey:@PARAM_PACE_PLAN_TARGET_PACE];
	NSString* targetDistanceInKms = [message objectForKey:@PARAM_PACE_PLAN_TARGET_DISTANCE];
	NSString* splits = [message objectForKey:@PARAM_PACE_PLAN_SPLITS];
	NSString* route = [message objectForKey:@PARAM_PACE_PLAN_ROUTE];
	NSString* targetPaceUnits = [message objectForKey:@PARAM_PACE_PLAN_TARGET_PACE_UNITS];
	NSString* targetDistanceUnits = [message objectForKey:@PARAM_PACE_PLAN_TARGET_DISTANCE_UNITS];

	[extDelegate createPacePlan:planId withPlanName:planName withTargetPaceInMinKm:[targetPaceInMinKm floatValue] withTargetDistanceInKms:[targetDistanceInKms floatValue] withSplits:[splits floatValue] withTargetDistanceUnits:(UnitSystem)[targetDistanceUnits intValue] withTargetPaceUnits:(UnitSystem)[targetPaceUnits intValue] withRoute:route];
}

/// @brief Sends the activity to the phone. Returns TRUE on success, FALSE on failure.
- (BOOL)sendActivityFileToPhone:(NSString*)activityId
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
	size_t numHistoricalActivities = [extDelegate getNumHistoricalActivities];
	BOOL result = FALSE;

	// Only reload the historical activities list if we really have to as it's rather
	// computationally expensive for something running on a watch.
	if (numHistoricalActivities == 0)
	{
		numHistoricalActivities = [extDelegate initializeHistoricalActivityList];
	}

	if (numHistoricalActivities > 0)
	{
		NSInteger activityIndex = [extDelegate getActivityIndexFromActivityId:activityId];
		NSString* activityType = [extDelegate getHistoricalActivityType:activityIndex];

		if (activityId && activityType)
		{
			FileFormat fileFormat = [extDelegate preferredExportFormatForActivityType:activityType];
			NSString* activityName = [extDelegate getHistoricalActivityName:activityIndex];

			time_t tempStartTime = 0;
			time_t tempEndTime = 0;

			[extDelegate getHistoricalActivityStartAndEndTime:activityIndex withStartTime:&tempStartTime withEndTime:&tempEndTime];

			NSNumber* startTime = [NSNumber numberWithUnsignedLongLong:tempStartTime];
			NSNumber* endTime = [NSNumber numberWithUnsignedLongLong:tempEndTime];
			NSNumber* fileFormatObj = [NSNumber numberWithInt:fileFormat];

			NSMutableDictionary* activityMetaData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
													 activityId, @WATCH_MSG_PARAM_ACTIVITY_ID,
													 activityType, @WATCH_MSG_PARAM_ACTIVITY_TYPE,
													 activityName, @WATCH_MSG_PARAM_ACTIVITY_NAME,
													 startTime, @WATCH_MSG_PARAM_ACTIVITY_START_TIME,
													 endTime, @WATCH_MSG_PARAM_ACTIVITY_END_TIME,
													 fileFormatObj, @WATCH_MSG_PARAM_FILE_FORMAT,
													 nil];

			NSURL* groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier: @"group.mjs-software.OpenWorkoutTracker"];
			if (groupURL)
			{
				NSString* exportFileName = [extDelegate exportActivityToFile:activityId withFileFormat:fileFormat toDirName:[groupURL path] ];
				if (exportFileName)
				{
					NSURL* exportUrl = [NSURL fileURLWithPath:exportFileName];
					[self->watchSession transferFile:exportUrl metadata:activityMetaData];
					return TRUE;
				}
				else
				{
				   NSLog(@"Activity export failed (file export).");
				}
			}
			else
			{
				NSLog(@"Activity export failed (nil group URL).");
			}
		}
		else
		{
			NSLog(@"Missing required attributes when sending an activity to the phone.");
		}
	}
	else
	{
		NSLog(@"Failed to load the activities list when sending an activity to the phone.");
	}
	
	return result;
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
			break;
	}
}

- (void)sessionReachabilityDidChange:(nonnull WCSession*)session
{
	if (session.reachable)
	{
		// Startup stuff.
		if (self->timeOfLastPhoneMsg == 0)
		{
			[self sendRegisterDeviceMsg];
			[self sendRequestSessionKeyMsg];
			[self requestIntervalWorkoutsFromPhone];
			[self requestPacePlansFromPhone];
		}

		// Rate limit the server synchronizations. Let's not be spammy.
		if (time(NULL) - self->timeOfLastPhoneMsg > 60)
		{
			[self checkIfActivitiesAreUploadedToPhone];
			self->timeOfLastPhoneMsg = time(NULL);
		}
	}
}

- (void)session:(nonnull WCSession*)session didReceiveMessage:(nonnull NSDictionary<NSString*,id> *)message replyHandler:(nonnull void (^)(NSDictionary<NSString*,id> * __nonnull))replyHandler
{
	// Don't process phone messages when we're doing an activity.
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
	if ([extDelegate isActivityInProgress])
	{
		return;
	}

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
	else if ([msgType isEqualToString:@WATCH_MSG_REQUEST_SESSION_KEY])
	{
		// This message should only be sent from the watch to the phone.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_INTERVAL_WORKOUTS])
	{
		// The phone app wants to download interval workouts.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_PACE_PLANS])
	{
		// The phone app wants to download pace plans.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_INTERVAL_WORKOUT])
	{
		// The phone app is sending an interval workout.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_PACE_PLAN])
	{
		// The phone app is sending a pace plan.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_CHECK_ACTIVITY])
	{
		// The phone app wants to know if we have an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REQUEST_ACTIVITY])
	{
		// The phone app is requesting an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_MARK_ACTIVITY_AS_SYNCHED])
	{
		// The phone app is telling us to mark an activity as synchronized.
	}

	self->timeOfLastPhoneMsg = time(NULL);
}

- (void)session:(nonnull WCSession*)session didReceiveMessage:(NSDictionary<NSString*,id> *)message
{
	// Don't process phone messages when we're doing an activity.
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
	if ([extDelegate isActivityInProgress])
	{
		return;
	}

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
	else if ([msgType isEqualToString:@WATCH_MSG_REQUEST_SESSION_KEY])
	{
		// This message should only be sent from the watch to the phone.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_INTERVAL_WORKOUTS])
	{
		// The phone app wants to download interval workouts.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_PACE_PLANS])
	{
		// The phone app wants to download pace plans.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_INTERVAL_WORKOUT])
	{
		// The phone app is sending an interval workout.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_PACE_PLAN])
	{
		// The phone app is sending a pace plan.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_CHECK_ACTIVITY])
	{
		// The phone app wants to know if we have an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REQUEST_ACTIVITY])
	{
		// The phone app is requesting an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_MARK_ACTIVITY_AS_SYNCHED])
	{
		// The phone app is telling us to mark an activity as synchronized.
	}

	self->timeOfLastPhoneMsg = time(NULL);
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

- (void)session:(nonnull WCSession*)session didFinishFileTransfer:(WCSessionFileTransfer*)fileTransfer error:(nullable NSError*)error
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
	NSString* fileName = [[fileTransfer.file fileURL] absoluteString];
	NSString* activityId = [fileTransfer.file.metadata objectForKey:@WATCH_MSG_PARAM_ACTIVITY_ID];

	[FileUtils deleteFile:fileName];
	[extDelegate markAsSynchedToPhone:activityId];
}

- (void)session:(nonnull WCSession*)session didFinishUserInfoTransfer:(WCSessionUserInfoTransfer*)userInfoTransfer error:(NSError*)error
{
}

/// @brief This method is called in response to activity stopped notification.
- (void)activityStopped:(NSNotification*)notification
{
}

@end
