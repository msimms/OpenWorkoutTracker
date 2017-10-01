// Created by Michael Simms on 7/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <AudioToolbox/AudioToolbox.h>
#import "TargetConditionals.h"

#import "AppDelegate.h"
#import "ActivityMgr.h"
#import "Accelerometer.h"
#import "ActivityAttribute.h"
#import "LeBikeSpeedAndCadence.h"
#import "LeFootPod.h"
#import "LeHeartRateMonitor.h"
#import "LePowerMeter.h"
#import "LeScale.h"
#import "LocationSensor.h"
#import "Preferences.h"
#import "SensorFactory.h"
#import "UnitConversionFactors.h"
#import "UserProfile.h"

#include <sys/sysctl.h>

#define DATABASE_NAME               "Activities.sqlite"
#define MAP_OVERLAY_DIR_NAME        "Map Overlays"

#define BROADCAST_LOGIN_URL         "login_submit?"
#define BROADCAST_CREATE_LOGIN_URL  "create_login_submit?"
#define BROADCAST_LIST_FOLLOWING    "list_users_following?"
#define BROADCAST_LIST_FOLLOWED_BY  "list_users_followed_by?"
#define BROADCAST_INVITE_TO_FOLLOW  "invite_to_follow?"
#define BROADCAST_REQUEST_TO_FOLLOW "request_to_follow?"

@implementation UINavigationController (Rotation_IOS6)

- (BOOL)shouldAutorotate
{
	return [[self.viewControllers lastObject] shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations
{
	return [[self.viewControllers lastObject] supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
	return [[self.viewControllers lastObject] preferredInterfaceOrientationForPresentation];
}

@end

@implementation AppDelegate

@synthesize window = _window;

#pragma mark methods for monitoring app state changes

- (BOOL)application:(UIApplication*)application willFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
	return YES;
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{	
	NSArray*  paths      = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* docDir     = [paths objectAtIndex: 0];
	NSString* dbFileName = [docDir stringByAppendingPathComponent:@DATABASE_NAME];

	Initialize([dbFileName UTF8String]);
	
	[self clearExportDir];

	[Preferences registerDefaultsFromSettingsBundle:@"Root.plist"];
	[Preferences registerDefaultsFromSettingsBundle:@"Profile.plist"];
	[Preferences registerDefaultsFromSettingsBundle:@"SocialCloud.plist"];

	SensorFactory* sensorFactory = [[SensorFactory alloc] init];
	
	Accelerometer* accelerometerController = [sensorFactory createAccelerometer];
	LocationSensor* locationController = [sensorFactory createLocationSensor];

	self->sensorMgr = [SensorMgr sharedInstance];
	if (self->sensorMgr)
	{
		[self->sensorMgr addSensor:(accelerometerController)];
		[self->sensorMgr addSensor:(locationController)];
	}

	self->activityPrefs = [[ActivityPreferences alloc] init];
	self->shouldTweetSplitTimes = FALSE;
	self->badGps = FALSE;

	self->lastLocationUpdateTime = 0;
	self->lastHeartRateUpdateTime = 0;
	self->lastCadenceUpdateTime = 0;
	self->lastWheelSpeedUpdateTime = 0;
	self->lastPowerUpdateTime = 0;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(weightUpdated:) name:@NOTIFICATION_NAME_WEIGHT_UPDATED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accelerometerUpdated:) name:@NOTIFICATION_NAME_ACCELEROMETER object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:@NOTIFICATION_NAME_LOCATION object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(heartRateUpdated:) name:@NOTIFICATION_NAME_HRM object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cadenceUpdated:) name:@NOTIFICATION_NAME_BIKE_CADENCE object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wheelSpeedUpdated:) name:@NOTIFICATION_NAME_BIKE_WHEEL_SPEED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(powerUpdated:) name:@NOTIFICATION_NAME_POWER object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(strideLengthUpdated:) name:@NOTIFICATION_NAME_RUN_STRIDE_LENGTH object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runDistanceUpdated:) name:@NOTIFICATION_NAME_RUN_DISTANCE object:nil];

	[self startInteralTimer];

	return YES;
}

- (void)applicationDidBecomeActive:(UIApplication*)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive.
	// If the application was previously in the background, optionally refresh the user interface.

	[self startSensorDiscovery];
	[self configureBroadcasting];
	[self startHealthMgr];

	self->cloudMgr = [[CloudMgr alloc] init];

	self->shouldTweetSplitTimes = [Preferences shouldTweetRunSplits];

	[self setUnits];
	[self setUserProfile];
}

- (void)applicationWillResignActive:(UIApplication*)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain
	// types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits
	// the application and it begins the transition to the background state. Use this method to pause ongoing
	// tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application
	// state information to restore your application to its current state in case it is terminated later. If your
	// application supports background execution, this method is called instead of applicationWillTerminate when the user quits.
	if (IsActivityInProgress())
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

- (void)applicationWillEnterForeground:(UIApplication*)application
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

- (void)applicationWillTerminate:(UIApplication*)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground.
	[self stopSensors];
}

- (void)applicationDidFinishLaunching:(UIApplication*)application
{
}

#pragma mark methods for responding to system notifications

- (void)applicationDidReceiveMemoryWarning:(UIApplication*)application
{
	FreeHistoricalActivityList();
}

- (void)applicationSignificantTimeChange:(UIApplication*)application
{
}

#pragma mark methods for managing application state restoration

- (BOOL)application:(UIApplication*)application shouldSaveApplicationState:(NSCoder*)coder
{
	return YES;
}

- (BOOL)application:(UIApplication*)application shouldRestoreApplicationState:(NSCoder*)coder
{
	return YES;
}

- (void)application:(UIApplication*)application willEncodeRestorableStateWithCoder:(NSCoder*)coder
{
}

- (void)application:(UIApplication*)application didDecodeRestorableStateWithCoder:(NSCoder*)coder
{
}

- (BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)url
{
	return NO;
}

#pragma mark 

- (NSString*)getUuid;
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
		case FEATURE_MAP_OVERLAYS:
			return TRUE;
		case FEATURE_HEATMAP:
			return FALSE;
		case FEATURE_LOCAL_BROADCAST:
			return FALSE;
		case FEATURE_GLOBAL_BROADCAST:
			return TRUE;
		case FEATURE_DROPBOX:
			return FALSE;
		case FEATURE_ICLOUD:
			return FALSE;
		case FEATURE_STRAVA:
			return FALSE;
		case FEATURE_RUNKEEPER:
			return FALSE;
		case FEATURE_TWITTER:
			return FALSE;
	}
	return TRUE;
}

