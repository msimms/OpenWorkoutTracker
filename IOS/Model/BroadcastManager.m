// Created by Michael Simms on 4/8/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "BroadcastManager.h"
#import "Accelerometer.h"
#import "ActivityMgr.h"
#import "ActivityAttribute.h"
#import "LocationSensor.h"
#import "Notifications.h"
#import "Preferences.h"
#import "Urls.h"

#if !OMIT_BROADCAST

#define MESSAGE_ERROR_SENDING NSLocalizedString(@"Error sending to the server", nil)

@implementation BroadcastManager

- (id)init
{
	if (self = [super init])
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accelerometerUpdated:) name:@NOTIFICATION_NAME_ACCELEROMETER object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:@NOTIFICATION_NAME_LOCATION object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityStarted:) name:@NOTIFICATION_NAME_ACTIVITY_STARTED object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityStopped:) name:@NOTIFICATION_NAME_ACTIVITY_STOPPED object:nil];

		self->locationCache = [[NSMutableArray alloc] init];
		self->accelerometerCache = [[NSMutableArray alloc] init];
		self->lastCacheFlush = 0;
		self->errorSending = FALSE;
		self->deviceId = NULL;
	}
	return self;
}

- (void)dealloc
{
	[self flushGlobalBroadcastCacheRest];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setDeviceId:(NSString*)deviceId
{
	self->deviceId = deviceId;
}

- (void)displayMessage:(NSString*)text
{	
	NSDictionary* msgData = [[NSDictionary alloc] initWithObjectsAndKeys:text, @KEY_NAME_MESSAGE, nil];

	[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_PRINT_MESSAGE object:msgData];
}

- (void)updateBroadcastStatus:(BOOL)status
{
	NSNumber* numStatus = [[NSNumber alloc] initWithBool:status];
	NSDictionary* msgData = [[NSDictionary alloc] initWithObjectsAndKeys:numStatus, @KEY_NAME_STATUS, nil];

	[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_BROADCAST_STATUS object:msgData];
}

- (void)sendToServer:(NSString*)hostName withPath:(const char*)path withData:(NSMutableData*)data
{
	NSString* protocolStr = [Preferences broadcastProtocol];
	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%s", protocolStr, hostName, path];
	NSString* postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[data length]];

	NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
	request.timeoutInterval = 30.0;
	request.allowsExpensiveNetworkAccess = TRUE;
	[request setURL:[NSURL URLWithString:urlStr]];
	[request setHTTPMethod:@"POST"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:data];

	self->dataBeingSent = data;

	NSURLSession* session = [NSURLSession sharedSession];
	NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request
												completionHandler:^(NSData* data, NSURLResponse* response, NSError* error)
	{
		NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;

		if ([httpResponse statusCode] == 200)
		{
			[self updateBroadcastStatus:TRUE];
			self->dataBeingSent = nil;
			self->errorSending = FALSE;
		}
		else
		{
			[self displayMessage:MESSAGE_ERROR_SENDING];
			[self updateBroadcastStatus:FALSE];
			self->errorSending = TRUE;
		}
	}];
	[dataTask resume];
}

