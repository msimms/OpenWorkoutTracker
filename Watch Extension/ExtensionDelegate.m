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

	self->backendLock = [[NSLock alloc] init];

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
	self->lastHeartRateUpdate = 0;
	self->activityType = nil;

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

	[self->backendLock lock];

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

	[self->backendLock unlock];
}

- (void)handleBackgroundTasks:(NSSet<WKRefreshBackgroundTask *> *)backgroundTasks
{
	// Sent when the system needs to launch the application in the background to process tasks.
	// Tasks arrive in a set, so loop through and process each one.

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
	[self->backendLock lock];

	if (self->sensorMgr)
	{
		GetUsableSensorTypes(startSensorCallback, (__bridge void*)self->sensorMgr);
	}

	[self->backendLock unlock];
}

#pragma mark methods for starting and stopping activities, etc.

- (BOOL)startActivity
{
	BOOL result = FALSE;

	// Generate a unique identifier for the activity.
	NSString* activityId = [[NSUUID UUID] UUIDString];

	// Create the backend data structures for the activity.
	[self->backendLock lock];
	result = StartActivity([activityId UTF8String]);
	[self->backendLock unlock];

	if (result)
	{
		[self->backendLock lock];
		ActivityAttributeType startTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_START_TIME);
		[self->backendLock unlock];

		self->activityType = [self getCurrentActivityType];		

		NSDictionary* startData = [[NSDictionary alloc] initWithObjectsAndKeys:
								   activityId, @KEY_NAME_ACTIVITY_ID,
								   self->activityType, @KEY_NAME_ACTIVITY_TYPE,
								   [NSNumber numberWithLongLong:startTime.value.intVal], @KEY_NAME_START_TIME,
								   nil];

		// Start the activity in HealthKit.
		[self->healthMgr startWorkout:self->activityType withStartTime:[[NSDate alloc] initWithTimeIntervalSince1970:startTime.value.intVal]];

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

	[self->backendLock lock];
	result = StopCurrentActivity();
	[self->backendLock unlock];

	if (result)
	{
		[self->backendLock lock];
		ActivityAttributeType startTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_START_TIME);
		ActivityAttributeType endTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_END_TIME);
		ActivityAttributeType distance = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED);
		ActivityAttributeType calories = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_CALORIES_BURNED);
		[self->backendLock unlock];

		NSString* activityId = [[NSString alloc] initWithFormat:@"%s", GetCurrentActivityId()];
		NSString* activityHash = [self hashCurrentActivity];

		dispatch_queue_t summarizerQueue = dispatch_queue_create("summarizer", NULL);
		dispatch_async(summarizerQueue, ^{
			[self->backendLock lock];
			SaveActivitySummaryData();
			[self->backendLock unlock];
		});

		NSDictionary* stopData = [[NSDictionary alloc] initWithObjectsAndKeys:
								  activityId, @KEY_NAME_ACTIVITY_ID,
								  self->activityType, @KEY_NAME_ACTIVITY_TYPE,
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
		
		self->activityType = nil;
	}
	return result;
}

- (BOOL)pauseActivity
{
	[self->backendLock lock];
	BOOL paused = PauseCurrentActivity();
	[self->backendLock unlock];
	return paused;
}

- (BOOL)startNewLap
{
	[self->backendLock lock];
	BOOL started = StartNewLap();
	[self->backendLock unlock];
	return started;
}

- (ActivityAttributeType)queryLiveActivityAttribute:(NSString*)attributeName
{
	ActivityAttributeType attr;

	[self->backendLock lock];
	attr = QueryLiveActivityAttribute([attributeName UTF8String]);
	[self->backendLock unlock];

	return attr;
}

#pragma mark methods for creating and destroying the current activity.

- (void)createActivity:(NSString*)activityType
{
	[self->backendLock lock];
	CreateActivityObject([activityType cStringUsingEncoding:NSASCIIStringEncoding]);
	[self->backendLock unlock];
}

- (void)recreateOrphanedActivity:(NSInteger)activityIndex
{
	[self->backendLock lock];
	DestroyCurrentActivity();
	ReCreateOrphanedActivity(activityIndex);
	[self->backendLock unlock];
}

- (void)endOrpanedActivity:(NSInteger)activityIndex
{
	[self->backendLock lock];
	FixHistoricalActivityEndTime(activityIndex);
	[self->backendLock unlock];
}

#pragma mark methods for querying the status of the current activity.

- (BOOL)isActivityCreated
{
	BOOL created = FALSE;

	[self->backendLock lock];
	created = IsActivityCreated();
	[self->backendLock unlock];

	return created;
}

- (BOOL)isActivityInProgress
{
	BOOL inProgress = FALSE;

	[self->backendLock lock];
	inProgress = IsActivityInProgress();
	[self->backendLock unlock];

	return inProgress;
}

- (BOOL)isActivityInProgressAndNotPaused
{
	BOOL inProgress = FALSE;

	[self->backendLock lock];
	inProgress = IsActivityInProgressAndNotPaused();
	[self->backendLock unlock];

	return inProgress;
}