- (BOOL)isFeatureEnabled:(Feature)feature
{
	switch (feature)
	{
		case FEATURE_MAP_OVERLAYS:
		case FEATURE_HEATMAP:
		case FEATURE_LOCAL_BROADCAST:
		case FEATURE_GLOBAL_BROADCAST:
			return [self isFeaturePresent:feature] && [self isFeaturePresent:feature];
		case FEATURE_DROPBOX:
			return [self isFeaturePresent:feature] && [self->cloudMgr isLinked:CLOUD_SERVICE_DROPBOX];
		case FEATURE_ICLOUD:
			return [self isFeaturePresent:feature] && [self->cloudMgr isLinked:CLOUD_SERVICE_ICLOUD];
		case FEATURE_STRAVA:
			return [self isFeaturePresent:feature] && [self->cloudMgr isLinked:CLOUD_SERVICE_STRAVA];
		case FEATURE_RUNKEEPER:
			return [self isFeaturePresent:feature] && [self->cloudMgr isLinked:CLOUD_SERVICE_RUNKEEPER];
		case FEATURE_TWITTER:
			return TRUE;
	}
	return TRUE;
}

- (NSString*)getPlatformString
{
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);

	char* machine = malloc(size);
	sysctlbyname("hw.machine", machine, &size, NULL, 0);

	NSString* platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
	free(machine);

	if ([platform isEqualToString:@"iPhone1,1"]) return @"iPhone 2G";
	if ([platform isEqualToString:@"iPhone1,2"]) return @"iPhone 3G";
	if ([platform isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS";
	if ([platform isEqualToString:@"iPhone3,1"]) return @"iPhone 4";
	if ([platform isEqualToString:@"iPhone3,2"]) return @"iPhone 4";
	if ([platform isEqualToString:@"iPhone3,3"]) return @"iPhone 4 (CDMA)";
	if ([platform isEqualToString:@"iPhone4,1"]) return @"iPhone 4S";
	if ([platform isEqualToString:@"iPhone5,1"]) return @"iPhone 5";
	if ([platform isEqualToString:@"iPhone5,2"]) return @"iPhone 5 (GSM+CDMA)";

	if ([platform isEqualToString:@"iPod1,1"])   return @"iPod Touch (1 Gen)";
	if ([platform isEqualToString:@"iPod2,1"])   return @"iPod Touch (2 Gen)";
	if ([platform isEqualToString:@"iPod3,1"])   return @"iPod Touch (3 Gen)";
	if ([platform isEqualToString:@"iPod4,1"])   return @"iPod Touch (4 Gen)";
	if ([platform isEqualToString:@"iPod5,1"])   return @"iPod Touch (5 Gen)";

	if ([platform isEqualToString:@"iPad1,1"])   return @"iPad";
	if ([platform isEqualToString:@"iPad1,2"])   return @"iPad 3G";
	if ([platform isEqualToString:@"iPad2,1"])   return @"iPad 2 (WiFi)";
	if ([platform isEqualToString:@"iPad2,2"])   return @"iPad 2";
	if ([platform isEqualToString:@"iPad2,3"])   return @"iPad 2 (CDMA)";
	if ([platform isEqualToString:@"iPad2,4"])   return @"iPad 2";
	if ([platform isEqualToString:@"iPad2,5"])   return @"iPad Mini (WiFi)";
	if ([platform isEqualToString:@"iPad2,6"])   return @"iPad Mini";
	if ([platform isEqualToString:@"iPad2,7"])   return @"iPad Mini (GSM+CDMA)";
	if ([platform isEqualToString:@"iPad3,1"])   return @"iPad 3 (WiFi)";
	if ([platform isEqualToString:@"iPad3,2"])   return @"iPad 3 (GSM+CDMA)";
	if ([platform isEqualToString:@"iPad3,3"])   return @"iPad 3";
	if ([platform isEqualToString:@"iPad3,4"])   return @"iPad 4 (WiFi)";
	if ([platform isEqualToString:@"iPad3,5"])   return @"iPad 4";
	if ([platform isEqualToString:@"iPad3,6"])   return @"iPad 4 (GSM+CDMA)";

	if ([platform isEqualToString:@"i386"])      return @"Simulator";
	if ([platform isEqualToString:@"x86_64"])    return @"Simulator";

	return platform;
}

#pragma mark unit management methods

- (void)setUnits
{
	UnitSystem preferredUnits = [Preferences preferredUnitSystem];
	SetUnitSystem(preferredUnits);
}

#pragma mark user profile methods

- (void)setUserProfile
{
	ActivityLevel userLevel = [UserProfile activityLevel];
	Gender userGender       = [UserProfile gender];
	struct tm userBirthDay  = [UserProfile birthDate];
	double userWeightKg     = [UserProfile weightInKg];
	double userHeightCm     = [UserProfile heightInCm];
	SetUserProfile(userLevel, userGender, userBirthDay, userWeightKg, userHeightCm);
}

- (ActivityLevel)userActivityLevel
{
	return [UserProfile activityLevel];
}

- (Gender)userGender;
{
	return [UserProfile gender];
}

- (struct tm)userBirthDate
{
	return [UserProfile birthDate];
}

- (double)userHeight
{
	switch ([Preferences preferredUnitSystem])
	{
		case UNIT_SYSTEM_METRIC:
			return [UserProfile heightInCm];
		case UNIT_SYSTEM_US_CUSTOMARY:
			return [UserProfile heightInInches];
	}
	return (double)0.0;
}

- (double)userWeight
{
	switch ([Preferences preferredUnitSystem])
	{
		case UNIT_SYSTEM_METRIC:
			return [UserProfile weightInKg];
		case UNIT_SYSTEM_US_CUSTOMARY:
			return [UserProfile weightInLbs];
	}
	return (double)0.0;
}

- (void)setUserActivityLevel:(ActivityLevel)activityLevel
{
	[UserProfile setActivityLevel:activityLevel];
}

- (void)setUserGender:(Gender)gender
{
	[UserProfile setGender:gender];
}

- (void)setUserBirthDate:(NSDate*)birthday
{
	[UserProfile setBirthDate:birthday];
}

- (void)setUserHeight:(double)height
{
	switch ([Preferences preferredUnitSystem])
	{
		case UNIT_SYSTEM_METRIC:
			[UserProfile setHeightInCm:height];
			break;
		case UNIT_SYSTEM_US_CUSTOMARY:
			[UserProfile setHeightInInches:height];
			break;
	}

	[self->healthMgr saveHeightIntoHealthStore:[UserProfile heightInInches]];
}

- (void)setUserWeight:(double)weight
{
	switch ([Preferences preferredUnitSystem])
	{
		case UNIT_SYSTEM_METRIC:
			[UserProfile setWeightInKg:weight];
			break;
		case UNIT_SYSTEM_US_CUSTOMARY:
			[UserProfile setWeightInLbs:weight];
			break;
	}

	[self->healthMgr saveWeightIntoHealthStore:[UserProfile weightInLbs]];
}

#pragma mark broadcast methods

- (void)configureBroadcasting
{
	if ([Preferences shouldBroadcastLocally] || [Preferences shouldBroadcastGlobally])
	{
		if (!self->broadcastMgr)
		{
			self->broadcastMgr = [[BroadcastManager alloc] init];
		}
	}
	else
	{
		self->broadcastMgr = nil;
	}
}

#pragma mark healthkit methods

- (void)startHealthMgr
{
	self->healthMgr = [[HealthManager alloc] init];
	if (self->healthMgr)
	{
		[self->healthMgr start];
	}
}

#pragma mark bluetooth methods

- (BOOL)hasLeBluetooth
{
	NSString* platform = [self getPlatformString];

	NSRange isIPhone2  = [platform rangeOfString:@"iPhone 2" options:NSCaseInsensitiveSearch];
	NSRange isIPhone3  = [platform rangeOfString:@"iPhone 3" options:NSCaseInsensitiveSearch];
	NSRange isIPhone4  = [platform rangeOfString:@"iPhone 4" options:NSCaseInsensitiveSearch];
	NSRange isIPhone4S = [platform rangeOfString:@"iPhone 4S" options:NSCaseInsensitiveSearch];

	if ((isIPhone2.location != NSNotFound) ||
		(isIPhone3.location != NSNotFound))
	{
		return FALSE;
	}

	if ((isIPhone4.location != NSNotFound) &&
		(isIPhone4S.location == NSNotFound))
	{
		return FALSE;
	}
	return TRUE;
}

- (BOOL)hasLeBluetoothSensor:(SensorType)sensorType
{
	if (self->leSensorFinder)
	{
		return [self->leSensorFinder hasConnectedSensor:sensorType];
	}
	return FALSE;
}

- (NSMutableArray*)listDiscoveredBluetoothSensorsOfType:(BluetoothService)type
{
	if (self->leSensorFinder)
	{
		return [self->leSensorFinder discoveredSensorsOfType:type];
	}
	return nil;
}

#pragma mark sensor management methods

- (void)startSensorDiscovery
{
	if ([Preferences shouldScanForSensors])
	{
		if ([self hasLeBluetooth])
		{
			self->leSensorFinder = [LeDiscovery sharedInstance];
		}
		else
		{
			self->leSensorFinder = NULL;
		}
		
		self->wifiSensorFinder = [WiFiDiscovery sharedInstance];
	}
}

- (void)stopSensorDiscovery
{
	if (self->leSensorFinder)
	{
		[self->leSensorFinder stopScanning];
		self->leSensorFinder = NULL;
	}
	if (self->wifiSensorFinder)
	{
		[self->wifiSensorFinder stopScanning];
		self->wifiSensorFinder = NULL;
	}
}

- (void)addSensorDiscoveryDelegate:(id<DiscoveryDelegate>)delegate
{
	if (self->leSensorFinder)
	{
		[self->leSensorFinder addDelegate:delegate];
	}
	if (self->wifiSensorFinder)
	{
		[self->wifiSensorFinder addDelegate:delegate];
	}
}

- (void)removeSensorDiscoveryDelegate:(id<DiscoveryDelegate>)delegate
{
	if (self->leSensorFinder)
	{
		[self->leSensorFinder removeDelegate:delegate];
	}
	if (self->wifiSensorFinder)
	{
		[self->wifiSensorFinder removeDelegate:delegate];
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
	SensorMgr* mgr = (__bridge SensorMgr*)context;
	[mgr startSensor:type];
}

- (void)startSensors
{
	if (self->sensorMgr)
	{
		[self->sensorMgr stopSensors];
		GetUsableSensorTypes(startSensorCallback, (__bridge void*)self->sensorMgr);
	}
}

#pragma mark sensor update methods

- (void)weightUpdated:(NSNotification*)notification
{
	NSDictionary* weightData = [notification object];

	NSNumber* weightKg = [weightData objectForKey:@KEY_NAME_WEIGHT_KG];
	NSNumber* time = [weightData objectForKey:@KEY_NAME_TIME];
	
	ProcessWeightReading([weightKg doubleValue], (time_t)[time unsignedLongLongValue]);
}

- (void)accelerometerUpdated:(NSNotification*)notification
{
	if (IsActivityInProgress())
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
	NSDictionary* locationData = [notification object];

	NSNumber* lat = [locationData objectForKey:@KEY_NAME_LATITUDE];
	NSNumber* lon = [locationData objectForKey:@KEY_NAME_LONGITUDE];
	NSNumber* alt = [locationData objectForKey:@KEY_NAME_ALTITUDE];
	
	NSNumber* horizontalAccuracy = [locationData objectForKey:@KEY_NAME_HORIZONTAL_ACCURACY];
	NSNumber* verticalAccuracy = [locationData objectForKey:@KEY_NAME_VERTICAL_ACCURACY];

	NSNumber* gpsTimestampMs = [locationData objectForKey:@KEY_NAME_GPS_TIMESTAMP_MS];

	NSString* activityName = [self getCurrentActivityName];

	BOOL tempBadGps = FALSE;

	uint8_t minHAccuracy = [self->activityPrefs getMinGpsHorizontalAccuracy:activityName];
	if (minHAccuracy != (uint8_t)-1)
	{
		uint8_t accuracy = [[locationData objectForKey:@KEY_NAME_HORIZONTAL_ACCURACY] intValue];
		if (minHAccuracy != 0 && accuracy > minHAccuracy)
		{
			tempBadGps = TRUE;
		}
	}
	
	uint8_t minVAccuracy = [self->activityPrefs getMinGpsVerticalAccuracy:activityName];
	if (minVAccuracy != (uint8_t)-1)
	{
		uint8_t accuracy = [[locationData objectForKey:@KEY_NAME_VERTICAL_ACCURACY] intValue];
		if (minVAccuracy != 0 && accuracy > minVAccuracy)
		{
			tempBadGps = TRUE;
		}
	}
	
	self->badGps = tempBadGps;

	if (IsActivityInProgress())
	{
		uint8_t freq = [self->activityPrefs getGpsSampleFrequency:activityName];
		time_t nextUpdateTimeSec = self->lastLocationUpdateTime + freq;
		time_t currentTimeSec = (time_t)([gpsTimestampMs longLongValue] / 1000);

		if (currentTimeSec >= nextUpdateTimeSec)
		{
			BOOL shouldProcessReading = TRUE;
			GpsFilterOption filterOption = [self->activityPrefs getGpsFilterOption:activityName];

			if (filterOption == GPS_FILTER_DROP && self->badGps)
			{
				shouldProcessReading = FALSE;
			}

			if (shouldProcessReading)
			{
				ProcessGpsReading([lat doubleValue], [lon doubleValue], [alt doubleValue], [horizontalAccuracy doubleValue], [verticalAccuracy doubleValue], [gpsTimestampMs longLongValue]);
			}

			if (self->shouldTweetSplitTimes)
			{
				ActivityAttributeType distance = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED);
				ActivityAttributeType prevDistance = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_PREVIOUS_DISTANCE_TRAVELED);

				if ((unsigned long)prevDistance.value.doubleVal < (unsigned long)distance.value.doubleVal)
				{
					char* pPostStr = GetSocialNetworkSplitPostStr();
					if (pPostStr)
					{
						NSString* postStr = [NSString stringWithFormat:@"%s", pPostStr];
						if (postStr != nil)
						{
							[self->cloudMgr postUpdate:postStr];
						}
						free((void*)pPostStr);
					}
				}
			}

			self->lastLocationUpdateTime = currentTimeSec;
		}
	}
}