- (void)flushGlobalBroadcastCacheRest
{
	// No host name set, just return.
	NSString* hostName = [Preferences broadcastHostName];
	if (hostName == nil)
	{
		NSLog(@"Broadcast host name not specified.");
		return;
	}

	// Still waiting on last data to be sent.
	if (self->dataBeingSent)
	{
		if (self->errorSending)
		{
			[self sendToServer:hostName withPath:REMOTE_API_UPDATE_STATUS_URL withData:self->dataBeingSent];
			NSLog(@"Resending.");
		}
		else
		{
			NSLog(@"Waiting on previous data to be sent.");
		}
		self->lastCacheFlush = time(NULL);
		return;
	}

	// Write cached location data to the JSON string.
	NSString* post = [NSString stringWithFormat:@"{\"locations\": ["];
	if (!post)
	{
		NSLog(@"Out of memory.");
		self->lastCacheFlush = time(NULL);
		return;
	}
	NSMutableData* postData = [[post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] mutableCopy];
	if (!postData)
	{
		NSLog(@"Out of memory.");
		self->lastCacheFlush = time(NULL);
		return;
	}
	size_t numLocObjsBeingSent = 0;
	for (NSString* text in self->locationCache)
	{
		if (numLocObjsBeingSent > 0)
			[postData appendData:[[NSString stringWithFormat:@",\n"] dataUsingEncoding:NSASCIIStringEncoding]];
		[postData appendData:[text dataUsingEncoding:NSASCIIStringEncoding]];
		++numLocObjsBeingSent;
	}
	[self->locationCache removeAllObjects];
	[postData appendData:[[NSString stringWithFormat:@"]"] dataUsingEncoding:NSASCIIStringEncoding]];

	// Write cached acclerometer data to the JSON string.
	[postData appendData:[[NSString stringWithFormat:@", \"accelerometer\": ["] dataUsingEncoding:NSASCIIStringEncoding]];
	size_t numAccelObjsBeingSent = 0;
	for (NSString* text in self->accelerometerCache)
	{
		if (numAccelObjsBeingSent > 0)
			[postData appendData:[[NSString stringWithFormat:@",\n"] dataUsingEncoding:NSASCIIStringEncoding]];
		[postData appendData:[text dataUsingEncoding:NSASCIIStringEncoding]];
		++numAccelObjsBeingSent;
	}
	[self->accelerometerCache removeAllObjects];
	[postData appendData:[[NSString stringWithFormat:@"]"] dataUsingEncoding:NSASCIIStringEncoding]];

	// Add the device ID to the JSON string.
	if (self->deviceId)
	{
		[postData appendData:[[NSString stringWithFormat:@",\n\"%s\":\"%@\"", KEY_NAME_DEVICE_ID, self->deviceId] dataUsingEncoding:NSASCIIStringEncoding]];
	}

	// Add the activity ID to the JSON string.
	NSString* activityId = [[NSString alloc] initWithFormat:@"%s", GetCurrentActivityId()];
	if (activityId)
	{
		[postData appendData:[[NSString stringWithFormat:@",\n\"%s\":\"%@\"", KEY_NAME_ACTIVITY_ID, activityId] dataUsingEncoding:NSASCIIStringEncoding]];
	}

	// Add the activity type to the JSON string.
	char* activityType = GetCurrentActivityType();
	if (activityType)
	{
		[postData appendData:[[NSString stringWithFormat:@",\n\"%s\":\"%s\"", KEY_NAME_ACTIVITY_TYPE, activityType] dataUsingEncoding:NSASCIIStringEncoding]];
		free((void*)activityType);
	}

	// Add the user name to the JSON string.
	NSString* userName = [Preferences broadcastUserName];
	if (userName)
	{
		[postData appendData:[[NSString stringWithFormat:@",\n\"%s\":\"%@\"", ACTIVITY_ATTRIBUTE_USER_NAME, userName] dataUsingEncoding:NSASCIIStringEncoding]];
	}

	[postData appendData:[[NSString stringWithFormat:@"}\n"] dataUsingEncoding:NSASCIIStringEncoding]];

	if ((numLocObjsBeingSent > 0) || (numAccelObjsBeingSent > 0))
	{
		[self sendToServer:hostName withPath:REMOTE_API_UPDATE_STATUS_URL withData:postData];
	}

	self->lastCacheFlush = time(NULL);
}

- (void)broadcast
{
	// Flush at the user-specified interval. Default to 60 seconds if one was not specified.
	NSInteger rate = [Preferences broadcastRate];
	if (([self->locationCache count] > 0 || [self->accelerometerCache count] > 0) && (time(NULL) - self->lastCacheFlush > rate))
	{
		[self flushGlobalBroadcastCacheRest];
	}
}

- (void)accelerometerUpdated:(NSNotification*)notification
{
	if (![Preferences shouldBroadcastToServer])
	{
		return;
	}
	if (!IsActivityInProgress())
	{
		return;
	}
	if (!IsLiftingActivity())
	{
		return;
	}

	NSDictionary* accelerometerData = [notification object];

	NSError* error;
	NSData* jsonData = [NSJSONSerialization dataWithJSONObject:accelerometerData options:NSJSONWritingPrettyPrinted error:&error];
	NSString* text = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

	[self->accelerometerCache addObject:text];
	[self broadcast];
}

