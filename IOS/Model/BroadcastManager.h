// Created by Michael Simms on 4/8/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "BroadcastSessionContainer.h"

@interface BroadcastManager : NSObject<NSURLConnectionDelegate>
{
	BroadcastSessionContainer* session;
	NSMutableArray*            locationCache;
	NSMutableArray*            accelerometerCache;
	time_t                     lastCacheFlush;
	NSString*                  deviceId;
	NSURLConnection*           currentLocationConnection; // Only want to create one connection at a time.
	size_t                     numLocObjsBeingSent;       // Number of location objects being sent.
	size_t                     numAccelObjsBeingSent;     // Number of accelerometer objects being sent.
}

@end