- (void)heartRateUpdated:(NSNotification*)notification
{
	if (IsActivityInProgress())
	{
		NSDictionary* heartRateData = [notification object];

		CBPeripheral* peripheral = [heartRateData objectForKey:@KEY_NAME_HRM_PERIPHERAL_OBJ];
		NSString* idStr = [[peripheral identifier] UUIDString];
		if ([Preferences shouldUsePeripheral:idStr])
		{
			NSNumber* timestampMs = [heartRateData objectForKey:@KEY_NAME_HRM_TIMESTAMP_MS];

			uint8_t freq = [self->activityPrefs getHeartRateSampleFrequency:[self getCurrentActivityName]];
			time_t nextUpdateTimeSec = self->lastHeartRateUpdateTime + freq;
			time_t currentTimeSec = (time_t)([timestampMs longLongValue] / 1000);

			if (currentTimeSec >= nextUpdateTimeSec)
			{
				NSNumber* rate = [heartRateData objectForKey:@KEY_NAME_HEART_RATE];
				if (rate)
				{
					ProcessHrmReading([rate doubleValue], [timestampMs longLongValue]);
					self->lastHeartRateUpdateTime = currentTimeSec;

					if (self->healthMgr)
					{
						[self->healthMgr saveHeartRateIntoHealthStore:[rate doubleValue]];
					}
				}
			}
		}
	}
}

