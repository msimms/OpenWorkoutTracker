//  Created by Michael Simms on 6/12/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "ExtensionDelegate.h"
#import "ActivityAttribute.h"
#import "ActivityHash.h"
#import "ActivityType.h"
#import "ActivityMgr.h"
#import "ApiClient.h"
#import "CloudPreferences.h"
#import "ExportUtils.h"
#import "FileUtils.h"
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

	self->cloudMgr = [[CloudMgr alloc] init];
	self->activityPrefs = [[ActivityPreferences alloc] init];
	self->badLocationData = FALSE;
	self->receivingLocations = FALSE;
	self->hasConnectivity = FALSE;
	self->lastHeartRateUpdate = 0;
	self->activityType = nil;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accelerometerUpdated:) name:@NOTIFICATION_NAME_ACCELEROMETER object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:@NOTIFICATION_NAME_LOCATION object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(heartRateUpdated:) name:@NOTIFICATION_NAME_HRM object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(broadcastMgrHasFinishedSendingActivity:) name:@NOTIFICATION_NAME_BROADCAST_MGR_SENT_ACTIVITY object:nil];
}

- (void)applicationDidBecomeActive
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application
	// was previously in the background, optionally refresh the user interface.
	[self testNetworkConnectivity];
	[self configureBroadcasting];
	[self startSensorDiscovery];
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

- (void)startSensorDiscovery
{
	if ([Preferences shouldScanForSensors])
	{
		self->bluetoothDeviceFinder = [BtleDiscovery sharedInstance];
	}
}

- (void)stopSensorDiscovery
{
	if (self->bluetoothDeviceFinder)
	{
		[self->bluetoothDeviceFinder stopScanning];
		self->bluetoothDeviceFinder = NULL;
	}
}

- (void)addSensorDiscoveryDelegate:(id<DiscoveryDelegate>)delegate
{
	if (self->bluetoothDeviceFinder)
	{
		[self->bluetoothDeviceFinder addDelegate:delegate];
	}
}

- (void)removeSensorDiscoveryDelegate:(id<DiscoveryDelegate>)delegate
{
	if (self->bluetoothDeviceFinder)
	{
		[self->bluetoothDeviceFinder removeDelegate:delegate];
	}
}

- (void)stopSensors
{
	if (self->sensorMgr)
	{
		[self->sensorMgr stopSensors];
	}
}

void startSensorCallback(SensorType type, void* context)
{
	if (context)
	{
		SensorMgr* mgr = (__bridge SensorMgr*)context;
		[mgr startSensor:type];
	}
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
	BOOL result = FALSE;

	// Generate a unique identifier for the activity.
	NSString* activityId = [[NSUUID UUID] UUIDString];

	// Create the backend data structures for the activity.
	result = StartActivity([activityId UTF8String]);

	if (result)
	{
		ActivityAttributeType startTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_START_TIME);

		self->activityType = [self getCurrentActivityType];

		// If we're doing a pool swim then we'll need to set the length of the pool.
		if ([self->activityType compare:@ACTIVITY_TYPE_POOL_SWIMMING] == NSOrderedSame)
		{
			SetPoolLength([Preferences poolLength], [Preferences poolLengthUnits]);
		}

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
	BOOL result = StopCurrentActivity();

	if (result)
	{
		ActivityAttributeType startTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_START_TIME);
		ActivityAttributeType endTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_END_TIME);
		ActivityAttributeType distance = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED);
		ActivityAttributeType calories = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_CALORIES_BURNED);

		NSString* activityId = [[NSString alloc] initWithFormat:@"%s", GetCurrentActivityId()];
		NSString* activityHash = [self hashCurrentActivity];

		dispatch_queue_t summarizerQueue = dispatch_queue_create("summarizer", NULL);
		dispatch_async(summarizerQueue, ^{
			SaveActivitySummaryData();
			DestroyCurrentActivity();
		});

		// Stop the activity in HealthKit.
		[self->healthMgr stopWorkout:[[NSDate alloc] initWithTimeIntervalSince1970:endTime.value.intVal]];

		// Let other modules know that the activity is stopped.
		NSDictionary* stopData = [[NSDictionary alloc] initWithObjectsAndKeys:
								  activityId, @KEY_NAME_ACTIVITY_ID,
								  self->activityType, @KEY_NAME_ACTIVITY_TYPE,
								  activityHash, @KEY_NAME_ACTIVITY_HASH,
								  [NSNumber numberWithLongLong:startTime.value.intVal], @KEY_NAME_START_TIME,
								  [NSNumber numberWithLongLong:endTime.value.intVal], @KEY_NAME_END_TIME,
								  [NSNumber numberWithDouble:distance.value.doubleVal], @KEY_NAME_DISTANCE,
								  [NSNumber numberWithInt:(UnitSystem)distance.unitSystem], @KEY_NAME_UNITS,
								  [NSNumber numberWithDouble:calories.value.doubleVal], @KEY_NAME_CALORIES,
								  nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_ACTIVITY_STOPPED object:stopData];

		self->activityType = nil;
	}
	return result;
}

