// Created by Michael Simms on 8/5/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#import <Foundation/Foundation.h>

#import "BluetoothServices.h"
#import "BtleSensor.h"

// Subscribe to the notification with this name to receive updates.
#define NOTIFICATION_NAME_LIGHT_ON    "LightTurnedOn"

// Keys for the dictionary associated with the notification.
#define KEY_NAME_LIGHT                "Light"
#define KEY_NAME_LIGHT_PERIPHERAL_OBJ "Peripheral"

@interface BtleLight : BtleSensor
{
}

- (SensorType)sensorType;

- (void)enteredBackground;
- (void)enteredForeground;

- (void)startUpdates;
- (void)stopUpdates;
- (void)update;

@end
