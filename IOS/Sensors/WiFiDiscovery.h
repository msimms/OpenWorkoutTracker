// Created by Michael Simms on 1/23/15.
// Copyright (c) 2015 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

#import "Discovery.h"

@interface WiFiDiscovery : NSObject <Discovery>
{
	NSMutableArray* discoveredSensors;
	NSMutableArray* discoveryDelegates;
	NSTimer*        scanTimer;
}

+ (id)sharedInstance;

- (void)addDelegate:(id<DiscoveryDelegate>)newDelegate;
- (void)removeDelegate:(id<DiscoveryDelegate>)oldDelegate;
- (void)refreshDelegates;

- (void)stopScanning;

@end