- (BOOL)isActivityInProgressAndNotPausedAndLiftingActivity
{
	BOOL inProgress = FALSE;

	[self->backendLock lock];
	inProgress = IsActivityInProgressAndNotPaused() && IsLiftingActivity();
	[self->backendLock unlock];

	return inProgress;
}

- (BOOL)isActivityPaused
{
	BOOL isPaused = FALSE;

	[self->backendLock lock];
	isPaused = IsActivityPaused();
	[self->backendLock unlock];

	return isPaused;
}

- (BOOL)isActivityOrphaned:(size_t*)activityIndex
{
	BOOL isOrphaned = FALSE;

	[self->backendLock lock];

	if (HistoricalActivityListIsInitialized())
	{
		isOrphaned = IsActivityOrphaned(activityIndex);
	}

	[self->backendLock unlock];

	return isOrphaned;
}

#pragma mark methods for loading and editing historical activities

- (NSInteger)initializeHistoricalActivityList
{
	NSInteger numActivities = 0;

	[self->backendLock lock];
	InitializeHistoricalActivityList();
	numActivities = (NSInteger)GetNumHistoricalActivities();
	[self->backendLock unlock];

	return numActivities;
}

- (NSInteger)getNumHistoricalActivities
{
	NSInteger numActivities = 0;

	[self->backendLock lock];
	numActivities = (NSInteger)GetNumHistoricalActivities();
	[self->backendLock unlock];

	return numActivities;
}

- (void)createHistoricalActivityObject:(NSInteger)activityIndex
{
	[self->backendLock lock];
	CreateHistoricalActivityObject(activityIndex);
	[self->backendLock unlock];
}

- (void)loadHistoricalActivitySummaryData:(NSInteger)activityIndex
{
	[self->backendLock lock];
	LoadHistoricalActivitySummaryData(activityIndex);
	[self->backendLock unlock];
}

- (void)getHistoricalActivityStartAndEndTime:(NSInteger)activityIndex withStartTime:(time_t*)startTime withEndTime:(time_t*)endTime
{
	[self->backendLock lock];
	GetHistoricalActivityStartAndEndTime((size_t)activityIndex, startTime, endTime);
	[self->backendLock unlock];
}

- (ActivityAttributeType)queryHistoricalActivityAttribute:(const char* const)attributeName forActivityIndex:(NSInteger)activityIndex
{
	[self->backendLock lock];
	ActivityAttributeType attr = QueryHistoricalActivityAttribute((size_t)activityIndex, attributeName);
	[self->backendLock unlock];
	return attr;
}

- (ActivityAttributeType)queryHistoricalActivityAttribute:(const char* const)attributeName forActivityId:(NSString*)activityId
{
	[self->backendLock lock];
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);
	ActivityAttributeType attr = QueryHistoricalActivityAttribute(activityIndex, attributeName);
	[self->backendLock unlock];
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

	[self->backendLock lock];
	LoadHistoricalActivityPoints([activityId UTF8String], HistoricalActivityLocationLoadCallback, (__bridge void*)locationData);
	[self->backendLock unlock];

	return locationData;
}

- (NSInteger)getActivityIndexFromActivityId:(NSString*)activityId
{
	[self->backendLock lock];
	NSInteger index = ConvertActivityIdToActivityIndex([activityId UTF8String]);
	[self->backendLock unlock];
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
		[self->backendLock lock];
		StoreHash([activityId UTF8String], [hashStr UTF8String]);
		[self->backendLock unlock];
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
		[self->backendLock lock];
		StoreHash([activityId UTF8String], [hashStr UTF8String]);
		[self->backendLock unlock];
	}
	return hashStr;
}

- (NSString*)retrieveHashForActivityId:(NSString*)activityId
{
	NSString* result = nil;
	char* activityHash = NULL;
	
	[self->backendLock lock];
	activityHash = GetHashForActivityId([activityId UTF8String]);
	[self->backendLock unlock];

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

	[self->backendLock lock];
	activityId = GetActivityIdByHash([activityHash UTF8String]);
	[self->backendLock unlock];

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

	[self->backendLock lock];
	activityName = GetActivityName([activityId UTF8String]);
	[self->backendLock unlock];

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
	if ([self isActivityInProgressAndNotPausedAndLiftingActivity])
	{
		NSDictionary* accelerometerData = [notification object];
		
		NSNumber* x = [accelerometerData objectForKey:@KEY_NAME_ACCEL_X];
		NSNumber* y = [accelerometerData objectForKey:@KEY_NAME_ACCEL_Y];
		NSNumber* z = [accelerometerData objectForKey:@KEY_NAME_ACCEL_Z];
		NSNumber* timestampMs = [accelerometerData objectForKey:@KEY_NAME_ACCELEROMETER_TIMESTAMP_MS];
		
		[self->backendLock lock];

		ProcessAccelerometerReading([x doubleValue], [y doubleValue], [z doubleValue], [timestampMs longLongValue]);

		[self->backendLock unlock];
	}
}

