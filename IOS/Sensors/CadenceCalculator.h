// Created by Michael Simms on 9/22/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface CadenceCalculator : NSObject
{
	bool     firstCadenceUpdate;
	uint16_t currentCadence;
	uint16_t lastCrankCount;
	uint16_t lastCrankCountTime;
	uint64_t lastCadenceUpdateTimeMs;
}

- (void)update:(uint64_t)curTimeMs withCrankCount:(uint16_t)currentCrankCount withCrankTime:(uint64_t)currentCrankTime fromPeripheral:(CBPeripheral*)peripheral;

@end
