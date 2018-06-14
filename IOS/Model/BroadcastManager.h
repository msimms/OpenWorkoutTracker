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
	NSMutableArray*            cache;
	time_t                     lastCacheFlush;
	NSString*                  deviceId;
	NSString*                  activityId;
	CLLocation*                lastBroadcastLoc;
}

@end
