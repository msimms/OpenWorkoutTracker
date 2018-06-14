// Created by Michael Simms on 4/8/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "BroadcastManager.h"
#import "ActivityMgr.h"
#import "ActivityAttribute.h"
#import "AppDelegate.h"
#import "LocationSensor.h"
#import "Preferences.h"

@implementation BroadcastManager

- (id)init
{
	if (self = [super init])
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:@NOTIFICATION_NAME_LOCATION object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityStarted:) name:@NOTIFICATION_NAME_ACTIVITY_STARTED object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityStopped:) name:@NOTIFICATION_NAME_ACTIVITY_STOPPED object:nil];

		self->session = [[BroadcastSessionContainer alloc] init];
		self->cache = [[NSMutableArray alloc] init];
		self->lastCacheFlush = 0;

		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		self->deviceId = [appDelegate getUuid];
	}
	return self;
}

- (void)dealloc
{
	[self flushGlobalBroadcastCacheRest];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)broadcastLocally:(NSString*)text
{
	if (self->session)
	{
		[self->session sendMessage:text];
	}
}

- (void)flushGlobalBroadcastCacheRest
{
	NSString* hostName = [Preferences broadcastHostName];
	if (hostName == nil)
	{
		return;
	}

	NSString* post = [NSString stringWithFormat:@"{\"locations\": ["];
	NSMutableData* postData = [[post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] mutableCopy];
	size_t numToSend = 0;

	for (NSString* text in self->cache)
	{
		if (numToSend > 0)
			[postData appendData:[[NSString stringWithFormat:@",\n"] dataUsingEncoding:NSASCIIStringEncoding]];
		[postData appendData:[text dataUsingEncoding:NSASCIIStringEncoding]];
		++numToSend;
	}
	[postData appendData:[[NSString stringWithFormat:@"]}\n"] dataUsingEncoding:NSASCIIStringEncoding]];
	
	if (numToSend > 0)
	{
		NSString* urlStr = [NSString stringWithFormat:@"https://%@/api/1.0/update_location", hostName];
		NSString* postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
		NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
		[request setURL:[NSURL URLWithString:urlStr]];
		[request setHTTPMethod:@"POST"];
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
		[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody:postData];

		NSURLConnection* conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
		if (conn != nil)
		{
			NSIndexSet* indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numToSend - 1)];
			[self->cache removeObjectsAtIndexes:indexSet];
		}
	}

	self->lastCacheFlush = time(NULL);
}

- (void)broadcastGlobally:(NSString*)text
{
	[self->cache addObject:text];

	// Flush at the user-specified interval. Default to 60 seconds if one was not specified.
	NSInteger rate = [Preferences broadcastRate];
	if ([self->cache count] > 0 && (time(NULL) - self->lastCacheFlush > rate))
	{
		[self flushGlobalBroadcastCacheRest];
	}
}

- (void)locationUpdated:(NSNotification*)notification
{
	if (!IsActivityInProgress())
	{
		return;
	}

	NSDictionary* locationData = [notification object];
	if (locationData)
	{
		NSMutableDictionary* broadcastData = [locationData mutableCopy];

		if (self->deviceId)
		{
			[broadcastData setObject:self->deviceId forKey:@KEY_NAME_DEVICE_ID];
		}

		NSString* activityId = [[NSString alloc] initWithFormat:@"%s", GetCurrentActivityId()];
		if (activityId)
		{
			[broadcastData setObject:activityId forKey:@KEY_NAME_ACTIVITY_ID];
		}

		char* activityType = GetCurrentActivityType();
		if (activityType)
		{
			NSString* value = [[NSString alloc] initWithUTF8String:activityType];
			[broadcastData setObject:value forKey:@KEY_NAME_ACTIVITY_TYPE];
			free((void*)activityType);
		}

		NSString* userName = [Preferences broadcastUserName];
		if (userName)
		{
			[broadcastData setObject:userName forKey:@ACTIVITY_ATTRIBUTE_USER_NAME];
		}

		ActivityAttributeType attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED);
		if (attr.valid)
		{
			NSNumber* value = [[NSNumber alloc] initWithDouble:attr.value.doubleVal];
			[broadcastData setObject:value forKey:@ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED];
		}

		attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_AVG_SPEED);
		if (attr.valid)
		{
			NSNumber* value = [[NSNumber alloc] initWithDouble:attr.value.doubleVal];
			[broadcastData setObject:value forKey:@ACTIVITY_ATTRIBUTE_AVG_SPEED];
		}
		
		attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_CURRENT_SPEED);
		if (attr.valid)
		{
			NSNumber* value = [[NSNumber alloc] initWithDouble:attr.value.doubleVal];
			[broadcastData setObject:value forKey:@ACTIVITY_ATTRIBUTE_CURRENT_SPEED];
		}
		
		attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_MOVING_SPEED);
		if (attr.valid)
		{
			NSNumber* value = [[NSNumber alloc] initWithDouble:attr.value.doubleVal];
			[broadcastData setObject:value forKey:@ACTIVITY_ATTRIBUTE_MOVING_SPEED];
		}

		attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_AVG_PACE);
		if (attr.valid)
		{
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
			[broadcastData setObject:value forKey:@ACTIVITY_ATTRIBUTE_AVG_CADENCE];
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

		if ([Preferences shouldBroadcastLocally])
		{
			[self broadcastLocally:text];
		}
		if ([Preferences shouldBroadcastGlobally])
		{
			[self broadcastGlobally:text];
		}
	}
}

- (void)activityStarted:(NSNotification*)notification
{
	[self->cache removeAllObjects];
	self->lastCacheFlush = time(NULL);
}

- (void)activityStopped:(NSNotification*)notification
{
	[self flushGlobalBroadcastCacheRest];
}

#pragma mark delegate methods

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
}

@end