- (void)cadenceUpdated:(NSNotification*)notification
{
	if (IsActivityInProgress())
	{
		NSDictionary* cadenceData = [notification object];

		CBPeripheral* peripheral = [cadenceData objectForKey:@KEY_NAME_WSC_PERIPHERAL_OBJ];
		NSString* idStr = [[peripheral identifier] UUIDString];
		if ([Preferences shouldUsePeripheral:idStr])
		{
			NSNumber* timestampMs = [cadenceData objectForKey:@KEY_NAME_CADENCE_TIMESTAMP_MS];

			uint8_t freq = [self->activityPrefs getCadenceSampleFrequency:[self getCurrentActivityName]];
			time_t nextUpdateTimeSec = self->lastCadenceUpdateTime + freq;
			time_t currentTimeSec = (time_t)([timestampMs longLongValue] / 1000);

			if (currentTimeSec >= nextUpdateTimeSec)
			{
				NSNumber* rate = [cadenceData objectForKey:@KEY_NAME_CADENCE];
				if (rate)
				{
					ProcessCadenceReading([rate doubleValue], [timestampMs longLongValue]);
					self->lastCadenceUpdateTime = currentTimeSec;
				}
			}
		}
	}
}

- (void)wheelSpeedUpdated:(NSNotification*)notification
{
	if (IsActivityInProgress())
	{
		NSDictionary* wheelSpeedData = [notification object];

		CBPeripheral* peripheral = [wheelSpeedData objectForKey:@KEY_NAME_WSC_PERIPHERAL_OBJ];
		NSString* idStr = [[peripheral identifier] UUIDString];
		if ([Preferences shouldUsePeripheral:idStr])
		{
			NSNumber* timestampMs = [wheelSpeedData objectForKey:@KEY_NAME_WHEEL_SPEED_TIMESTAMP_MS];

			uint8_t freq = [self->activityPrefs getWheelSpeedSampleFrequency:[self getCurrentActivityName]];
			time_t nextUpdateTimeSec = self->lastWheelSpeedUpdateTime + freq;
			time_t currentTimeSec = (time_t)([timestampMs longLongValue] / 1000);

			if (currentTimeSec >= nextUpdateTimeSec)
			{
				NSNumber* count = [wheelSpeedData objectForKey:@KEY_NAME_WHEEL_SPEED];
				if (count)
				{
					ProcessWheelSpeedReading([count doubleValue], [timestampMs longLongValue]);
					self->lastWheelSpeedUpdateTime = currentTimeSec;
				}
			}
		}
	}
}

