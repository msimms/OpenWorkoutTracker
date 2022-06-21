// Created by Michael Simms on 6/17/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <NearbyInteraction/NearbyInteraction.h>

#import "Sensor.h"

// Subscribe to the notification with this name to receive updates.
#define NOTIFICATION_NAME_NEARBY_INTERACTION "Nearby Interaction"

#if !OMIT_BROADCAST

@interface NearbyInteractions : NSObject <NISessionDelegate, Sensor>
{
	NISession* niSession;
}

- (id)init;

- (SensorType)sensorType;

- (void)enteredBackground;
- (void)enteredForeground;

- (void)startUpdates;
- (void)stopUpdates;
- (void)update;

#endif

@end
