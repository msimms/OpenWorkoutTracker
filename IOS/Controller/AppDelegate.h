// Created by Michael Simms on 7/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <WatchConnectivity/WatchConnectivity.h>

#import "ActivityAttributeType.h"
#import "ActivityLevel.h"
#import "ActivityPreferences.h"
#import "BroadcastManager.h"
#import "BtleDiscovery.h"
#import "CloudMgr.h"
#import "Defines.h"
#import "Feature.h"
#import "FileFormat.h"
#import "Gender.h"
#import "HealthManager.h"
#import "MultipeerSession.h"
#import "SensorMgr.h"
#import "SensorType.h"

#define EXPORT_TO_EMAIL_STR "Email"

@interface AppDelegate : UIResponder <UIApplicationDelegate, WCSessionDelegate>
{
	SensorMgr*           sensorMgr;             // For managing sensors, whether they are built into the phone (location, accelerometer) or external (cycling power).
	BtleDiscovery*       bluetoothDeviceFinder; // For discovering Bluetooth devices, such as heart rate monitors and power meters.
	CloudMgr*            cloudMgr;              // For interfacing with cloud services such as iCloud, Dropbox, and Strava.
	ActivityPreferences* activityPrefs;         // For managing activity-related preferences.
#if !OMIT_BROADCAST
	BroadcastManager*    broadcastMgr;          // For sending data to the cloud service.
	MultipeerSession*    multipeerSession;      // Handles peer-to-peer connections.
#endif
	HealthManager*       healthMgr;             // Interfaces with Apple HealthKit.
	NSTimer*             intervalTimer;         // Timer that fires when it's time to advance to the next part of an interval workout.
	WCSession*           watchSession;          // Interfaces with the watch app.
	BOOL                 currentlyImporting;    // TRUE if currently importing an activity (like from the watch, for example).
	size_t               currentActivityIndex;  // Used when iterating over historical activities.
}

- (NSString*)getDeviceId;

// feature management; some features may be optionally disabled

- (BOOL)isFeaturePresent:(Feature)feature;
- (BOOL)isFeatureEnabled:(Feature)feature;

// describes the phone; only used for determining if we're on a really old phone or not

- (NSString*)getPlatformString;

// unit management methods

- (void)setUnits;

// user profile methods

- (ActivityLevel)userActivityLevel;
- (Gender)userGender;
- (struct tm)userBirthDate;
- (double)userHeight;
- (double)userWeight;
- (NSDictionary*)userWeightHistory;
- (double)userSpecifiedFtp;
- (double)userEstimatedFtp;

- (void)setUserActivityLevel:(ActivityLevel)activityLevel;
- (void)setUserGender:(Gender)gender;
- (void)setUserBirthDate:(NSDate*)birthday;
- (void)setUserHeight:(double)height;
- (void)setUserWeight:(double)weight;
- (void)setUserFtp:(double)ftp;

// watch methods

- (void)configureWatchSession;

// broadcast methods

- (void)configureBroadcasting;

// healthkit methods

- (void)startHealthMgr;

// bluetooth methods

- (BOOL)hasBluetoothSupport;
- (BOOL)hasBluetoothSensorOfType:(SensorType)sensorType;
- (NSMutableArray*)listDiscoveredBluetoothSensorsWithServiceId:(BluetoothServiceId)serviceId;
- (NSMutableArray*)listDiscoveredBluetoothSensorsWithCustomServiceId:(NSString*)serviceId;
- (void)allowConnectionsFromUnknownBluetoothDevices:(BOOL)allow;

// sensor management methods

- (void)startSensorDiscovery;
- (void)stopSensorDiscovery;
- (void)addSensorDiscoveryDelegate:(id<DiscoveryDelegate>)delegate;
- (void)removeSensorDiscoveryDelegate:(id<DiscoveryDelegate>)delegate;
- (void)stopSensors;
- (void)startSensors;
- (BOOL)isRadarConnected;

// sensor update methods

