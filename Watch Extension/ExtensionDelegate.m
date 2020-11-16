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

	self->currentActivityLock = [[NSLock alloc] init];
	self->databaseLock = [[NSLock alloc] init];

	if (!Initialize([dbFileName UTF8String]))
	{
		NSLog(@"Database not created.");
	}

	//
	// Sensor management object. Add the accelerometer and location sensors by default.
	//

	SensorFactory* sensorFactory = [[SensorFactory alloc] init];
	Accelerometer* accelerometerController = [sensorFactory createAccelerometer];
	LocationSensor* locationController = [sensorFactory createLocationSensor];

	self->sensorMgr = [SensorMgr sharedInstance];
	[self->sensorMgr addSensor:accelerometerController];
	[self->sensorMgr addSensor:locationController];

	[self startHealthMgr];
	[self startWatchSession]; // handles watch to phone interactions

	self->activityPrefs = [[ActivityPreferences alloc] initWithBT:TRUE];
	self->badGps = FALSE;
	self->receivingLocations = FALSE;
	self->hasConnectivity = FALSE;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accelerometerUpdated:) name:@NOTIFICATION_NAME_ACCELEROMETER object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:@NOTIFICATION_NAME_LOCATION object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(heartRateUpdated:) name:@NOTIFICATION_NAME_HRM object:nil];
}

- (void)applicationDidBecomeActive
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application
	// was previously in the background, optionally refresh the user interface.
	[self testNetworkConnectivity];
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

	if ([self isActivityCreated])
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

	[self->currentActivityLock lock];

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

	[self->currentActivityLock unlock];
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

#pragma mark network monitoring methods

- (BOOL)hasConnectivity
{
	return self->hasConnectivity;
}

- (void)testNetworkConnectivity
{
	NSString* protocolStr = [Preferences broadcastProtocol];
	NSString* hostName = [Preferences broadcastHostName];
	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/status", protocolStr, hostName];

	NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
	request.timeoutInterval = 30.0;
	request.allowsExpensiveNetworkAccess = TRUE;
	[request setURL:[NSURL URLWithString:urlStr]];
	[request setHTTPMethod:@"GET"];

	NSURLSession* session = [NSURLSession sharedSession];
	NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request
												completionHandler:^(NSData* data, NSURLResponse* response, NSError* error)
	{
		NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
		self->hasConnectivity = ([httpResponse statusCode] == 200);
	}];
	[dataTask resume];
}

#pragma mark watch session methods

- (void)startWatchSession
{
	self->watchSession = [[WatchSessionManager alloc] init];
	if (self->watchSession)
	{
		[self->watchSession startWatchSession];
	}
}

#pragma mark healthkit methods

- (void)startHealthMgr
{
	self->healthMgr = [[WatchHealthManager alloc] init];
	if (self->healthMgr)
	{
		[self->healthMgr requestAuthorization];
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
	[self->currentActivityLock lock];

	if (self->sensorMgr)
	{
		GetUsableSensorTypes(startSensorCallback, (__bridge void*)self->sensorMgr);
	}

	[self->currentActivityLock unlock];
}

#pragma mark methods for starting and stopping activities, etc.

- (BOOL)startActivity
{
	BOOL result = FALSE;

	// Generate a unique identifier for the activity.
	NSString* activityId = [[NSUUID UUID] UUIDString];

	// Create the backend data structures for the activity.
	[self->currentActivityLock lock];
	result = StartActivity([activityId UTF8String]);
	[self->currentActivityLock unlock];

	if (result)
	{
		ActivityAttributeType startTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_START_TIME);
		NSString* activityType = [self getCurrentActivityType];		
		NSDictionary* startData = [[NSDictionary alloc] initWithObjectsAndKeys:
								   activityId, @KEY_NAME_ACTIVITY_ID,
								   activityType, @KEY_NAME_ACTIVITY_TYPE,
								   [NSNumber numberWithLongLong:startTime.value.intVal], @KEY_NAME_START_TIME,
								   nil];

		// Start the activity in HealthKit.
		[self->healthMgr startWorkout:activityType withStartTime:[[NSDate alloc] initWithTimeIntervalSince1970:startTime.value.intVal]];

		// Let the others know.
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
	BOOL result = FALSE;

	[self->currentActivityLock lock];
	result = StopCurrentActivity();
	[self->currentActivityLock unlock];

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
			[self->currentActivityLock lock];
			SaveActivitySummaryData();
			[self->currentActivityLock unlock];
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

		// Start the activity in HealthKit.
		[self->healthMgr stopWorkout:[[NSDate alloc] initWithTimeIntervalSince1970:endTime.value.intVal]];

		// Let the others know.
		[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_ACTIVITY_STOPPED object:stopData];
	}
	return result;
}