- (void)powerUpdated:(NSNotification*)notification
{
	if (IsActivityInProgress())
	{
		NSDictionary* powerData = [notification object];

		CBPeripheral* peripheral = [powerData objectForKey:@KEY_NAME_POWER_PERIPHERAL_OBJ];
		NSString* idStr = [[peripheral identifier] UUIDString];
		if ([Preferences shouldUsePeripheral:idStr])
		{
			NSNumber* timestampMs = [powerData objectForKey:@KEY_NAME_POWER_TIMESTAMP_MS];

			uint8_t freq = [self->activityPrefs getPowerSampleFrequency:[self getCurrentActivityName]];
			time_t nextUpdateTimeSec = self->lastPowerUpdateTime + freq;
			time_t currentTimeSec = (time_t)([timestampMs longLongValue] / 1000);
			
			if (currentTimeSec >= nextUpdateTimeSec)
			{
				NSNumber* watts = [powerData objectForKey:@KEY_NAME_POWER];
				if (watts)
				{
					ProcessPowerMeterReading([watts doubleValue], [timestampMs longLongValue]);
					self->lastPowerUpdateTime = currentTimeSec;
				}
			}
		}
	}
}

- (void)strideLengthUpdated:(NSNotification*)notification
{
	if (IsActivityInProgress())
	{
		NSDictionary* strideData = [notification object];

		CBPeripheral* peripheral = [strideData objectForKey:@KEY_NAME_FOOT_POD_PERIPHERAL_OBJ];
		NSString* idStr = [[peripheral identifier] UUIDString];
		if ([Preferences shouldUsePeripheral:idStr])
		{
			NSNumber* value = [strideData objectForKey:@KEY_NAME_STRIDE_LENGTH];
			NSNumber* timestampMs = [strideData objectForKey:@KEY_NAME_STRIDE_LENGTH_TIMESTAMP_MS];
			if (value)
			{
				ProcessRunStrideLengthReading([value doubleValue], [timestampMs longLongValue]);
			}
		}
	}
}

- (void)runDistanceUpdated:(NSNotification*)notification
{
	if (IsActivityInProgress())
	{
		NSDictionary* distanceData = [notification object];

		CBPeripheral* peripheral = [distanceData objectForKey:@KEY_NAME_FOOT_POD_PERIPHERAL_OBJ];
		NSString* idStr = [[peripheral identifier] UUIDString];
		if ([Preferences shouldUsePeripheral:idStr])
		{
			NSNumber* value = [distanceData objectForKey:@KEY_NAME_RUN_DISTANCE];
			NSNumber* timestampMs = [distanceData objectForKey:@KEY_NAME_RUN_DISTANCE_TIMESTAMP_MS];
			if (value)
			{
				ProcessRunDistanceReading([value doubleValue], [timestampMs longLongValue]);
			}
		}
	}
}

#pragma mark methods for managing intervals

- (void)onIntervalTimer:(NSTimer*)timer
{
	if (CheckCurrentIntervalWorkout())
	{
		if (IsIntervalWorkoutComplete())
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_INTERVAL_COMPLETE object:nil];
		}
		else
		{
			uint32_t quantity;
			IntervalUnit units;

			if (GetCurrentIntervalWorkoutSegment(&quantity, &units))
			{
				NSDictionary* intervalData = [[NSDictionary alloc] initWithObjectsAndKeys:
											  [NSNumber numberWithLong:quantity], @KEY_NAME_INTERVAL_QUANTITY,
											  [NSNumber numberWithLong:units], @KEY_NAME_INTERVAL_UNITS,
											  nil];
				if (intervalData)
				{
					[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_INTERVAL_UPDATED object:intervalData];
				}
			}
		}

		[self playPingSound];
	}
}

- (void)startInteralTimer
{
	self->intervalTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow: 1.0]
												   interval:1
													 target:self
												   selector:@selector(onIntervalTimer:)
												   userInfo:nil
													repeats:YES];
	
	NSRunLoop* runner = [NSRunLoop currentRunLoop];
	if (runner)
	{
		[runner addTimer:self->intervalTimer forMode: NSDefaultRunLoopMode];
	}
}

#pragma mark methods for starting and stopping activities, etc.

