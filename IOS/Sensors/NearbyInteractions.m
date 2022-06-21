// Created by Michael Simms on 6/17/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#import "NearbyInteractions.h"

#if !OMIT_BROADCAST

@implementation NearbyInteractions

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		self->niSession = nil;

		if ([NISession isSupported])
		{
			self->niSession = [[NISession alloc] init];
			self->niSession.delegate = self;
		}
	}
	return self;
}

#pragma mark NISessionDelegate methods

- (void)session:(NISession*)session didUpdateNearbyObjects:(NSArray<__kindof NINearbyObject*>*)nearbyObjects
{
}

- (void)session:(NISession*)session didGenerateShareableConfigurationData:(NSData*)shareableConfigurationData forObject:(NINearbyObject*)object
{
}

- (void)session:(NISession*)session didRemoveNearbyObjects:(NSArray<__kindof NINearbyObject*>*)nearbyObjects withReason:(NINearbyObjectRemovalReason)reason
{
}

- (void)sessionWasSuspended:(NISession*)session
{
}

- (void)sessionSuspensionEnded:(NISession*)session
{
}

- (void)session:(NISession*)session didInvalidateWithError:(NSError*)error
{
}

#pragma mark Sensor methods

- (void)enteredBackground
{	
}

- (void)enteredForeground
{
}

- (SensorType)sensorType
{
	return SENSOR_TYPE_NEARBY;
}

- (void)startUpdates
{
}

- (void)stopUpdates
{
}

- (void)update
{
}

@end

#endif

