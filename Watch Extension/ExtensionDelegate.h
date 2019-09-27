//  Created by Michael Simms on 6/12/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <WatchKit/WatchKit.h>
#import <WatchConnectivity/WatchConnectivity.h>
#import "ActivityPreferences.h"
#import "BroadcastManager.h"
#import "Feature.h"
#import "HealthManager.h"
#import "SensorMgr.h"
#import "WatchSessionManager.h"

@interface ExtensionDelegate : NSObject <WKExtensionDelegate>
{
	SensorMgr*           sensorMgr;
	ActivityPreferences* activityPrefs;
	WatchSessionManager* watchSession;
	BroadcastManager*    broadcastMgr;
	HealthManager*       healthMgr;

	BOOL badGps;
}

// watch sensor methods

- (void)startWatchSession;

// sensor management methods

- (void)stopSensors;
- (void)startSensors;

// methods for starting and stopping activities, etc.

- (BOOL)startActivity;
- (BOOL)startActivityWithBikeName:(NSString*)bikeName;
- (BOOL)stopActivity;
- (BOOL)pauseActivity;
- (BOOL)startNewLap;
- (BOOL)loadHistoricalActivity:(NSInteger)activityIndex;

// hash methods

- (NSString*)hashActivityWithId:(NSString*)activityId;
- (NSString*)hashCurrentActivity;

// methods for managing the activity name

- (NSString*)getActivityName:(NSString*)activityId;

// accessor methods

- (NSMutableArray*)getActivityTypes;
- (NSMutableArray*)getCurrentActivityAttributes;
- (NSString*)getCurrentActivityType;

@end
