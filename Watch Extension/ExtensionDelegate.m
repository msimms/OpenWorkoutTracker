//  Created by Michael Simms on 6/12/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "ExtensionDelegate.h"
#import "ActivityAttribute.h"
#import "ActivityHash.h"
#import "ActivityMgr.h"
#import "Notifications.h"
#import "Preferences.h"
#import "SensorFactory.h"

#define DATABASE_NAME "Activities.sqlite"

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching
{
	NSArray*  paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* docDir = [paths objectAtIndex: 0];
	NSString* dbFileName = [docDir stringByAppendingPathComponent:@DATABASE_NAME];

	Initialize([dbFileName UTF8String]);

	SensorFactory* sensorFactory = [[SensorFactory alloc] init];
	Accelerometer* accelerometerController = [sensorFactory createAccelerometer];
	LocationSensor* locationController = [sensorFactory createLocationSensor];

	self->sensorMgr = [SensorMgr sharedInstance];
	if (self->sensorMgr)
	{
		[self->sensorMgr addSensor:accelerometerController];
		[self->sensorMgr addSensor:locationController];
	}

	[self startHealthMgr];
	[self startWatchSession];

	self->activityPrefs = [[ActivityPreferences alloc] initWithBT:TRUE];
	self->badGps = FALSE;
	self->receivingLocations = FALSE;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accelerometerUpdated:) name:@NOTIFICATION_NAME_ACCELEROMETER object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:@NOTIFICATION_NAME_LOCATION object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(heartRateUpdated:) name:@NOTIFICATION_NAME_HRM object:nil];
}

- (void)applicationDidBecomeActive
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application
	// was previously in the background, optionally refresh the user interface.
	[self configureBroadcasting];
}

- (void)applicationWillResignActive
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of
	// temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application
	// and it begins the transition to the background state. Use this method to pause ongoing tasks, disable timers, etc.
}

- (void)applicationWillEnterForeground
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of
	// the changes made on entering the background.
	if (IsActivityCreated())
	{
		[self startSensors];
	}

	if (self->sensorMgr)
	{
		[self->sensorMgr enteredForeground];
	}
}

- (void)applicationDidEnterBackground
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application
	// state information to restore your application to its current state in case it is terminated later. If your
	// application supports background execution, this method is called instead of applicationWillTerminate when the user quits.
	if (IsActivityInProgress() || IsAutoStartEnabled())
	{
		if (self->sensorMgr)
		{
			[self->sensorMgr enteredBackground];
		}
	}
	else
	{
		[self stopSensors];
	}
}

- (void)handleBackgroundTasks:(NSSet<WKRefreshBackgroundTask *> *)backgroundTasks
{
	// Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
	for (WKRefreshBackgroundTask* task in backgroundTasks)
	{
		// Check the Class of each task to decide how to process it
		if ([task isKindOfClass:[WKApplicationRefreshBackgroundTask class]])
		{
			// Be sure to complete the background task once you’re done.
			WKApplicationRefreshBackgroundTask *backgroundTask = (WKApplicationRefreshBackgroundTask*)task;
			[backgroundTask setTaskCompletedWithSnapshot:NO];
		}
		else if ([task isKindOfClass:[WKSnapshotRefreshBackgroundTask class]])
		{
			// Snapshot tasks have a unique completion call, make sure to set your expiration date
			WKSnapshotRefreshBackgroundTask *snapshotTask = (WKSnapshotRefreshBackgroundTask*)task;
			[snapshotTask setTaskCompletedWithDefaultStateRestored:YES estimatedSnapshotExpiration:[NSDate distantFuture] userInfo:nil];
		}
		else if ([task isKindOfClass:[WKWatchConnectivityRefreshBackgroundTask class]])
		{
			// Be sure to complete the background task once you’re done.
			WKWatchConnectivityRefreshBackgroundTask *backgroundTask = (WKWatchConnectivityRefreshBackgroundTask*)task;
			[backgroundTask setTaskCompletedWithSnapshot:NO];
		}
		else if ([task isKindOfClass:[WKURLSessionRefreshBackgroundTask class]])
		{
			// Be sure to complete the background task once you’re done.
			WKURLSessionRefreshBackgroundTask *backgroundTask = (WKURLSessionRefreshBackgroundTask*)task;
			[backgroundTask setTaskCompletedWithSnapshot:NO];
		}
/*		else if ([task isKindOfClass:[WKRelevantShortcutRefreshBackgroundTask class]])
		{
			// Be sure to complete the relevant-shortcut task once you’re done.
			WKRelevantShortcutRefreshBackgroundTask *relevantShortcutTask = (WKRelevantShortcutRefreshBackgroundTask*)task;
			[relevantShortcutTask setTaskCompletedWithSnapshot:NO];
		}
		else if ([task isKindOfClass:[WKIntentDidRunRefreshBackgroundTask class]])
		{
			// Be sure to complete the intent-did-run task once you’re done.
			WKIntentDidRunRefreshBackgroundTask *intentDidRunTask = (WKIntentDidRunRefreshBackgroundTask*)task;
			[intentDidRunTask setTaskCompletedWithSnapshot:NO];
		} */
		else
		{
			// make sure to complete unhandled task types
			[task setTaskCompletedWithSnapshot:NO];
		}
	}
}