- (BOOL)pauseActivity
{
	return PauseCurrentActivity();
}

- (BOOL)deleteActivity:(NSString*)activityId
{
	return DeleteActivityFromDatabase([activityId UTF8String]);
}

- (BOOL)startNewLap
{
	return StartNewLap();
}

- (ActivityAttributeType)queryLiveActivityAttribute:(NSString*)attributeName
{
	ActivityAttributeType attr;
	attr = QueryLiveActivityAttribute([attributeName UTF8String]);
	return attr;
}

#pragma mark methods for creating and destroying the current activity.

- (void)createActivity:(NSString*)activityType
{
	CreateActivityObject([activityType cStringUsingEncoding:NSASCIIStringEncoding]);
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

- (BOOL)isActivityInProgressAndNotPaused
{
	return IsActivityInProgressAndNotPaused();
}

- (BOOL)isActivityInProgressAndNotPausedAndUsesTheAccelerometer
{
	return IsActivityInProgressAndNotPaused() && (IsLiftingActivity() || IsSwimmingActivity());
}

- (BOOL)isActivityPaused
{
	return IsActivityPaused();
}

- (BOOL)isActivityOrphaned:(size_t*)activityIndex
{
	return IsActivityOrphaned(activityIndex);
}

#pragma mark methods for loading and editing historical activities

- (NSInteger)initializeHistoricalActivityList
{
	NSInteger numActivities = 0;

	InitializeHistoricalActivityList();
	numActivities = (NSInteger)GetNumHistoricalActivities();

	return numActivities;
}

- (NSInteger)getNumHistoricalActivities
{
	return (NSInteger)GetNumHistoricalActivities();
}

- (void)createHistoricalActivityObject:(NSInteger)activityIndex
{
	CreateHistoricalActivityObject(activityIndex);
}

- (void)loadHistoricalActivitySummaryData:(NSInteger)activityIndex
{
	LoadHistoricalActivitySummaryData(activityIndex);
}

- (void)getHistoricalActivityStartAndEndTime:(NSInteger)activityIndex withStartTime:(time_t*)startTime withEndTime:(time_t*)endTime
{
	GetHistoricalActivityStartAndEndTime((size_t)activityIndex, startTime, endTime);
}

- (ActivityAttributeType)queryHistoricalActivityAttribute:(const char* const)attributeName forActivityIndex:(NSInteger)activityIndex
{
	ActivityAttributeType attr = QueryHistoricalActivityAttribute((size_t)activityIndex, attributeName);
	return attr;
}

- (ActivityAttributeType)queryHistoricalActivityAttribute:(const char* const)attributeName forActivityId:(NSString*)activityId
{
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);
	ActivityAttributeType attr = QueryHistoricalActivityAttribute(activityIndex, attributeName);
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
	LoadHistoricalActivityPoints([activityId UTF8String], HistoricalActivityLocationLoadCallback, (__bridge void*)locationData);
	return locationData;
}

- (NSInteger)getActivityIndexFromActivityId:(NSString*)activityId
{
	return ConvertActivityIdToActivityIndex([activityId UTF8String]);
}

