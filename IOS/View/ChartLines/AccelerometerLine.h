// Created by Michael Simms on 2/9/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.#import <UIKit/UIKit.h>

#import "ChartLine.h"

typedef enum Axis
{
	AXIS_X = 0,
	AXIS_Y,
	AXIS_Z
} Axis;

@interface AccelerometerLine : ChartLine

- (void)setAxis:(Axis)axis;
- (void)draw;

@end