- (void)locationUpdated:(NSNotification*)notification
{
	if (![Preferences shouldBroadcastToServer])
	{
		return;
	}
	if (!IsActivityInProgress())
	{
		return;
	}
	if (!IsMovingActivity())
	{
		return;
	}

	NSDictionary* locationData = [notification object];
	NSMutableDictionary* broadcastData = [locationData mutableCopy];

	ActivityAttributeType attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED);
	if (attr.valid)
	{
		NSNumber* value = [[NSNumber alloc] initWithDouble:attr.value.doubleVal];
		[broadcastData setObject:value forKey:@ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED];
	}

	attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_AVG_SPEED);
	if (attr.valid)
	{
		ConvertToBroadcastUnits(&attr);
		NSNumber* value = [[NSNumber alloc] initWithDouble:attr.value.doubleVal];
		[broadcastData setObject:value forKey:@ACTIVITY_ATTRIBUTE_AVG_SPEED];
	}

	attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_CURRENT_SPEED);
	if (attr.valid)
	{
		ConvertToBroadcastUnits(&attr);
		NSNumber* value = [[NSNumber alloc] initWithDouble:attr.value.doubleVal];
		[broadcastData setObject:value forKey:@ACTIVITY_ATTRIBUTE_CURRENT_SPEED];
	}

	attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_MOVING_SPEED);
	if (attr.valid)
	{
		ConvertToBroadcastUnits(&attr);
		NSNumber* value = [[NSNumber alloc] initWithDouble:attr.value.doubleVal];
		[broadcastData setObject:value forKey:@ACTIVITY_ATTRIBUTE_MOVING_SPEED];
	}

	attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_AVG_PACE);
	if (attr.valid)
	{
		ConvertToBroadcastUnits(&attr);
		NSNumber* value = [[NSNumber alloc] initWithDouble:attr.value.doubleVal];
		[broadcastData setObject:value forKey:@ACTIVITY_ATTRIBUTE_AVG_PACE];
	}

	attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_AVG_HEART_RATE);
	if (attr.valid)
	{
		NSNumber* value = [[NSNumber alloc] initWithDouble:attr.value.doubleVal];
		[broadcastData setObject:value forKey:@ACTIVITY_ATTRIBUTE_AVG_HEART_RATE];
	}

	attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_HEART_RATE);
	if (attr.valid)
	{
		NSNumber* value = [[NSNumber alloc] initWithDouble:attr.value.doubleVal];
		[broadcastData setObject:value forKey:@ACTIVITY_ATTRIBUTE_HEART_RATE];
	}

	attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_AVG_CADENCE);
	if (attr.valid)
	{
		NSNumber* value = [[NSNumber alloc] initWithDouble:attr.value.doubleVal];
		[broadcastData setObject:value forKey:@ACTIVITY_ATTRIBUTE_AVG_CADENCE];
	}

	attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_CADENCE);
	if (attr.valid)
	{
		NSNumber* value = [[NSNumber alloc] initWithDouble:attr.value.doubleVal];
		[broadcastData setObject:value forKey:@ACTIVITY_ATTRIBUTE_CADENCE];
	}

	attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_AVG_POWER);
	if (attr.valid)
	{
		NSNumber* value = [[NSNumber alloc] initWithDouble:attr.value.doubleVal];
		[broadcastData setObject:value forKey:@ACTIVITY_ATTRIBUTE_AVG_POWER];
	}

	attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_POWER);
	if (attr.valid)
	{
		NSNumber* value = [[NSNumber alloc] initWithDouble:attr.value.doubleVal];
		[broadcastData setObject:value forKey:@ACTIVITY_ATTRIBUTE_POWER];
	}

	NSError* error;
	NSData* jsonData = [NSJSONSerialization dataWithJSONObject:broadcastData options:NSJSONWritingPrettyPrinted error:&error];
	NSString* text = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

	[self->locationCache addObject:text];
	[self broadcast];
}

- (void)activityStarted:(NSNotification*)notification
{
	[self->locationCache removeAllObjects];
	[self->accelerometerCache removeAllObjects];
	self->lastCacheFlush = time(NULL);
}

- (void)activityStopped:(NSNotification*)notification
{
	[self flushGlobalBroadcastCacheRest];
}

@end

#endif