- (void)weightHistoryUpdated:(NSNotification*)notification;
- (void)accelerometerUpdated:(NSNotification*)notification;
- (void)locationUpdated:(NSNotification*)notification;
- (void)heartRateUpdated:(NSNotification*)notification;
- (void)cadenceUpdated:(NSNotification*)notification;
- (void)wheelSpeedUpdated:(NSNotification*)notification;
- (void)powerUpdated:(NSNotification*)notification;
- (void)strideLengthUpdated:(NSNotification*)notification;
- (void)runDistanceUpdated:(NSNotification*)notification;

// methods for starting and stopping activities, etc.

- (BOOL)startActivity;
- (BOOL)stopActivity;
- (BOOL)pauseActivity;
- (BOOL)startNewLap;
- (ActivityAttributeType)queryLiveActivityAttribute:(NSString*)attributeName;

// methods for creating and destroying the current activity.

- (void)createActivity:(NSString*)activityType;
- (void)recreateOrphanedActivity:(NSInteger)activityIndex;
- (void)destroyCurrentActivity;

// methods for querying the status of the current activity.

- (BOOL)isImportingActivityFromWatch;
- (BOOL)isActivityCreated;
- (BOOL)isActivityInProgress;
- (BOOL)isActivityInProgressAndNotPaused;
- (BOOL)isActivityOrphaned:(size_t*)activityIndex;
- (BOOL)isActivityPaused;
- (BOOL)isCyclingActivity;
- (BOOL)isFootBasedActivity;
- (BOOL)isMovingActivity;

// methods for loading and editing historical activities

- (NSInteger)initializeHistoricalActivityList;
- (void)loadAllHistoricalActivitySummaryData;
- (NSString*)getNextActivityId;
- (NSInteger)getNumHistoricalActivities;
- (NSInteger)getNumHistoricalActivityLocationPoints:(NSString*)activityId;
- (NSInteger)getNumHistoricalActivityAccelerometerReadings:(NSString*)activityId;
- (void)createHistoricalActivityObject:(NSString*)activityId;
- (BOOL)isHealthKitActivity:(NSString*)activityId;
- (BOOL)loadHistoricalActivityByIndex:(NSInteger)activityIndex;
- (BOOL)loadHistoricalActivity:(NSString*)activityId;
- (void)loadHistoricalActivitySummaryData:(NSString*)activityId;
- (void)saveHistoricalActivitySummaryData:(NSString*)activityId;
- (void)getHistoricalActivityStartAndEndTime:(NSString*)activityId withStartTime:(time_t*)startTime withEndTime:(time_t*)endTime;
- (BOOL)getHistoricalActivityLocationPoint:(NSString*)activityId withPointIndex:(size_t)pointIndex withLatitude:(double*)latitude withLongitude:(double*)longitude withAltitude:(double*)altitude withTimestamp:(time_t*)timestamp;
- (ActivityAttributeType)queryHistoricalActivityAttribute:(const char* const)attributeName forActivityIndex:(NSInteger)activityIndex;
- (ActivityAttributeType)queryHistoricalActivityAttribute:(const char* const)attributeName forActivityId:(NSString*)activityId;
- (BOOL)isHistoricalActivityFootBased:(NSString*)activityId;
- (void)setHistoricalActivityAttribute:(NSString*)activityId withAttributeName:(const char* const)attributeName withAttributeType:(ActivityAttributeType) attributeValue;
- (BOOL)loadHistoricalActivitySensorData:(SensorType)sensorType forActivityId:(NSString*)activityId withCallback:(void*)callback withContext:(void*)context;
- (BOOL)loadAllHistoricalActivitySensorData:(NSString*)activityId;
- (BOOL)trimActivityData:(NSString*)activityId withNewTime:(uint64_t)newTime fromStart:(BOOL)fromStart;
- (BOOL)deleteActivity:(NSString*)activityId;
- (void)freeHistoricalActivityList;

// methods for listing locations from the current activity.

- (BOOL)getCurrentActivityPoint:(size_t)pointIndex withLatitude:(double*)latitude withLongitude:(double*)longitude;

// hash methods

- (NSString*)getActivityHash:(NSString*)activityId;
- (NSString*)hashCurrentActivity;

