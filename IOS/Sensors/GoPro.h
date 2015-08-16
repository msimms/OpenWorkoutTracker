// Created by Michael Simms on 1/23/15.
// Copyright (c) 2015 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

#import "WiFiSensor.h"

#define GOPRO_IP_ADDR "10.5.5.9"

@interface GoPro : WiFiSensor
{
	NSString* password;
}

- (SensorType)sensorType;

- (void)enteredBackground;
- (void)enteredForeground;

- (void)startUpdates;
- (void)stopUpdates;
- (void)update;

- (void)setPassword:(NSString*)newPassword;
- (void)powerOff;
- (void)powerOn;
- (void)changeMode;
- (void)stopCapture;
- (void)startCapture;
- (void)previewOff;
- (void)previewOn;

- (void)captureFrame;
- (void)listImageFiles;

@end
