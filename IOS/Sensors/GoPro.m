// Created by Michael Simms on 1/23/15.
// Copyright (c) 2015 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "GoPro.h"

@implementation GoPro

#pragma mark characteristics methods

- (SensorType)sensorType
{
	return SENSOR_TYPE_GOPRO;
}

- (void)enteredBackground
{
}

- (void)enteredForeground
{
}

- (void)startUpdates
{
}

- (void)stopUpdates
{
}

- (void)update
{
	[self listImageFiles];
}

#pragma mark methods

- (void)send:(NSString*)group withAction:(NSString*)action
{
	NSString* urlStr = [[NSString alloc] initWithFormat:@"http://%s/camera/%@?t=%@=%@", GOPRO_IP_ADDR, group, self->password, action];
	NSURL* url = [[NSURL alloc] initWithString:urlStr];
	[[UIApplication sharedApplication] openURL:url];
}

- (void)setPassword:(NSString*)newPassword
{
	self->password = newPassword;
}

- (void)powerOff
{
	[self send:@"PW" withAction:@"00"];
}

- (void)powerOn
{
	[self send:@"PW" withAction:@"01"];
}

- (void)changeMode
{
	[self send:@"PW" withAction:@"02"];
}

- (void)stopCapture
{
	[self send:@"SH" withAction:@"00"];
}

- (void)startCapture
{
	[self send:@"SH" withAction:@"01"];
}

- (void)previewOff
{
	[self send:@"PV" withAction:@"00"];
}

- (void)previewOn
{
	[self send:@"PV" withAction:@"02"];
}

- (void)setModeVideo
{
	[self send:@"CM" withAction:@"00"];
}

- (void)setModePhoto
{
	[self send:@"CM" withAction:@"01"];
}

- (void)setModeBurst
{
	[self send:@"CM" withAction:@"02"];
}

- (void)setModeTimeLapse
{
	[self send:@"CM" withAction:@"03"];
}

- (void)captureFrame
{
	NSString* urlStr = [[NSString alloc] initWithFormat:@"10.5.5.9:8080/live/amba.m3u8"];
	NSURL* url = [[NSURL alloc] initWithString:urlStr];
	[[UIApplication sharedApplication] openURL:url];
}

- (void)listImageFiles
{
	NSString* urlStr = [[NSString alloc] initWithFormat:@"http://10.5.5.9:8080/videos/DCIM/115GOPRO/"];
	NSURL* url = [[NSURL alloc] initWithString:urlStr];
	[[UIApplication sharedApplication] openURL:url];


}

@end