// methods for managing bike profiles

- (BOOL)initializeBikeProfileList;
- (BOOL)createBikeProfile:(NSString*)name withWeight:(double)weightKg withWheelCircumference:(double)wheelCircumferenceMm withTimeRetired:(time_t)timeRetired;
- (BOOL)updateBikeProfile:(uint64_t)bikeId withName:(NSString*)name withWeight:(double)weightKg withWheelCircumference:(double)wheelCircumferenceMm withTimeRetired:(time_t)timeRetired;
- (BOOL)getBikeProfileById:(uint64_t)bikeId withName:(char** const)name withWeightKg:(double*)weightKg withWheelCircumferenceMm:(double*)wheelCircumferenceMm withTimeRetired:(time_t*)timeRetired;
- (uint64_t)getBikeIdFromName:(NSString*)bikeName;
- (BOOL)deleteBikeProfile:(uint64_t)bikeId;

// methods for managing shoes

- (BOOL)initializeShoeProfileList;
- (BOOL)createShoeProfile:(NSString*)name withDescription:(NSString*)description withTimeAdded:(time_t)timeAdded withTimeRetired:(time_t)timeRetired;
- (BOOL)updateShoeProfile:(uint64_t)bikeId withName:(NSString*)name withDescription:(NSString*)description withTimeAdded:(time_t)timeAdded withTimeRetired:(time_t)timeRetired;
- (uint64_t)getShoeIdFromName:(NSString*)shoeName;
- (BOOL)deleteShoeProfile:(uint64_t)shoeId;

// sound methods

- (void)playSound:(NSString*)soundPath;
- (void)playBeepSound;
- (void)playPingSound;

// sync status methods

- (BOOL)markAsSynchedToWeb:(NSString*)activityId;
- (BOOL)markAsSynchedToICloudDrive:(NSString*)activityId;
- (NSMutableArray*)retrieveSyncDestinationsForActivityId:(NSString*)activityId;

// methods for exporting activities

- (BOOL)deleteFile:(NSString*)fileName;
- (BOOL)exportFileToCloudService:(NSString*)fileName toServiceNamed:(NSString*)serviceName;
- (BOOL)exportFileToCloudService:(NSString*)fileName toService:(CloudServiceType)service;
- (BOOL)exportActivityFileToCloudService:(NSString*)fileName forActivityId:(NSString*)activityId toServiceNamed:(NSString*)serviceName;
- (BOOL)exportActivityFileToCloudService:(NSString*)fileName forActivityId:(NSString*)activityId toService:(CloudServiceType)service;
- (BOOL)exportActivityToCloudService:(NSString*)activityId toService:(CloudServiceType)service;
- (NSString*)exportActivityToTempFile:(NSString*)activityId withFileFormat:(FileFormat)format;
- (NSString*)exportActivitySummary:(NSString*)activityType;
- (void)clearExportDir;

// methods for managing the activity name

- (BOOL)updateActivityName:(NSString*)activityId withName:(NSString*)name;
- (NSString*)getActivityName:(NSString*)activityId;

// methods for managing the activity type

- (BOOL)updateActivityType:(NSString*)activityId withName:(NSString*)type;

// methods for managing the activity description

- (BOOL)updateActivityDescription:(NSString*)activityId withDescription:(NSString*)description;
- (NSString*)getActivityDescription:(NSString*)activityId;

// accessor methods

- (NSMutableArray*)getTagsForActivity:(NSString*)activityId;
- (NSArray*)getBikeNames;
- (NSArray*)getShoeNames;
- (NSMutableArray*)getIntervalWorkoutNamesAndIds;
- (NSMutableArray*)getPacePlanNamesAndIds;
- (NSArray*)getEnabledFileExportCloudServices;
- (NSArray*)getEnabledFileExportServices;
- (NSArray*)getActivityTypes;
- (NSArray*)getCurrentActivityAttributes;
- (NSArray*)getHistoricalActivityAttributes:(NSString*)activityId;