- (void)locationUpdated:(NSNotification*)notification
{
	self->receivingLocations = TRUE;

	if ([self isActivityInProgressAndNotPaused])
	{
		NSDictionary* locationData = [notification object];

		NSNumber* lat = [locationData objectForKey:@KEY_NAME_LATITUDE];
		NSNumber* lon = [locationData objectForKey:@KEY_NAME_LONGITUDE];
		NSNumber* alt = [locationData objectForKey:@KEY_NAME_ALTITUDE];

		NSNumber* horizontalAccuracy = [locationData objectForKey:@KEY_NAME_HORIZONTAL_ACCURACY];
		NSNumber* verticalAccuracy = [locationData objectForKey:@KEY_NAME_VERTICAL_ACCURACY];

		NSNumber* gpsTimestampMs = [locationData objectForKey:@KEY_NAME_GPS_TIMESTAMP_MS];

		BOOL tempBadGps = FALSE;

		uint8_t minHAccuracy = [self->activityPrefs getMinGpsHorizontalAccuracy:self->activityType];
		if (minHAccuracy != (uint8_t)-1)
		{
			uint8_t accuracy = [[locationData objectForKey:@KEY_NAME_HORIZONTAL_ACCURACY] intValue];
			if (minHAccuracy != 0 && accuracy > minHAccuracy)
			{
				tempBadGps = TRUE;
			}
		}
		
		uint8_t minVAccuracy = [self->activityPrefs getMinGpsVerticalAccuracy:self->activityType];
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
		GpsFilterOption filterOption = [self->activityPrefs getGpsFilterOption:self->activityType];
		
		if (filterOption == GPS_FILTER_DROP && self->badGps)
		{
			shouldProcessReading = FALSE;
		}
		
		if (shouldProcessReading)
		{
			[self->backendLock lock];

			ProcessLocationReading([lat doubleValue], [lon doubleValue], [alt doubleValue], [horizontalAccuracy doubleValue], [verticalAccuracy doubleValue], [gpsTimestampMs longLongValue]);

			[self->backendLock unlock];
		}
	}
}

- (void)heartRateUpdated:(NSNotification*)notification
{
	if ([self isActivityInProgressAndNotPaused])
	{
		NSDictionary* heartRateData = [notification object];

		NSNumber* timestampMs = [heartRateData objectForKey:@KEY_NAME_HRM_TIMESTAMP_MS];
		NSNumber* rate = [heartRateData objectForKey:@KEY_NAME_HEART_RATE];
		
		time_t now = time(NULL);

		if (timestampMs && rate && (now - lastHeartRateUpdate) > 3)
		{
			[self->backendLock lock];

			ProcessHrmReading([rate doubleValue], [timestampMs longLongValue]);

			[self->backendLock unlock];

			lastHeartRateUpdate = now;
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

	[self->backendLock lock];
	GetActivityAttributeNames(attributeNameCallback, (__bridge void*)names);
	[self->backendLock unlock];

	return names;
}

- (NSMutableArray*)getHistoricalActivityAttributes:(NSInteger)activityIndex
{
	NSMutableArray* attributes = [[NSMutableArray alloc] init];

	[self->backendLock lock];

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

	[self->backendLock unlock];

	return attributes;
}

- (NSMutableArray*)getIntervalWorkoutNamesAndIds
{
	NSMutableArray* namesAndIds = [[NSMutableArray alloc] init];

	[self->backendLock lock];

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

	[self->backendLock unlock];

	return namesAndIds;
}

- (NSMutableArray*)getPacePlanNamesAndIds
{
	NSMutableArray* namesAndIds = [[NSMutableArray alloc] init];

	[self->backendLock lock];

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

	[self->backendLock unlock];

	return namesAndIds;
}

- (NSString*)getCurrentActivityType
{
	NSString* activityTypeStr = nil;
	char* activityType = NULL;

	[self->backendLock lock];
	activityType = GetCurrentActivityType();
	[self->backendLock unlock];

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
	
	[self->backendLock lock];
	activityType = GetHistoricalActivityType((size_t)activityIndex);
	[self->backendLock unlock];

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

	[self->backendLock lock];
	activityName = GetHistoricalActivityName((size_t)activityIndex);
	[self->backendLock unlock];

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
	[self->backendLock lock];

	if (InitializePacePlanList())
	{
		if (!GetPacePlanDetails([planId UTF8String], NULL, NULL, NULL, NULL))
		{
			CreateNewPacePlan([planName UTF8String], [planId UTF8String]);
		}
		UpdatePacePlanDetails([planId UTF8String], [planName UTF8String], targetPaceMinKm, targetDistanceKms, splits);
	}

	[self->backendLock unlock];
}

#pragma mark reset methods

- (void)resetDatabase
{
	[self->backendLock lock];
	ResetDatabase();
	[self->backendLock unlock];
}

@end
