//  Created by Michael Simms on 6/12/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

#import <WatchKit/WatchKit.h>
#import "ActivityPreferences.h"
#import "SensorMgr.h"

@interface ExtensionDelegate : NSObject <WKExtensionDelegate>
{
	SensorMgr* sensorMgr;
	ActivityPreferences* activityPrefs;

	BOOL badGps;

	time_t lastLocationUpdateTime;
	time_t lastHeartRateUpdateTime;
	time_t lastCadenceUpdateTime;
	time_t lastWheelSpeedUpdateTime;
	time_t lastPowerUpdateTime;
}

// sensor management methods

- (void)stopSensors;
- (void)startSensors;

// methods for starting and stopping activities, etc.

- (BOOL)startActivity;
- (BOOL)startActivityWithBikeName:(NSString*)bikeName;
- (BOOL)stopActivity;
- (BOOL)pauseActivity;
- (BOOL)startNewLap;

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