- (BOOL)startActivity
{
	BOOL result = StartActivity();
	if (result)
	{
		if ([Preferences shouldTweetWorkoutStart])
		{
			char* pPostStr = GetSocialNetworkStartingPostStr();
			if (pPostStr != nil)
			{
				NSString* postStr = [NSString stringWithFormat:@"%s", pPostStr];
				if (postStr != nil)
				{
					[self->cloudMgr postUpdate:postStr];
				}
				free((void*)pPostStr);
			}
		}

		ActivityAttributeType startTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_START_TIME);
		NSString* activityName = [self getCurrentActivityName];

		NSDictionary* startData = [[NSDictionary alloc] initWithObjectsAndKeys:
								   [NSNumber numberWithLongLong:GetCurrentActivityId()],@KEY_NAME_ACTIVITY_ID,
								   activityName,@KEY_NAME_ACTIVITY_NAME,
								   [NSNumber numberWithLongLong:startTime.value.intVal],@KEY_NAME_START_TIME,
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
	uint64_t activityId = GetCurrentActivityId();

	BOOL result = StopCurrentActivity();
	if (result)
	{
		ActivityAttributeType startTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_START_TIME);
		ActivityAttributeType endTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_END_TIME);
		ActivityAttributeType distance = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED);
		ActivityAttributeType calories = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_CALORIES_BURNED);
		NSString* activityName = [self getCurrentActivityName];
		
		SaveActivitySummaryData();

		if ([Preferences shouldTweetWorkoutStop])
		{
			char* pPostStr = GetSocialNetworkStoppingPostStr();
			if (pPostStr != nil)
			{
				NSString* postStr = [NSString stringWithFormat:@"%s", pPostStr];
				if (postStr != nil)
				{
					[self->cloudMgr postUpdate:postStr];
				}
				free((void*)pPostStr);
			}
		}

		NSDictionary* stopData = [[NSDictionary alloc] initWithObjectsAndKeys:
								  [NSNumber numberWithLongLong:activityId],@KEY_NAME_ACTIVITY_ID,
								  activityName,@KEY_NAME_ACTIVITY_NAME,
								  [NSNumber numberWithLongLong:startTime.value.intVal],@KEY_NAME_START_TIME,
								  [NSNumber numberWithLongLong:endTime.value.intVal],@KEY_NAME_END_TIME,
								  [NSNumber numberWithDouble:distance.value.doubleVal],@KEY_NAME_DISTANCE,
								  [NSNumber numberWithDouble:calories.value.doubleVal],@KEY_NAME_CALORIES,
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

- (BOOL)loadHistoricalActivity:(NSInteger)activityIndex
{
	BOOL result = FALSE;

	LoadHistoricalActivitySummaryData(activityIndex);
	CreateHistoricalActivityObject(activityIndex);

	if (LoadAllHistoricalActivitySensorData(activityIndex))
	{
		time_t startTime = 0;
		time_t endTime = 0;

		GetHistoricalActivityStartAndEndTime(activityIndex, &startTime, &endTime);
		if (endTime == 0)
		{
			FixHistoricalActivityEndTime(activityIndex);
		}

		if (SaveHistoricalActivitySummaryData(activityIndex))
		{
			LoadHistoricalActivitySummaryData(activityIndex);
			LoadHistoricalActivityLapData(activityIndex);
			
			result = TRUE;
		}
	}
	return result;
}

- (void)recreateOrphanedActivity:(NSInteger)activityIndex
{
	DestroyCurrentActivity();
	ReCreateOrphanedActivity(activityIndex);
}

#pragma mark sound methods

- (void)playSound:(NSString*)soundPath
{
	NSURL* mySoundUrl = [NSURL fileURLWithPath:soundPath];
	if (mySoundUrl)
	{
		SystemSoundID mySoundId;
		AudioServicesCreateSystemSoundID((__bridge CFURLRef)mySoundUrl, &mySoundId);
		AudioServicesPlaySystemSound(mySoundId);
	}
}

- (void)playBeepSound
{
	NSString* mySoundPath = [[NSBundle mainBundle] pathForResource:@"Beep" ofType:@"aif"];
	if (mySoundPath)
	{
		[self playSound:mySoundPath];
	}
}

- (void)playPingSound
{
	NSString* mySoundPath = [[NSBundle mainBundle] pathForResource:@"Ping" ofType:@"aif"];
	if (mySoundPath)
	{
		[self playSound:mySoundPath];
	}
}

#pragma mark method for downloading a map overlay

- (NSString*)getOverlayDir
{
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [[paths objectAtIndex: 0] stringByAppendingPathComponent:@MAP_OVERLAY_DIR_NAME];
}

- (NSString*)createOverlayDir
{
	NSString* overlayDir = [self getOverlayDir];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:overlayDir])
	{
		NSError* error = nil;
		
		if (![[NSFileManager defaultManager] createDirectoryAtPath:overlayDir withIntermediateDirectories:NO attributes:nil error:&error])
		{
			return nil;
		}
	}
	return overlayDir;
}

- (BOOL)downloadMapOverlay:(NSString*)urlStr withName:(NSString*)name
{
	NSURL* url = [NSURL URLWithString:urlStr];
	NSData* urlData = [NSData dataWithContentsOfURL:url];
	if (urlData)
	{
		NSString* overlayDir = [self createOverlayDir];
		NSString* theFileName = [[urlStr lastPathComponent] stringByDeletingPathExtension];
		NSString* filePath = [NSString stringWithFormat:@"%@/%@", overlayDir, theFileName];
		return [urlData writeToFile:filePath atomically:YES];
	}
	return FALSE;
}

- (BOOL)downloadActivity:(NSString*)urlStr withActivityName:(NSString*)activityName
{
	NSURL* url = [NSURL URLWithString:urlStr];
	NSData* urlData = [NSData dataWithContentsOfURL:url];
	if (urlData)
	{
		NSString* fileName = [urlStr lastPathComponent];
		NSString* filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
		if ([urlData writeToFile:filePath atomically:YES])
		{
			BOOL result = ImportActivityFromFile([filePath UTF8String], [activityName UTF8String]);
			[self deleteFile:filePath];
			return result;
		}
	}
	return FALSE;
}

#pragma mark methods for exporting activities

- (BOOL)deleteFile:(NSString*)fileName
{
	NSError* error;
	NSFileManager* fileMgr = [NSFileManager defaultManager];
	return [fileMgr removeItemAtPath:fileName error:&error] == YES;
}

- (NSString*)createExportDir
{
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* exportDir = [[paths objectAtIndex: 0] stringByAppendingPathComponent:@"Export"];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:exportDir])
	{
		NSError* error = nil;
		
		if (![[NSFileManager defaultManager] createDirectoryAtPath:exportDir withIntermediateDirectories:NO attributes:nil error:&error])
		{
			return nil;
		}
	}
	return exportDir;
}

- (NSString*)exportActivity:(uint64_t)activityId withFileFormat:(FileFormat)format to:selectedExportLocation
{
	NSString* exportFileName = nil;
	NSString* exportDir = [self createExportDir];
	char* tempExportFileName = ExportActivity(activityId, format, [exportDir UTF8String]);
	if (tempExportFileName)
	{
		exportFileName = [[NSString alloc] initWithFormat:@"%s", tempExportFileName];
		free((void*)tempExportFileName);
	}
	return exportFileName;
}

- (NSString*)exportActivitySummary:(NSString*)activityName
{	
	NSString* exportFileName = nil;
	NSString* exportDir = [self createExportDir];
	char* tempExportFileName = ExportActivitySummary([activityName UTF8String], [exportDir UTF8String]);
	if (tempExportFileName)
	{
		exportFileName = [[NSString alloc] initWithFormat:@"%s", tempExportFileName];
		free((void*)tempExportFileName);
	}
	return exportFileName;
}

- (void)clearExportDir
{
	NSString* exportDir = [self createExportDir];
	NSError* error;
	NSArray* directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:exportDir error:&error];
	for (NSString* file in directoryContents)
	{
		NSString* filePath = [[NSString alloc] initWithFormat:@"%@/%@", exportDir, file];
		[self deleteFile:filePath];
	}
}

- (NSMutableArray*)getEnabledFileImportCloudServices
{
	NSMutableArray* services = [[NSMutableArray alloc] init];
	if (services)
	{
		if ([self isFeatureEnabled:FEATURE_DROPBOX])
		{
			[services addObject:[self->cloudMgr nameOf:CLOUD_SERVICE_DROPBOX]];
		}
	}
	return services;
}

