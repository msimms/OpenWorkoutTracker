// Created by Michael Simms on 1/23/15.
// Copyright (c) 2015 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "WiFiDiscovery.h"
#import "WiFiSensor.h"
#import "SensorFactory.h"

#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/in.h>

@implementation WiFiDiscovery

+ (id)sharedInstance
{
	static WiFiDiscovery* this = nil;
	
	if (!this)
	{
		this = [[WiFiDiscovery alloc] init];
	}
	return this;
}

- (id)init
{
	self = [super init];
	if (self)
	{
		self->discoveryDelegates = [[NSMutableArray alloc] init];
		self->discoveredSensors  = [[NSMutableArray alloc] init];

		[self startScanning];
	}
	return self;
}

#pragma mark methods for managing delegates

- (void)addDelegate:(id<DiscoveryDelegate>)newDelegate
{
	@synchronized(self->discoveryDelegates)
	{
		for (id<DiscoveryDelegate> delegate in self->discoveryDelegates)
		{
			if (delegate == newDelegate)
			{
				return;
			}
		}
		
		[self->discoveryDelegates addObject:newDelegate];
	}
}

- (void)removeDelegate:(id<DiscoveryDelegate>)oldDelegate
{
	@synchronized(self->discoveryDelegates)
	{
		if (self->discoveryDelegates)
		{
			[self->discoveryDelegates removeObject:oldDelegate];
		}
	}
}

- (void)refreshDelegates
{
	@synchronized(self->discoveryDelegates)
	{
		if (self->discoveryDelegates)
		{
			[self->discoveryDelegates makeObjectsPerformSelector:@selector(discoveryDidRefresh)];
		}
	}
}

#pragma mark discovery methods

- (void)startScanning
{
	self->scanTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow: 3.0]
											   interval:5
												 target:self
											   selector:@selector(onScanTimer:)
											   userInfo:nil
												repeats:YES];
	NSRunLoop* runner = [NSRunLoop currentRunLoop];
	if (runner)
	{
		[runner addTimer:self->scanTimer forMode: NSDefaultRunLoopMode];
	}
}

- (void)stopScanning
{
	[self->scanTimer invalidate];
	self->scanTimer = NULL;
}

#pragma mark utility methods

- (NSString*)getHostName:(char*)str
{
	struct addrinfo* result;
	
	int error = getaddrinfo(str, NULL, NULL, &result);
	if (error != 0)
	{
		return nil;
	}
	
	struct in_addr addr;
	addr.s_addr = ((struct sockaddr_in *)(result->ai_addr))->sin_addr.s_addr;
	return [[NSString alloc] initWithUTF8String:inet_ntoa(addr)];
}

- (bool)canConnect:(char*)hostName
{
	NSString* ipAddrStr = [self getHostName:hostName];
	if (ipAddrStr == nil)
	{
		return false;
	}
	
	int sd = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
	if (sd <= 0)
	{
		return false;
	}
	
	struct sockaddr_in hostAddr;
	memset(&hostAddr, 0, sizeof(hostAddr));
	hostAddr.sin_family      = AF_INET;
	hostAddr.sin_addr.s_addr = inet_addr([ipAddrStr UTF8String]);
	hostAddr.sin_port        = htons(80);

	int flags = fcntl(sd, F_GETFL, 0);
	fcntl(sd, F_SETFL, flags | O_NONBLOCK);
	
	if ((connect(sd, (struct sockaddr*)&hostAddr, sizeof(hostAddr)) < 0) && (errno != EINPROGRESS))
	{
		close(sd);
		return false;
	}
	
	close(sd);
	
	return true;
}

- (bool)alreadyDiscovered:(SensorType)type
{
	for (WiFiSensor* sensor in self->discoveredSensors)
	{
		if ([sensor sensorType] == type)
		{
			return true;
		}
	}
	return false;
}

#pragma mark timer methods

- (void)onScanTimer:(NSTimer*)timer
{
	@synchronized(self->discoveredSensors)
	{
		WiFiSensor* sensor;
		
//		if (![self alreadyDiscovered:SENSOR_TYPE_GOPRO] && [self canConnect:GOPRO_IP_ADDR])
//		{
//			sensor = [[[SensorFactory alloc] init] createGoPro];
//		}

		if (sensor)
		{
			[self->discoveredSensors addObject:sensor];
		}
	}
	
	[self refreshDelegates];
}

@end
