// Created by Michael Simms on 2/11/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import "DataCloud.h"

typedef enum RunKeeperActivityType
{
    RUNKEEPER_RUNNING,
    RUNKEEPER_CYCLING,
    RUNKEEPER_MOUNTAIN_BIKING,
    RUNKEEPER_WALKING,
    RUNKEEPER_HIKING,
    RUNKEEPER_DOWNHILL_SKIING,
    RUNKEEPER_CROSS_COUNTRY_SKIING,
    RUNKEEPER_SNOWBOARDING,
    RUNKEEPER_SKATING,
    RUNKEEPER_SWIMMING,
    RUNKEEPER_WHEELCHAR,
    RUNKEEPER_ROWING,
    RUNKEEPER_ELLIPTICAL,
    RUNKEEPER_OTHER
} RunKeeperActivityType;

@interface RunKeeper : DataCloud
{
}

- (NSString*)name;

- (id)init;
- (BOOL)isLinked;
- (BOOL)uploadActivity:(NSString*)activityId;

@end
