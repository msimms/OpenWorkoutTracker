// Created by Michael Simms on 9/22/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "CadenceCalculator.h"

@implementation CadenceCalculator

#pragma mark init methods

- (void)update:(uint64_t)curTimeMs withCrankCount:(uint16_t)currentCrankCount withCrankTime:(uint64_t)currentCrankTime fromPeripheral:(CBPeripheral*)peripheral
{
	uint64_t msSinceLastUpdate = curTimeMs - self->lastCadenceUpdateTimeMs;

	double elapsedSecs;

	if (currentCrankTime >= self->lastCrankCountTime)	// handle wrap-around
	{
		elapsedSecs = (double)(currentCrankTime - self->lastCrankCountTime) / (double)1024.0;
	}
	else
	{
		uint32_t temp = 0x0000ffff + (uint32_t)currentCrankTime;
		elapsedSecs = (double)(temp - (uint32_t)self->lastCrankCountTime) / (double)1024.0;
	}

	// Compute the cadence (zero on the first iteration).
	if (self->firstCadenceUpdate)
	{
		self->currentCadence = 0;
	}
	else if (elapsedSecs > (double)0.0)
	{
		uint16_t newCrankCount = currentCrankCount - self->lastCrankCount;
		self->currentCadence = (uint16_t)(((double)newCrankCount / elapsedSecs) * (double)60.0);
	}

	// Handle cases where it has been a while since our last update (i.e. the crank is either not
	// turning or is turning very slowly).
	if (msSinceLastUpdate >= 3000)
	{
		self->currentCadence = 0;
	}

	NSDictionary* cadenceData = [[NSDictionary alloc] initWithObjectsAndKeys:
								 [NSNumber numberWithLong:self->currentCadence], @KEY_NAME_CADENCE,
								 [NSNumber numberWithLongLong:curTimeMs], @KEY_NAME_CADENCE_TIMESTAMP_MS,
								 peripheral, @KEY_NAME_PERIPHERAL_OBJ,
								 nil];
	if (cadenceData)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_BIKE_CADENCE object:cadenceData];
		self->lastCadenceUpdateTimeMs = curTimeMs;
	}

	firstCadenceUpdate = false;

	self->lastCrankCount = currentCrankCount;
	self->lastCrankCountTime = currentCrankTime;
}

@end