- (BOOL)pauseActivity
{
	[self->currentActivityLock lock];
	BOOL paused = PauseCurrentActivity();
	[self->currentActivityLock unlock];
	return paused;
}

- (BOOL)startNewLap
{
	[self->currentActivityLock lock];
	BOOL started = StartNewLap();
	[self->currentActivityLock unlock];
	return started;
}

- (ActivityAttributeType)queryLiveActivityAttribute:(NSString*)attributeName
{
	return QueryLiveActivityAttribute([attributeName UTF8String]);
}

#pragma mark methods for creating and destroying the current activity.

- (void)createActivity:(NSString*)activityType
{
	[self->currentActivityLock lock];
	CreateActivityObject([activityType cStringUsingEncoding:NSASCIIStringEncoding]);
	[self->currentActivityLock unlock];
}

- (void)recreateOrphanedActivity:(NSInteger)activityIndex
{
	[self->currentActivityLock lock];
	DestroyCurrentActivity();
	ReCreateOrphanedActivity(activityIndex);
	[self->currentActivityLock unlock];
}

- (void)endOrpanedActivity:(NSInteger)activityIndex
{
	[self->databaseLock lock];
	FixHistoricalActivityEndTime(activityIndex);
	[self->databaseLock unlock];
}

#pragma mark methods for querying the status of the current activity.

- (BOOL)isActivityCreated
{
	[self->currentActivityLock lock];
	BOOL created = IsActivityCreated();
	[self->currentActivityLock unlock];
	return created;
}

- (BOOL)isActivityInProgress
{
	[self->currentActivityLock lock];
	BOOL inProgress = IsActivityInProgress();
	[self->currentActivityLock unlock];
	return inProgress;
}

- (BOOL)isActivityOrphaned:(size_t*)activityIndex
{
	BOOL isOrphaned = FALSE;

	[self->databaseLock lock];

	if (HistoricalActivityListIsInitialized())
	{
		isOrphaned = IsActivityOrphaned(activityIndex);
	}

	[self->databaseLock unlock];

	return isOrphaned;
}

#pragma mark methods for loading and editing historical activities

- (NSInteger)initializeHistoricalActivityList
{
	[self->databaseLock lock];
	InitializeHistoricalActivityList();
	NSInteger numActivities = (NSInteger)GetNumHistoricalActivities();
	[self->databaseLock unlock];
	return numActivities;
}

- (NSInteger)getNumHistoricalActivities
{
	[self->databaseLock lock];
	NSInteger numActivities = (NSInteger)GetNumHistoricalActivities();
	[self->databaseLock unlock];
	return numActivities;
}

- (void)createHistoricalActivityObject:(NSInteger)activityIndex
{
	[self->databaseLock lock];
	CreateHistoricalActivityObject(activityIndex);
	[self->databaseLock unlock];
}

- (void)loadHistoricalActivitySummaryData:(NSInteger)activityIndex
{
	[self->databaseLock lock];
	LoadHistoricalActivitySummaryData(activityIndex);
	[self->databaseLock unlock];
}

- (void)getHistoricalActivityStartAndEndTime:(NSInteger)activityIndex withStartTime:(time_t*)startTime withEndTime:(time_t*)endTime
{
	[self->databaseLock lock];
	GetHistoricalActivityStartAndEndTime((size_t)activityIndex, startTime, endTime);
	[self->databaseLock unlock];
}