- (NSMutableArray*)getEnabledFileImportServices
{
	NSMutableArray* services = [self getEnabledFileImportCloudServices];
	if (services)
	{
		[services addObject:@IMPORT_VIA_URL_STR];
	}
	return services;
}

- (NSMutableArray*)getEnabledFileExportCloudServices
{
	NSMutableArray* services = [[NSMutableArray alloc] init];
	if (services)
	{
		if ([self isFeatureEnabled:FEATURE_DROPBOX])
		{
			[services addObject:[self->cloudMgr nameOf:CLOUD_SERVICE_DROPBOX]];
		}
		if ([self isFeatureEnabled:FEATURE_RUNKEEPER])
		{
			[services addObject:[self->cloudMgr nameOf:CLOUD_SERVICE_RUNKEEPER]];
		}
		if ([self isFeatureEnabled:FEATURE_STRAVA])
		{
			[services addObject:[self->cloudMgr nameOf:CLOUD_SERVICE_STRAVA]];
		}
	}
	return services;
}

- (NSMutableArray*)getEnabledFileExportServices
{
	NSMutableArray* services = [self getEnabledFileExportCloudServices];
	if (services)
	{
		[services addObject:@EXPORT_TO_EMAIL_STR];
	}
	return services;
}

#pragma mark methods for managing map overlays

- (NSMutableArray*)getMapOverlayList
{
	NSMutableArray* pOverlays = [[NSMutableArray alloc] init];
	if (pOverlays)
	{
		NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString* overlaysDir = [[paths objectAtIndex: 0] stringByAppendingPathComponent:@MAP_OVERLAY_DIR_NAME];
		NSFileManager* fm = [NSFileManager defaultManager];
		NSArray* files = [fm contentsOfDirectoryAtPath:overlaysDir error:nil];
		for (NSString* file in files)
		{
			if ([file characterAtIndex:0] != '.')
			{
				NSString* fullPath = [overlaysDir stringByAppendingPathComponent:file];
				[pOverlays addObject:fullPath];
			}
		}
	}
	return pOverlays;
}

#pragma mark methods for managing bikes

- (void)setBikeForCurrentActivity:(NSString*)bikeName
{
	uint64_t bikeId = 0;
	double weightKg = (double)0.0;
	double wheelSize = (double)0.0;

	if (GetBikeProfileByName([bikeName UTF8String], &bikeId, &weightKg, &wheelSize))
	{
		uint64_t activityId = GetCurrentActivityId();
		SetActivityBikeProfile(bikeId, activityId);
	}
}

- (void)setBikeForActivityId:(NSString*)bikeName withActivityId:(uint64_t)activityId
{
	uint64_t bikeId = 0;
	double weightKg = (double)0.0;
	double wheelSize = (double)0.0;
	
	if (GetBikeProfileByName([bikeName UTF8String], &bikeId, &weightKg, &wheelSize))
	{
		SetActivityBikeProfile(bikeId, activityId);
	}
}

- (uint64_t)getBikeIdFromName:(NSString*)bikeName
{
	return GetBikeIdFromName([bikeName UTF8String]);
}

- (BOOL)deleteBikeProfile:(uint64_t)bikeId
{
	return DeleteBikeProfile(bikeId);
}

#pragma mark accessor methods

void tagCallback(const char* name, void* context)
{
	NSMutableArray* names = (__bridge NSMutableArray*)context;
	[names addObject:[[NSString alloc] initWithUTF8String:name]];
}

- (NSMutableArray*)getTagsForActivity:(uint64_t)activityId
{
	NSMutableArray* names = [[NSMutableArray alloc] init];
	if (names)
	{
		GetTags(activityId, tagCallback, (__bridge void*)names);
	}
	return names;
}

- (NSMutableArray*)getBikeNames
{
	NSMutableArray* names = [[NSMutableArray alloc] init];
	if (names)
	{
		char* bikeName = NULL;
		size_t bikeIndex = 0;
		uint64_t bikeId = 0;
		double weightKg = (double)0.0;
		double wheelCircumference = (double)0.0;

		InitializeBikeProfileList();
		while (GetBikeProfileByIndex(bikeIndex++, &bikeName, &bikeId, &weightKg, &wheelCircumference))
		{
			[names addObject:[[NSString alloc] initWithUTF8String:bikeName]];
			free((void*)bikeName);
		}
	}
	return names;
}

- (NSMutableArray*)getIntervalWorkoutNames
{
	NSMutableArray* names = [[NSMutableArray alloc] init];
	if (names)
	{
		char* workoutName = NULL;
		size_t index = 0;

		InitializeIntervalWorkoutList();
		while ((workoutName = GetIntervalWorkoutName(index++)) != NULL)
		{
			[names addObject:[[NSString alloc] initWithUTF8String:workoutName]];
			free((void*)workoutName);
		}
	}
	return names;
}

void activityNameCallback(const char* name, void* context)
{
	NSMutableArray* names = (__bridge NSMutableArray*)context;
	[names addObject:[[NSString alloc] initWithUTF8String:name]];
}