- (NSString*)getCurrentActivityType;
- (NSString*)getHistoricalActivityTypeForIndex:(NSInteger)activityIndex;
- (NSString*)getHistoricalActivityType:(NSString*)activityId;

- (NSString*)getCurrentActivityId;

// methods for managing interval sessions

- (BOOL)createNewIntervalSession:(NSString*)sessionId withName:(NSString*)sessionName withSport:(NSString*)sport withDescription:(NSString*)description;
- (BOOL)retrieveIntervalSession:(NSString*)sessionId withName:(NSString**)sessionName withSport:(NSString**)sport withDescription:(NSString**)description;
- (BOOL)setCurrentIntervalSession:(NSString*)sessionId;
- (BOOL)deleteIntervalSession:(NSString*)sessionId;
- (NSString*)getCurrentIntervalSessionId;

// methods for managing pace plans

- (BOOL)createNewPacePlan:(NSString*)planName withPlanId:(NSString*)planId;
- (BOOL)retrievePacePlan:(NSString*)planId withPlanName:(NSString**)name withTargetDistance:(double*)targetDistance withTargetTime:(time_t*)targetTime withSplits:(time_t*)targetSplits withTargetDistanceUnits:(UnitSystem*)targetDistanceUnits withTargetSplitsUnits:(UnitSystem*)targetSplitsUnits;
- (BOOL)updatePacePlan:(NSString*)planId withPlanName:(NSString*)name withTargetDistance:(double)targetDistance withTargetTime:(time_t)targetTime withSplits:(time_t)targetSplits withTargetDistanceUnits:(UnitSystem)targetDistanceUnits withTargetSplitsUnits:(UnitSystem)targetSplitsUnits;
- (BOOL)setCurrentPacePlan:(NSString*)planId;
- (BOOL)deletePacePlanWithId:(NSString*)planId;
- (NSString*)getCurrentPacePlanId;

// methods for managing workouts

- (BOOL)generateWorkouts;
- (NSMutableArray*)getPlannedWorkouts;
- (BOOL)deleteWorkoutWithId:(NSString*)workoutId;
- (NSString*)exportWorkoutWithId:(NSString*)workoutId;

// methods for managing tags

- (BOOL)createTag:(NSString*)tag forActivityId:(NSString*)activityId;
- (BOOL)deleteTag:(NSString*)tag forActivityId:(NSString*)activityId;
- (void)searchForTags:(NSString*)searchText;

// utility methods

- (void)setScreenLocking;

// unit conversion methods

- (double)convertMilesToKms:(double)value;
- (double)convertMinutesPerMileToMinutesPerKm:(double)value;
- (double)convertMinutesPerKmToMinutesPerMile:(double)value;
- (double)convertPoundsToKgs:(double)value;
- (void)convertToPreferredUnits:(ActivityAttributeType*)attr;

// cloud methods

- (NSMutableArray*)listCloudServices;
- (NSString*)nameOfCloudService:(CloudServiceType)service;
- (void)requestCloudServiceAcctNames:(CloudServiceType)service;

// These methods are used to interact with the server. The app should still function, in all but the obvious ways,
// if server communications are disabled (which should be the default).

- (void)syncWithServer;
- (BOOL)serverLogin:(NSString*)username withPassword:(NSString*)password;
- (BOOL)serverCreateLogin:(NSString*)username withPassword:(NSString*)password1 withConfirmation:(NSString*)password2 withRealName:(NSString*)realname;
- (BOOL)serverIsLoggedIn;
- (BOOL)serverLogout;
- (BOOL)serverListFriends;
- (BOOL)serverRequestToFollow:(NSString*)targetUsername;
- (BOOL)serverRequestActivityMetadata:(NSString*)activityId;
- (BOOL)serverDeleteActivity:(NSString*)activityId;
- (BOOL)serverCreateTag:(NSString*)tag forActivity:(NSString*)activityId;
- (BOOL)serverDeleteTag:(NSString*)tag forActivity:(NSString*)activityId;

// reset methods

- (void)resetDatabase;
- (void)resetPreferences;

@property (strong, nonatomic) UIWindow* window;

@end