- (ActivityAttributeType)queryHistoricalActivityAttribute:(const char* const)attributeName forActivityIndex:(NSInteger)activityIndex
{
	[self->databaseLock lock];
	ActivityAttributeType attr = QueryHistoricalActivityAttribute((size_t)activityIndex, attributeName);
	[self->databaseLock unlock];
	return attr;
}

- (ActivityAttributeType)queryHistoricalActivityAttribute:(const char* const)attributeName forActivityId:(NSString*)activityId
{
	[self->databaseLock lock];
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);
	ActivityAttributeType attr = QueryHistoricalActivityAttribute(activityIndex, attributeName);
	[self->databaseLock unlock];
	return attr;
}

void HistoricalActivityLocationLoadCallback(Coordinate coordinate, void* context)
{
	NSMutableArray* locationData = (__bridge NSMutableArray*)context;
	NSArray* locations = @[[NSNumber numberWithFloat:coordinate.latitude], [NSNumber numberWithFloat:coordinate.longitude], [NSNumber numberWithFloat:coordinate.altitude], [NSNumber numberWithFloat:coordinate.horizontalAccuracy], [NSNumber numberWithFloat:coordinate.verticalAccuracy], [NSNumber numberWithFloat:coordinate.time]];
	[locationData addObject:locations];
}

- (NSArray*)getHistoricalActivityLocationData:(NSString*)activityId
{
	NSMutableArray* locationData = [[NSMutableArray alloc] init];

	[self->databaseLock lock];
	LoadHistoricalActivityPoints([activityId UTF8String], HistoricalActivityLocationLoadCallback, (__bridge void*)locationData);
	[self->databaseLock unlock];

	return locationData;
}

- (NSInteger)getActivityIndexFromActivityId:(NSString*)activityId
{
	[self->databaseLock lock];
	NSInteger index = ConvertActivityIdToActivityIndex([activityId UTF8String]);
	[self->databaseLock unlock];
	return index;
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
#if OMIT_BROADCAST
			return FALSE;
#else
			return TRUE;
#endif
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
		if ([Preferences shouldBroadcastToServer])
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
		[self->databaseLock lock];
		StoreHash([activityId UTF8String], [hashStr UTF8String]);
		[self->databaseLock unlock];
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
		[self->databaseLock lock];
		StoreHash([activityId UTF8String], [hashStr UTF8String]);
		[self->databaseLock unlock];
	}
	return hashStr;
}

- (NSString*)retrieveHashForActivityId:(NSString*)activityId
{
	NSString* result = nil;
	char* activityHash = NULL;
	
	[self->databaseLock lock];
	activityHash = GetHashForActivityId([activityId UTF8String]);
	[self->databaseLock unlock];

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
	char* activityId = NULL;

	[self->databaseLock lock];
	activityId = GetActivityIdByHash([activityHash UTF8String]);
	[self->databaseLock unlock];

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
	char* activityName = NULL;

	[self->databaseLock lock];
	activityName = GetActivityName([activityId UTF8String]);
	[self->databaseLock unlock];

	if (activityName)
	{
		result = [NSString stringWithFormat:@"%s", activityName];
		free((void*)activityName);
	}

	return result;
}

#pragma mark sensor update methods

- (void)accelerometerUpdated:(NSNotification*)notification
{
	[self->currentActivityLock lock];

	if (IsActivityInProgress() && IsLiftingActivity())
	{
		NSDictionary* accelerometerData = [notification object];
		
		NSNumber* x = [accelerometerData objectForKey:@KEY_NAME_ACCEL_X];
		NSNumber* y = [accelerometerData objectForKey:@KEY_NAME_ACCEL_Y];
		NSNumber* z = [accelerometerData objectForKey:@KEY_NAME_ACCEL_Z];
		NSNumber* timestampMs = [accelerometerData objectForKey:@KEY_NAME_ACCELEROMETER_TIMESTAMP_MS];
		
		ProcessAccelerometerReading([x doubleValue], [y doubleValue], [z doubleValue], [timestampMs longLongValue]);
	}

	[self->currentActivityLock unlock];
}

