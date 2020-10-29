// Created by Michael Simms on 4/8/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "Defines.h"

#if !OMIT_BROADCAST

@interface BroadcastManager : NSObject<NSURLConnectionDelegate>
{
	NSMutableArray* locationCache; // locations to be sent
	NSMutableArray* accelerometerCache; // accelerometer readings to be sent
	time_t          lastCacheFlush; // Unix time of the cache flush
	NSString*       deviceId; // Unique identifier for the device doing the sending
	NSMutableData*  dataBeingSent; // Formatted data to be sent
	BOOL            errorSending; // Whether or not the last send was successful
}

- (void)setDeviceId:(NSString*)deviceId;

@end

#endif