#pragma mark watch session methods

- (void)startWatchSession
{
	self->watchSession = [[WatchSessionManager alloc] init];
	[self->watchSession startWatchSession];
}

#pragma mark healthkit methods

- (void)startHealthMgr
{
	self->healthMgr = [[HealthManager alloc] init];
	if (self->healthMgr)
	{
		[self->healthMgr requestAuthorization];
		[self->healthMgr subscribeToHeartRateUpdates];
	}
}

#pragma mark sensor methods

- (void)stopSensors
{
	if (self->sensorMgr)
	{
		[self->sensorMgr stopSensors];
	}
}

void startSensorCallback(SensorType type, void* context)
{
	SensorMgr* mgr = (__bridge SensorMgr*)context;
	[mgr startSensor:type];
}

- (void)startSensors
{
	if (self->sensorMgr)
	{
		GetUsableSensorTypes(startSensorCallback, (__bridge void*)self->sensorMgr);
	}
}

#pragma mark methods for starting and stopping activities, etc.

- (BOOL)startActivity
{
	NSString* activityId = [[NSUUID UUID] UUIDString];
	BOOL result = StartActivity([activityId UTF8String]);
	if (result)
	{
		ActivityAttributeType startTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_START_TIME);

		NSString* activityType = [self getCurrentActivityType];
		NSString* activityId = [[NSString alloc] initWithFormat:@"%s", GetCurrentActivityId()];
		
		NSDictionary* startData = [[NSDictionary alloc] initWithObjectsAndKeys:
								   activityId, @KEY_NAME_ACTIVITY_ID,
								   activityType, @KEY_NAME_ACTIVITY_TYPE,
								   [NSNumber numberWithLongLong:startTime.value.intVal], @KEY_NAME_START_TIME,
								   nil];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_ACTIVITY_STARTED object:startData];
	}
	return result;
}

- (BOOL)startActivityWithBikeName:(NSString*)bikeName
{
	BOOL result = [self startActivity];
	if (result)
	{
		SetCurrentBicycle([bikeName UTF8String]);
	}
	return result;
}

- (BOOL)stopActivity
{
	BOOL result = StopCurrentActivity();
	if (result)
	{		
		ActivityAttributeType startTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_START_TIME);
		ActivityAttributeType endTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_END_TIME);
		ActivityAttributeType distance = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED);
		ActivityAttributeType calories = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_CALORIES_BURNED);

		NSString* activityType = [self getCurrentActivityType];
		NSString* activityId = [[NSString alloc] initWithFormat:@"%s", GetCurrentActivityId()];
		NSString* activityHash = [self hashCurrentActivity];

		dispatch_queue_t summarizerQueue = dispatch_queue_create("summarizer", NULL);
		dispatch_async(summarizerQueue, ^{
			@synchronized(self) {
				SaveActivitySummaryData();
			}
		});

		NSDictionary* stopData = [[NSDictionary alloc] initWithObjectsAndKeys:
								  activityId, @KEY_NAME_ACTIVITY_ID,
								  activityType, @KEY_NAME_ACTIVITY_TYPE,
								  activityHash, @KEY_NAME_ACTIVITY_HASH,
								  [NSNumber numberWithLongLong:startTime.value.intVal], @KEY_NAME_START_TIME,
								  [NSNumber numberWithLongLong:endTime.value.intVal], @KEY_NAME_END_TIME,
								  [NSNumber numberWithDouble:distance.value.doubleVal], @KEY_NAME_DISTANCE,
								  [NSNumber numberWithDouble:calories.value.doubleVal], @KEY_NAME_CALORIES,
								  nil];

		[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_ACTIVITY_STOPPED object:stopData];
	}
	return result;
}