- (NSMutableArray*)getActivityTypeNames
{
	NSMutableArray* names = [[NSMutableArray alloc] init];
	if (names)
	{
		GetActivityTypeNames(activityNameCallback, (__bridge void*)names);
	}
	return names;
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

- (NSString*)getCurrentActivityName
{
	NSString* activityNameStr = nil;
	char* activityName = GetCurrentActivityName();
	if (activityName)
	{
		activityNameStr = [NSString stringWithFormat:@"%s", activityName];
		free((void*)activityName);
	}
	return activityNameStr;
}

- (NSString*)getHistorialActivityName:(NSInteger)activityIndex
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

#pragma mark utility methods

- (void)setScreenLocking
{
	NSString* activityName = [self getCurrentActivityName];
	BOOL screenLocking = [activityPrefs getScreenAutoLocking:activityName];
	[UIApplication sharedApplication].idleTimerDisabled = !screenLocking;
}

- (BOOL)hasBadGps
{
	return self->badGps;
}

#pragma mark cloud methods

- (NSMutableArray*)listFileClouds
{
	return [self->cloudMgr listFileClouds];
}

- (NSMutableArray*)listDataClouds
{
	return [self->cloudMgr listDataClouds];
}

- (NSMutableArray*)listSocialClouds
{
	return [self->cloudMgr listSocialClouds];
}

- (BOOL)isCloudServiceLinked:(CloudServiceType)service
{
	return [self->cloudMgr isLinked:service];
}

- (NSString*)nameOfCloudService:(CloudServiceType)service
{
	return [self->cloudMgr nameOf:service];
}

- (void)requestCloudServiceAcctNames:(CloudServiceType)service
{
	[self->cloudMgr requestCloudServiceAcctNames:service];
}

#pragma mark NSURLConnectionDataDelegate methods

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
	NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
	[self->downloadedData setObject:[[NSNumber alloc] initWithInteger:[httpResponse statusCode]] forKey:@KEY_NAME_RESPONSE_CODE];
	[self->downloadedData setObject:[[NSMutableData alloc] init] forKey:@KEY_NAME_DATA];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
	NSString* url = [self->downloadedData objectForKey:@KEY_NAME_URL];

	if ([url rangeOfString:@BROADCAST_LOGIN_URL].location != NSNotFound)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_LOGIN_PROCESSED object:self->downloadedData];
	}
	else if ([url rangeOfString:@BROADCAST_CREATE_LOGIN_URL].location != NSNotFound)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_CREATE_LOGIN_PROCESSED object:self->downloadedData];
	}
	else if ([url rangeOfString:@BROADCAST_LIST_FOLLOWING].location != NSNotFound)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_FOLLOWING_LIST_UPDATED object:self->downloadedData];
	}
	else if ([url rangeOfString:@BROADCAST_LIST_FOLLOWED_BY].location != NSNotFound)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_FOLLOWED_BY_LIST_UPDATED object:self->downloadedData];
	}
	else if ([url rangeOfString:@BROADCAST_INVITE_TO_FOLLOW].location != NSNotFound)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_INVITE_TO_FOLLOW_RESULT object:self->downloadedData];
	}
	else if ([url rangeOfString:@BROADCAST_REQUEST_TO_FOLLOW].location != NSNotFound)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_REQUEST_TO_FOLLOW_RESULT object:self->downloadedData];
	}

	self->downloadedData = nil;
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
	NSMutableData* dataObj = [self->downloadedData objectForKey:@KEY_NAME_DATA];
	[dataObj appendData:data];
}

- (NSCachedURLResponse*)connection:(NSURLConnection*)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
	// Return nil to indicate not necessary to store a cached response for this connection
	return nil;
}

#pragma mark broadcast options

- (BOOL)makeRequest:(NSString*)urlStr withMethod:(NSString*)method withPostData:(NSMutableData*)postData
{
	self->downloadedData = [[NSMutableDictionary alloc] init];
	[self->downloadedData setObject:urlStr forKey:@KEY_NAME_URL];

	NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:urlStr]];
	[request setHTTPMethod:method];

	if (postData)
	{
		NSString* postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
		[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody:postData];
	}

	NSURLConnection* conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	return conn != nil;
}

- (BOOL)login:(NSString*)username withPassword:(NSString*)password
{
	[Preferences setBroadcastUserName:username];
	
	NSString* post = [NSString stringWithFormat:@"{"];
	NSMutableData* postData = [[post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] mutableCopy];
	[postData appendData:[[NSString stringWithFormat:@"\"username\": \"%@\",", username] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"\"password\": \"%@\",", password] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"\"device\": \"%@\"", [Preferences uuid]] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"}"] dataUsingEncoding:NSASCIIStringEncoding]];

	NSString* urlStr = [NSString stringWithFormat:@"http://%@/%s", [Preferences broadcastHostName], BROADCAST_LOGIN_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:postData];
}

- (BOOL)createLogin:(NSString*)username withPassword:(NSString*)password1 withConfirmation:(NSString*)password2 withRealName:(NSString*)realname
{
	[Preferences setBroadcastUserName:username];
	
	NSString* post = [NSString stringWithFormat:@"{"];
	NSMutableData* postData = [[post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] mutableCopy];
	[postData appendData:[[NSString stringWithFormat:@"\"username\": \"%@\",", username] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"\"password1\": \"%@\",", password1] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"\"password2\": \"%@\",", password2] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"\"realname\": \"%@\",", realname] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"\"device\": \"%@\"", [Preferences uuid]] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"}"] dataUsingEncoding:NSASCIIStringEncoding]];
	
	NSString* urlStr = [NSString stringWithFormat:@"http://%@/%s", [Preferences broadcastHostName], BROADCAST_CREATE_LOGIN_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:postData];
}

- (BOOL)listFollowingAsync
{
	NSString* username = [Preferences broadcastUserName];
	NSString* params = [NSString stringWithFormat:@"username=%@", username];
	NSString* escapedParams = [params stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
	NSString* str = [NSString stringWithFormat:@"http://%@/%s%@", [Preferences broadcastHostName], BROADCAST_LIST_FOLLOWING, escapedParams];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
}

- (BOOL)listFollowedByAsync
{
	NSString* username = [Preferences broadcastUserName];
	NSString* params = [NSString stringWithFormat:@"username=%@", username];
	NSString* escapedParams = [params stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
	NSString* str = [NSString stringWithFormat:@"http://%@/%s%@", [Preferences broadcastHostName], BROADCAST_LIST_FOLLOWED_BY, escapedParams];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
}

- (BOOL)inviteToFollow:(NSString*)targetUsername
{
	NSString* username = [Preferences broadcastUserName];
	NSString* params = [NSString stringWithFormat:@"username=%@target_username=%@", username, targetUsername];
	NSString* escapedParams = [params stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
	NSString* str = [NSString stringWithFormat:@"http://%@/%s%@", [Preferences broadcastHostName], BROADCAST_INVITE_TO_FOLLOW, escapedParams];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
}

- (BOOL)requestToFollow:(NSString*)targetUsername
{
	NSString* username = [Preferences broadcastUserName];
	NSString* params = [NSString stringWithFormat:@"username=%@target_username=%@", username, targetUsername];
	NSString* escapedParams = [params stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
	NSString* str = [NSString stringWithFormat:@"http://%@/%s%@", [Preferences broadcastHostName], BROADCAST_REQUEST_TO_FOLLOW, escapedParams];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
}

#pragma mark reset methods

- (void)resetDatabase
{
	ResetDatabase();
}

- (void)resetPreferences
{
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
}

@end
