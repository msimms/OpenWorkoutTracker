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

#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/in.h>

#if TARGET_IPHONE_SIMULATOR
#define BROADCAST_HOST_NAME "10.0.1.5"
#else
#define BROADCAST_HOST_NAME "exert-app.com"
#endif

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
	[self flushGlobalBroadcastCache];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)broadcastLocally:(NSString*)text
{
	if (self->session)
	{
		[self->session sendMessage:text];
	}
}

- (NSString*)getHostName
{
	struct addrinfo* result;

	int error = getaddrinfo(BROADCAST_HOST_NAME, NULL, NULL, &result);
	if (error != 0)
	{
		return nil;
	}

	struct in_addr addr;
	addr.s_addr = ((struct sockaddr_in *)(result->ai_addr))->sin_addr.s_addr;
	return [[NSString alloc] initWithUTF8String:inet_ntoa(addr)];
}

- (void)flushGlobalBroadcastCache
{
	NSString* hostName = [self getHostName];
	if (hostName == nil)
	{
		return;
	}

	int sd = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
	if (sd <= 0)
	{
		return;
	}

	int flags = fcntl(sd, F_GETFL, 0);
	fcntl(sd, F_SETFL, flags | O_NONBLOCK);

	// Since we don't call bind() here, the system decides on the port for us, which is what we want.
	// Configure the port and ip we want to send to.
	struct sockaddr_in destAddr;
	memset(&destAddr, 0, sizeof destAddr);
	inet_pton(AF_INET, [hostName UTF8String], &destAddr.sin_addr);
	destAddr.sin_port = htons(5150);
	destAddr.sin_family = AF_INET;
	
	size_t numSent = 0;

	for (NSString* text in self->cache)
	{
		if (sendto(sd, [text UTF8String], [text length], 0, (struct sockaddr*)&destAddr, sizeof(destAddr)) == [text length])
		{
			++numSent;
		}
		else
		{
			break;
		}
	}

	if (numSent > 0)
	{
		NSIndexSet* indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numSent - 1)];
		[self->cache removeObjectsAtIndexes:indexSet];
	}

	self->lastCacheFlush = time(NULL);

	close(sd);
}

- (void)broadcastGlobally:(NSString*)text
{
	[self->cache addObject:text];

	// Flush at the user-specified interval. Default to 60 seconds if one was not specified.
	NSInteger rate = [Preferences broadcastRate];
	if ([self->cache count] > 0 && (time(NULL) - self->lastCacheFlush > rate))
	{
		[self flushGlobalBroadcastCache];
//		dispatch_async(dispatch_get_main_queue(), ^{ [self flushGlobalBroadcastCache]; });
	}
}

- (void)locationUpdated:(NSNotification*)notification
{
	if (!IsActivityInProgress())
	{
		return;
	}

	if (!self->activityId)
	{
		self->activityId = [[NSNumber alloc] initWithUnsignedLongLong:GetCurrentActivityId()];
	}

	NSDictionary* locationData = [notification object];
	if (locationData)
	{
		NSNumber* lat = [locationData objectForKey:@KEY_NAME_LATITUDE];
		NSNumber* lon = [locationData objectForKey:@KEY_NAME_LONGITUDE];
		CLLocation* curLoc = [[CLLocation alloc] initWithLatitude:[lat doubleValue] longitude:[lon doubleValue]];

		bool shouldBroadcast = true;

		// Only broadcast after moving a few meters.
		if (self->lastBroadcastLoc != nil)
		{
			CLLocationDistance dist = [curLoc distanceFromLocation:self->lastBroadcastLoc];
			shouldBroadcast = dist > 25;
		}

		if (shouldBroadcast)
		{
			NSMutableDictionary* broadcastData = [locationData mutableCopy];

			if (self->deviceId)
			{
				[broadcastData setObject:self->deviceId forKey:@KEY_NAME_DEVICE_ID];
			}
			if (self->activityId)
			{
				[broadcastData setObject:self->activityId forKey:@KEY_NAME_ACTIVITY_ID];
			}

			NSString* userName = [Preferences broadcastUserName];
			[broadcastData setObject:userName forKey:@KEY_NAME_USER_NAME];

			char* activityName = GetCurrentActivityName();
			if (activityName)
			{
				NSString* value = [[NSString alloc] initWithUTF8String:activityName];
				[broadcastData setObject:value forKey:@KEY_NAME_ACTIVITY_NAME];
				free((void*)activityName);
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

			self->lastBroadcastLoc = curLoc;
		}
	}
}

- (void)activityStarted:(NSNotification*)notification
{
	NSDictionary* activityData = [notification object];
	if (activityData)
	{
		self->activityId = [activityData objectForKey:@KEY_NAME_ACTIVITY_ID];
	}

	[self->cache removeAllObjects];
	self->lastCacheFlush = time(NULL);
}

- (void)activityStopped:(NSNotification*)notification
{
	[self flushGlobalBroadcastCache];
	self->activityId = nil;
}

@end