- (NSString*)getActivityIdFromActivityIndex:(NSInteger)activityIndex
{
	const char* const activityId = ConvertActivityIndexToActivityId(activityIndex);

	if (activityId)
	{
		return [[NSString alloc] initWithFormat:@"%s", activityId];
	}
	return NULL;
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
		case FEATURE_STRENGTH_ACTIVITIES:
#if OMIT_STRENGTH_ACTIVITIES
			return FALSE;
#else
			return TRUE;
#endif
		case FEATURE_SWIM_ACTIVITIES:
#if OMIT_SWIM_ACTIVITIES
			return FALSE;
#else
			return TRUE;
#endif
		case FEATURE_MULTISPORT:
#if OMIT_SWIM_ACTIVITIES
			return FALSE;
#else
			return TRUE;
#endif
		case FEATURE_DEBUG:
#if OMIT_DEBUG
			return FALSE;
#else
			return TRUE;
#endif
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

#pragma mark sync status methods

- (BOOL)markAsSynchedToPhone:(NSString*)activityId
{
	return CreateActivitySync([activityId UTF8String], SYNC_DEST_PHONE);
}

- (BOOL)markAsSynchedToWeb:(NSString*)activityId
{
	return CreateActivitySync([activityId UTF8String], SYNC_DEST_WEB);
}

- (BOOL)isSyncedToPhone:(NSString*)activityId
{
	NSMutableArray* syncDests = [self retrieveSyncDestinationsForActivityId:activityId];
	return [syncDests indexOfObject:@SYNC_DEST_PHONE] != NSNotFound;
}

void syncStatusCallback(const char* const destination, void* context)
{
	if (context)
	{
		NSMutableArray* destList = (__bridge NSMutableArray*)context;
		[destList addObject:[[NSString alloc] initWithFormat:@"%s", destination]];
	}
}

- (NSMutableArray*)retrieveSyncDestinationsForActivityId:(NSString*)activityId
{
	NSMutableArray* destinations = [[NSMutableArray alloc] init];
	
	if (destinations)
	{
		RetrieveSyncDestinationsForActivityId([activityId UTF8String], syncStatusCallback, (__bridge void*)destinations);
	}
	return destinations;
}

/// @brief Called when the broadcast manager has finished with an activity.
- (void)broadcastMgrHasFinishedSendingActivity:(NSNotification*)notification
{
	@try
	{
		NSString* activityId = [notification object];
		[self markAsSynchedToWeb:activityId];
	}
	@catch (...)
	{
	}
}

#pragma mark hash methods

- (NSString*)hashCurrentActivity
{
	ActivityHash* hash = [[ActivityHash alloc] init];

	NSString* activityId = [[NSString alloc] initWithFormat:@"%s", GetCurrentActivityId()];
	NSString* hashStr = [hash calculateWithActivityId:activityId];

	if (hashStr)
	{
		CreateOrUpdateActivityHash([activityId UTF8String], [hashStr UTF8String]);
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
	char* activityName = RetrieveActivityName([activityId UTF8String]);

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
	if ([self isActivityInProgressAndNotPausedAndUsesTheAccelerometer])
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

	if ([self isActivityInProgressAndNotPaused])
	{
		NSDictionary* locationData = [notification object];

		NSNumber* lat = [locationData objectForKey:@KEY_NAME_LATITUDE];
		NSNumber* lon = [locationData objectForKey:@KEY_NAME_LONGITUDE];
		NSNumber* alt = [locationData objectForKey:@KEY_NAME_ALTITUDE];

		NSNumber* horizontalAccuracy = [locationData objectForKey:@KEY_NAME_HORIZONTAL_ACCURACY];
		NSNumber* verticalAccuracy = [locationData objectForKey:@KEY_NAME_VERTICAL_ACCURACY];

		NSNumber* locationTimestampMs = [locationData objectForKey:@KEY_NAME_LOCATION_TIMESTAMP_MS];

		BOOL invalidLocationData = FALSE;
		BOOL invalidAltitudeData = FALSE;
		BOOL tempBadLocationData = FALSE;

		// Horizontal accuracy. Per the documentation, a value of less than 0 indicates the value is completely invalid.
		// Otherwise, compare it against our own thresholds.
		double horizAccuracy = [[locationData objectForKey:@KEY_NAME_HORIZONTAL_ACCURACY] doubleValue];
		if (horizAccuracy < (double)0.0)
		{
			invalidLocationData = TRUE;
		}
		else
		{
			uint8_t minHorizAccuracy = [self->activityPrefs getMinLocationHorizontalAccuracy:activityType];
			if (minHorizAccuracy != (uint8_t)-1)
			{
				if (minHorizAccuracy != 0 && horizAccuracy > (double)minHorizAccuracy)
				{
					tempBadLocationData = TRUE;
				}
			}
		}

		// Vertical accuracy. Per the documentation, a value of less than 0 indicates the value is completely invalid.
		// Otherwise, compare it against our own thresholds.
		double vertAccuracy = [[locationData objectForKey:@KEY_NAME_VERTICAL_ACCURACY] doubleValue];
		if (vertAccuracy < (double)0.0)
		{
			invalidAltitudeData = TRUE;
		}
		else
		{
			uint8_t minVertAccuracy = [self->activityPrefs getMinLocationVerticalAccuracy:activityType];
			if (minVertAccuracy != (uint8_t)-1)
			{
				if (minVertAccuracy != 0 && vertAccuracy > (double)minVertAccuracy)
				{
					tempBadLocationData = TRUE;
				}
			}
		}

		// Consider a location bad if it is either completely invalid or just beyond our own thresholds.
		self->badLocationData = invalidLocationData || tempBadLocationData;

		if (!invalidLocationData)
		{
			BOOL shouldProcessReading = TRUE;
			LocationFilterOption filterOption = [self->activityPrefs getLocationFilterOption:self->activityType];
			
			if (filterOption == LOCATION_FILTER_DROP && self->badLocationData)
			{
				shouldProcessReading = FALSE;
			}
			
			if (shouldProcessReading)
			{
				ProcessLocationReading([lat doubleValue], [lon doubleValue], [alt doubleValue], [horizontalAccuracy doubleValue], [verticalAccuracy doubleValue], [locationTimestampMs longLongValue]);
			}
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
			ProcessHrmReading([rate doubleValue], [timestampMs longLongValue]);
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
	GetActivityTypes(activityTypeCallback, (__bridge void*)types, [self isFeaturePresent:FEATURE_STRENGTH_ACTIVITIES], [self isFeaturePresent:FEATURE_SWIM_ACTIVITIES], [self isFeaturePresent:FEATURE_MULTISPORT]);
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
	GetActivityAttributeNames(attributeNameCallback, (__bridge void*)names);
	return names;
}

- (NSMutableArray*)getHistoricalActivityAttributes:(NSInteger)activityIndex
{
	NSMutableArray* attributes = [[NSMutableArray alloc] init];
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

#pragma mark

- (void)createPacePlan:(NSString*)planId withPlanName:(NSString*)planName withTargetPaceInMinKm:(double)targetPaceInMinKm withTargetDistanceInKms:(double)targetDistanceInKms withSplits:(double)splits withTargetDistanceUnits:(UnitSystem)targetDistanceUnits withTargetPaceUnits:(UnitSystem)targetPaceUnits withRoute:(NSString*)route
{
	if (InitializePacePlanList())
	{
		if (!GetPacePlanDetails([planId UTF8String], NULL, NULL, NULL, NULL, NULL, NULL, NULL))
		{
			CreateNewPacePlan([planName UTF8String], [planId UTF8String]);
		}
		UpdatePacePlanDetails([planId UTF8String], [planName UTF8String], targetPaceInMinKm, targetDistanceInKms, targetDistanceUnits, targetPaceUnits, splits, time(NULL));
	}
}

#pragma mark methods for exporting activities

- (NSString*)exportActivityToTempFile:(NSString*)activityId withFileFormat:(FileFormat)format
{
	NSString* exportFileName = nil;
	NSString* exportDir = [ExportUtils createExportDir];

	if (exportDir)
	{
		size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

		// Make sure we have a valid activity from the database.
		if (activityIndex != ACTIVITY_INDEX_UNKNOWN)
		{
			char* tempExportFileName = ExportActivityFromDatabase([activityId UTF8String], format, [exportDir UTF8String]);

			if (tempExportFileName)
			{
				exportFileName = [[NSString alloc] initWithFormat:@"%s", tempExportFileName];
				free((void*)tempExportFileName);
			}
		}
	}
	return exportFileName;
}

- (BOOL)isCloudServiceAvailable:(CloudServiceType)service
{
	if (self->cloudMgr)
	{
		return ([self->cloudMgr isLinked:service]);
	}
	return FALSE;
}

- (BOOL)exportActivityFileToCloudService:(NSString*)fileName forActivityId:(NSString*)activityId toService:(CloudServiceType)service
{
	if (self->cloudMgr)
	{
		NSString* activityName = [self getActivityName:activityId];
		return [self->cloudMgr uploadActivityFile:fileName forActivityId:activityId forActivityName:activityName toService:service];
	}
	return FALSE;
}

- (BOOL)exportActivityToCloudService:(NSString*)activityId toService:(CloudServiceType)service
{
	BOOL result = FALSE;

	// Can we even do this?
	if (self->cloudMgr && [self->cloudMgr isLinked:service])
	{
		// Export the activity to a temp file.
		NSString* exportedFileName = [self exportActivityToTempFile:activityId withFileFormat:FILE_GPX];

		// Activity exported?
		if (exportedFileName)
		{
			result = [self exportActivityFileToCloudService:exportedFileName forActivityId:activityId toService:service];
		}
		else
		{
			NSLog(@"Error when exporting an activity to send to a cloud service.");
		}

		// Remove the temp file.
		BOOL tempFileDeleted = [FileUtils deleteFile:exportedFileName];
		if (!tempFileDeleted)
		{
			NSLog(@"Failed to delete temp file %@.", exportedFileName);
		}
	}

	return result;
}

- (BOOL)exportActivityToPhone:(NSString*)activityId
{
	BOOL result = FALSE;

	if (self->watchSession)
	{
		[self->watchSession sendActivity:activityId];
	}
	return result;
}

#pragma mark reset methods

- (void)resetDatabase
{
	ResetDatabase();
}

@end