- (void)locationUpdated:(NSNotification*)notification
{
	self->receivingLocations = TRUE;

	[self->currentActivityLock lock];

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

	[self->currentActivityLock unlock];
}

- (void)heartRateUpdated:(NSNotification*)notification
{
	[self->currentActivityLock lock];

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

	[self->currentActivityLock unlock];
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
	GetActivityTypes(activityTypeCallback, (__bridge void*)types);
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

	[self->currentActivityLock lock];
	GetActivityAttributeNames(attributeNameCallback, (__bridge void*)names);
	[self->currentActivityLock unlock];

	return names;
}

- (NSMutableArray*)getHistoricalActivityAttributes:(NSInteger)activityIndex
{
	NSMutableArray* attributes = [[NSMutableArray alloc] init];

	[self->databaseLock lock];

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

	[self->databaseLock unlock];

	return attributes;
}

- (NSMutableArray*)getIntervalWorkoutNamesAndIds
{
	NSMutableArray* namesAndIds = [[NSMutableArray alloc] init];

	if (InitializeIntervalWorkoutList())
	{
		size_t index = 0;
		char* workoutJson = NULL;

		while ((workoutJson = RetrieveIntervalWorkoutAsJSON(index)) != NULL)
		{
			NSString* jsonString = [[NSString alloc] initWithUTF8String:workoutJson];
			NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
			NSDictionary* jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];

			[namesAndIds addObject:jsonObject];
			free((void*)workoutJson);
			++index;
		}
	}
	return namesAndIds;
}

- (NSMutableArray*)getPacePlanNamesAndIds
{
	NSMutableArray* namesAndIds = [[NSMutableArray alloc] init];

	if (InitializePacePlanList())
	{
		size_t index = 0;
		char* pacePlanJson = NULL;

		while ((pacePlanJson = RetrievePacePlanAsJSON(index)) != NULL)
		{
			NSString* jsonString = [[NSString alloc] initWithUTF8String:pacePlanJson];
			NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
			NSDictionary* jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];

			[namesAndIds addObject:jsonObject];
			free((void*)pacePlanJson);
			++index;
		}
	}
	return namesAndIds;
}

- (NSString*)getCurrentActivityType
{
	NSString* activityTypeStr = nil;
	char* activityType = NULL;

	[self->databaseLock lock];
	activityType = GetCurrentActivityType();
	[self->databaseLock unlock];

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
	char* activityType = NULL;
	
	[self->databaseLock lock];
	activityType = GetHistoricalActivityType((size_t)activityIndex);
	[self->databaseLock unlock];

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
	char* activityName = NULL;

	[self->databaseLock lock];
	activityName = GetHistoricalActivityName((size_t)activityIndex);
	[self->databaseLock unlock];

	if (activityName)
	{
		result = [NSString stringWithFormat:@"%s", activityName];
		free((void*)activityName);
	}
	return result;
}

#pragma mark

- (void)createPacePlan:(NSString*)planId withPlanName:(NSString*)planName withTargetPaceMinKm:(double)targetPaceMinKm withTargetDistanceKms:(double)targetDistanceKms withSplits:(double)splits withRoute:(NSString*)route
{
	[self->databaseLock lock];

	if (InitializePacePlanList())
	{
		if (!GetPacePlanDetails([planId UTF8String], NULL, NULL, NULL, NULL))
		{
			CreateNewPacePlan([planName UTF8String], [planId UTF8String]);
		}
		UpdatePacePlanDetails([planId UTF8String], [planName UTF8String], targetPaceMinKm, targetDistanceKms, splits);
	}

	[self->databaseLock unlock];
}

#pragma mark reset methods

- (void)resetDatabase
{
	[self->currentActivityLock lock];
	[self->databaseLock lock];

	ResetDatabase();

	[self->databaseLock unlock];
	[self->currentActivityLock unlock];
}

@end
