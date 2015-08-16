// Created by Michael Simms on 7/21/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

#import "SensorType.h"

@protocol Sensor <NSObject>

- (SensorType)sensorType;

- (void)enteredBackground;
- (void)enteredForeground;

- (void)startUpdates;
- (void)stopUpdates;
- (void)update;

@end