- (BOOL)pauseActivity
{
	return PauseCurrentActivity();
}

- (BOOL)startNewLap
{
	return StartNewLap();
}

- (ActivityAttributeType)queryLiveActivityAttribute:(NSString*)attributeName
{
	return QueryLiveActivityAttribute([attributeName UTF8String]);
}

#pragma mark methods for creating and destroying the current activity.

- (void)createActivity:(NSString*)activityType
{
	CreateActivity([activityType cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)recreateOrphanedActivity:(NSInteger)activityIndex
{
	DestroyCurrentActivity();
	ReCreateOrphanedActivity(activityIndex);
}

- (void)endOrpanedActivity:(NSInteger)activityIndex
{
	FixHistoricalActivityEndTime(activityIndex);
}

#pragma mark methods for querying the status of the current activity.

- (BOOL)isActivityCreated
{
	return IsActivityCreated();
}

- (BOOL)isActivityInProgress
{
	return IsActivityInProgress();
}

- (BOOL)isActivityOrphaned:(size_t*)activityIndex
{
	return IsActivityOrphaned(activityIndex);
}

#pragma mark methods for loading and editing historical activities

- (NSInteger)initializeHistoricalActivityList
{
	InitializeHistoricalActivityList();
	return [self getNumHistoricalActivities];
}

- (NSInteger)getNumHistoricalActivities
{
	// The number of activities from out database.
	return (NSInteger)GetNumHistoricalActivities();
}

- (void)createHistoricalActivityObject:(NSInteger)activityIndex
{
	CreateHistoricalActivityObject(activityIndex);
}

- (void)loadHistoricalActivitySummaryData:(NSInteger)activityIndex
{
	@synchronized(self) {
		LoadHistoricalActivitySummaryData(activityIndex);
	}
}

- (void)getHistoricalActivityStartAndEndTime:(NSInteger)activityIndex withStartTime:(time_t*)startTime withEndTime:(time_t*)endTime
{
	GetHistoricalActivityStartAndEndTime((size_t)activityIndex, startTime, endTime);
}

- (ActivityAttributeType)queryHistoricalActivityAttribute:(const char* const)attributeName forActivityIndex:(NSInteger)activityIndex
{
	return QueryHistoricalActivityAttribute((size_t)activityIndex, attributeName);
}

- (ActivityAttributeType)queryHistoricalActivityAttribute:(const char* const)attributeName forActivityId:(NSString*)activityId
{
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);
	return QueryHistoricalActivityAttribute(activityIndex, attributeName);
}

- (NSArray*)getHistoricalActivityLocationData:(NSString*)activityId
{
	NSMutableArray* locationData = [[NSMutableArray alloc] init];
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	InitializeHistoricalActivityList();
	CreateHistoricalActivityObject(activityIndex);

	if (LoadHistoricalActivitySensorData(activityIndex, SENSOR_TYPE_LOCATION, NULL, NULL))
	{
		NSInteger pointIndex = 0;
		BOOL result = FALSE;

		do {
			Coordinate coordinate;

			result = GetHistoricalActivityPoint(activityIndex, pointIndex, &coordinate);
			if (result)
			{
				CLLocation* location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
				[locationData addObject:location];
				++pointIndex;
			}
		} while (result);
	}
	return locationData;
}

#pragma mark retrieves or creates and retrieves the applications unique identifier

- (NSString*)getDeviceId;
{
	NSString* uuid = [Preferences uuid];
	if ((uuid == nil) || ([uuid length] == 0))
	{
		uuid = [[NSUUID UUID] UUIDString];
		[Preferences setUuid:uuid];
	}
	return uuid;
}

#pragma mark controller methods for this application

- (BOOL)isFeaturePresent:(Feature)feature
{
	switch (feature)
	{
		case FEATURE_BROADCAST:
			return TRUE;
		case FEATURE_WORKOUT_PLAN_GENERATION:
			return FALSE;
		case FEATURE_DROPBOX:
			return FALSE;
		case FEATURE_STRAVA:
			return FALSE;
		case FEATURE_RUNKEEPER:
			return FALSE;
	}
	return TRUE;
}

#pragma mark broadcast methods

- (void)configureBroadcasting
{
#if !OMIT_BROADCAST
	if ([self isFeaturePresent:FEATURE_BROADCAST])
	{
		if ([Preferences shouldBroadcastGlobally])
		{
			if (!self->broadcastMgr)
			{
				self->broadcastMgr = [[BroadcastManager alloc] init];
				[self->broadcastMgr setDeviceId:[self getDeviceId]];
			}
		}
		else
		{
			self->broadcastMgr = nil;
		}
	}
	else
	{
		self->broadcastMgr = nil;
	}
#endif
}

#pragma mark hash methods

- (NSString*)hashActivityWithId:(NSString*)activityId
{
	ActivityHash* hash = [[ActivityHash alloc] init];
	NSString* hashStr = [hash calculateWithActivityId:activityId];

	if (hashStr)
	{
		StoreHash([activityId UTF8String], [hashStr UTF8String]);
	}
	return hashStr;
}

- (NSString*)hashCurrentActivity
{
	ActivityHash* hash = [[ActivityHash alloc] init];
	NSString* activityId = [[NSString alloc] initWithFormat:@"%s", GetCurrentActivityId()];
	NSString* hashStr = [hash calculateWithActivityId:activityId];

	if (hashStr)
	{
		StoreHash([activityId UTF8String], [hashStr UTF8String]);
	}
	return hashStr;
}

- (NSString*)retrieveHashForActivityId:(NSString*)activityId
{
	NSString* result = nil;
	char* activityHash = GetHashForActivityId([activityId UTF8String]);

	if (activityHash)
	{
		result = [NSString stringWithFormat:@"%s", activityHash];
		free((void*)activityHash);
	}
	return result;
}

- (NSString*)retrieveHashForActivityIndex:(NSInteger)activityIndex
{
	const char* const activityId = ConvertActivityIndexToActivityId(activityIndex);

	if (activityId)
	{
		NSString* tempActivityId = [[NSString alloc] initWithFormat:@"%s", activityId];
		return [self retrieveHashForActivityId:tempActivityId];
	}
	return NULL;
}

- (NSString*)retrieveActivityIdByHash:(NSString*)activityHash
{
	NSString* result = nil;
	char* activityId = GetActivityIdByHash([activityHash UTF8String]);

	if (activityId)
	{
		result = [NSString stringWithFormat:@"%s", activityId];
		free((void*)activityId);
	}
	return result;
}

#pragma mark methods for managing the activity name

- (NSString*)getActivityName:(NSString*)activityId
{
	NSString* result = nil;
	char* activityName = GetActivityName([activityId UTF8String]);

	if (activityName)
	{
		result = [NSString stringWithFormat:@"%s", activityName];
		free((void*)activityName);
	}
	return result;
}

#pragma mark sensor update methods

- (void)weightHistoryUpdated:(NSNotification*)notification
{
	NSDictionary* weightData = [notification object];
	
	NSNumber* weightKg = [weightData objectForKey:@KEY_NAME_WEIGHT_KG];
	NSNumber* time = [weightData objectForKey:@KEY_NAME_TIME];
	
	ProcessWeightReading([weightKg doubleValue], (time_t)[time unsignedLongLongValue]);
}

- (void)accelerometerUpdated:(NSNotification*)notification
{
	if (IsActivityInProgress() && IsLiftingActivity())
	{
		NSDictionary* accelerometerData = [notification object];
		
		NSNumber* x = [accelerometerData objectForKey:@KEY_NAME_ACCEL_X];
		NSNumber* y = [accelerometerData objectForKey:@KEY_NAME_ACCEL_Y];
		NSNumber* z = [accelerometerData objectForKey:@KEY_NAME_ACCEL_Z];
		NSNumber* timestampMs = [accelerometerData objectForKey:@KEY_NAME_ACCELEROMETER_TIMESTAMP_MS];
		
		ProcessAccelerometerReading([x doubleValue], [y doubleValue], [z doubleValue], [timestampMs longLongValue]);
	}
}

- (void)locationUpdated:(NSNotification*)notification
{
	self->receivingLocations = TRUE;

	if (IsActivityInProgressAndNotPaused())
	{
		NSDictionary* locationData = [notification object];

		NSNumber* lat = [locationData objectForKey:@KEY_NAME_LATITUDE];
		NSNumber* lon = [locationData objectForKey:@KEY_NAME_LONGITUDE];
		NSNumber* alt = [locationData objectForKey:@KEY_NAME_ALTITUDE];

		NSNumber* horizontalAccuracy = [locationData objectForKey:@KEY_NAME_HORIZONTAL_ACCURACY];
		NSNumber* verticalAccuracy = [locationData objectForKey:@KEY_NAME_VERTICAL_ACCURACY];

		NSNumber* gpsTimestampMs = [locationData objectForKey:@KEY_NAME_GPS_TIMESTAMP_MS];

		NSString* activityType = [self getCurrentActivityType];

		BOOL tempBadGps = FALSE;

		uint8_t minHAccuracy = [self->activityPrefs getMinGpsHorizontalAccuracy:activityType];
		if (minHAccuracy != (uint8_t)-1)
		{
			uint8_t accuracy = [[locationData objectForKey:@KEY_NAME_HORIZONTAL_ACCURACY] intValue];
			if (minHAccuracy != 0 && accuracy > minHAccuracy)
			{
				tempBadGps = TRUE;
			}
		}
		
		uint8_t minVAccuracy = [self->activityPrefs getMinGpsVerticalAccuracy:activityType];
		if (minVAccuracy != (uint8_t)-1)
		{
			uint8_t accuracy = [[locationData objectForKey:@KEY_NAME_VERTICAL_ACCURACY] intValue];
			if (minVAccuracy != 0 && accuracy > minVAccuracy)
			{
				tempBadGps = TRUE;
			}
		}

		self->badGps = tempBadGps;

		BOOL shouldProcessReading = TRUE;
		GpsFilterOption filterOption = [self->activityPrefs getGpsFilterOption:activityType];
		
		if (filterOption == GPS_FILTER_DROP && self->badGps)
		{
			shouldProcessReading = FALSE;
		}
		
		if (shouldProcessReading)
		{
			ProcessLocationReading([lat doubleValue], [lon doubleValue], [alt doubleValue], [horizontalAccuracy doubleValue], [verticalAccuracy doubleValue], [gpsTimestampMs longLongValue]);
		}
	}
}

- (void)heartRateUpdated:(NSNotification*)notification
{
	if (IsActivityInProgressAndNotPaused())
	{
		NSDictionary* heartRateData = [notification object];

		NSNumber* timestampMs = [heartRateData objectForKey:@KEY_NAME_HRM_TIMESTAMP_MS];
		NSNumber* rate = [heartRateData objectForKey:@KEY_NAME_HEART_RATE];

		if (timestampMs && rate)
		{
			ProcessHrmReading([rate doubleValue], [timestampMs longLongValue]);
		}
	}
}

#pragma mark accessor methods

void activityTypeCallback(const char* type, void* context)
{
	NSMutableArray* types = (__bridge NSMutableArray*)context;
	[types addObject:[[NSString alloc] initWithUTF8String:type]];
}

- (NSMutableArray*)getActivityTypes
{
	NSMutableArray* types = [[NSMutableArray alloc] init];
	if (types)
	{
		GetActivityTypes(activityTypeCallback, (__bridge void*)types);
	}
	return types;
}

void attributeNameCallback(const char* name, void* context)
{
	NSMutableArray* names = (__bridge NSMutableArray*)context;
	[names addObject:[[NSString alloc] initWithUTF8String:name]];
}

- (NSMutableArray*)getCurrentActivityAttributes
{
	NSMutableArray* names = [[NSMutableArray alloc] init];
	if (names)
	{
		GetActivityAttributeNames(attributeNameCallback, (__bridge void*)names);
	}
	return names;
}

- (NSMutableArray*)getHistoricalActivityAttributes:(NSInteger)activityIndex
{
	NSMutableArray* attributes = [[NSMutableArray alloc] init];
	if (attributes)
	{
		size_t numAttributes = GetNumHistoricalActivityAttributes(activityIndex);
		for (size_t i = 0; i < numAttributes; ++i)
		{
			char* attrName = GetHistoricalActivityAttributeName(activityIndex, i);
			if (attrName)
			{
				NSString* attrTitle = [[NSString alloc] initWithFormat:@"%s", attrName];
				if (attrTitle)
				{
					[attributes addObject:attrTitle];
				}
				free((void*)attrName);
			}
		}
	}
	return attributes;
}

- (NSMutableArray*)getIntervalWorkoutNamesAndIds
{
	NSMutableArray* namesAndIds = [[NSMutableArray alloc] init];
	if (namesAndIds)
	{
		if (InitializeIntervalWorkoutList())
		{
			char* workoutId = NULL;
			char* workoutName = NULL;
			size_t index = 0;

			while (((workoutName = GetIntervalWorkoutName(index)) != NULL) && ((workoutId = GetIntervalWorkoutId(index)) != NULL))
			{
				NSMutableDictionary* mutDic = [[NSMutableDictionary alloc] initWithCapacity:2];
				[mutDic setValue:[[NSString alloc] initWithUTF8String:workoutId] forKey:@"id"];
				[mutDic setValue:[[NSString alloc] initWithUTF8String:workoutName] forKey:@"name"];
				[namesAndIds addObject:mutDic];
				free((void*)workoutId);
				free((void*)workoutName);
				++index;
			}
		}
	}
	return namesAndIds;
}

- (NSMutableArray*)getPacePlanNamesAndIds
{
	NSMutableArray* namesAndIds = [[NSMutableArray alloc] init];
	if (namesAndIds)
	{
		if (InitializePacePlanList())
		{
			char* pacePlanId = NULL;
			char* pacePlanName = NULL;
			size_t index = 0;

			while (((pacePlanName = GetPacePlanName(index)) != NULL) && ((pacePlanId = GetPacePlanId(index)) != NULL))
			{
				NSMutableDictionary* mutDic = [[NSMutableDictionary alloc] initWithCapacity:2];
				[mutDic setValue:[[NSString alloc] initWithUTF8String:pacePlanId] forKey:@"id"];
				[mutDic setValue:[[NSString alloc] initWithUTF8String:pacePlanName] forKey:@"name"];
				[namesAndIds addObject:mutDic];
				free((void*)pacePlanId);
				free((void*)pacePlanName);
				++index;
			}
		}
	}
	return namesAndIds;
}

- (NSString*)getCurrentActivityType
{
	NSString* activityTypeStr = nil;
	char* activityType = GetCurrentActivityType();
	if (activityType)
	{
		activityTypeStr = [NSString stringWithFormat:@"%s", activityType];
		free((void*)activityType);
	}
	return activityTypeStr;
}

- (NSString*)getHistoricalActivityType:(NSInteger)activityIndex
{
	NSString* result = nil;
	char* activityType = GetHistoricalActivityType((size_t)activityIndex);
	if (activityType)
	{
		result = [NSString stringWithFormat:@"%s", activityType];
		free((void*)activityType);
	}
	return result;
}

- (NSString*)getHistoricalActivityName:(NSInteger)activityIndex
{
	NSString* result = nil;
	char* activityName = GetHistoricalActivityName((size_t)activityIndex);
	if (activityName)
	{
		result = [NSString stringWithFormat:@"%s", activityName];
		free((void*)activityName);
	}
	return result;
}

#pragma mark reset methods

- (void)resetDatabase
{
	ResetDatabase();
}

@end
