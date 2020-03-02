// Created by Michael Simms on 7/29/19.
// Copyright © 2019 Michael J Simms. All rights reserved.

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "ActivityAttribute.h"
#import "ActivityHash.h"
#import "ActivityMgr.h"
#import "HashUtils.h"
#import "StringUtils.h"

@implementation ActivityHash

- (id)init
{
	self = [super init];
	return self;
}

NSString* NumToStringForHashing(NSNumber* num)
{
	NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[formatter setPaddingCharacter:@"0"];
	[formatter setMinimumFractionDigits:6];
	[formatter setMaximumFractionDigits:6];
	return [formatter stringFromNumber:num];
}

void GpsDataHashCallback(const char* activityId, void* context)
{
	ActivityAttributeType latValue = QueryHistoricalActivityAttributeById(activityId, ACTIVITY_ATTRIBUTE_LATITUDE);
	ActivityAttributeType lonValue = QueryHistoricalActivityAttributeById(activityId, ACTIVITY_ATTRIBUTE_LONGITUDE);
	ActivityAttributeType altValue = QueryHistoricalActivityAttributeById(activityId, ACTIVITY_ATTRIBUTE_ALTITUDE);

	if (latValue.valid && lonValue.valid && altValue.valid)
	{
		CC_SHA512_CTX* ctx = (CC_SHA512_CTX*)context;

		NSNumber* time = [NSNumber numberWithLongLong:latValue.startTime];
		NSNumber* latitude = [NSNumber numberWithDouble:latValue.value.doubleVal];
		NSNumber* longitude = [NSNumber numberWithDouble:lonValue.value.doubleVal];
		NSNumber* altitude = [NSNumber numberWithDouble:altValue.value.doubleVal];
		
		NSString* timeStr = [time stringValue];
		NSString* latitudeStr = NumToStringForHashing(latitude);
		NSString* longitudeStr = NumToStringForHashing(longitude);
		NSString* altitudeStr = NumToStringForHashing(altitude);
		
		CC_SHA512_Update(ctx, [timeStr UTF8String], (CC_LONG)[timeStr length]);
		CC_SHA512_Update(ctx, [latitudeStr UTF8String], (CC_LONG)[latitudeStr length]);
		CC_SHA512_Update(ctx, [longitudeStr UTF8String], (CC_LONG)[longitudeStr length]);
		CC_SHA512_Update(ctx, [altitudeStr UTF8String], (CC_LONG)[altitudeStr length]);
	}
}

void AccelDataHashCallback(const char* activityId, void* context)
{
	ActivityAttributeType xAxisValue = QueryHistoricalActivityAttributeById(activityId, ACTIVITY_ATTRIBUTE_X);
	ActivityAttributeType yAxisValue = QueryHistoricalActivityAttributeById(activityId, ACTIVITY_ATTRIBUTE_Y);
	ActivityAttributeType zAxisValue = QueryHistoricalActivityAttributeById(activityId, ACTIVITY_ATTRIBUTE_Z);

	if (xAxisValue.valid && yAxisValue.valid && zAxisValue.valid)
	{
		CC_SHA512_CTX* ctx = (CC_SHA512_CTX*)context;

		NSNumber* time = [NSNumber numberWithLongLong:xAxisValue.startTime];
		NSNumber* xAxisValueNum = [NSNumber numberWithDouble:xAxisValue.value.doubleVal];
		NSNumber* yAxisValueNum = [NSNumber numberWithDouble:yAxisValue.value.doubleVal];
		NSNumber* zAxisValueNum = [NSNumber numberWithDouble:zAxisValue.value.doubleVal];

		NSString* timeStr = [time stringValue];
		NSString* xAxisValueStr = NumToStringForHashing(xAxisValueNum);
		NSString* yAxisValueStr = NumToStringForHashing(yAxisValueNum);
		NSString* zAxisValueStr = NumToStringForHashing(zAxisValueNum);

		CC_SHA512_Update(ctx, [timeStr UTF8String], (CC_LONG)[timeStr length]);
		CC_SHA512_Update(ctx, [xAxisValueStr UTF8String], (CC_LONG)[xAxisValueStr length]);
		CC_SHA512_Update(ctx, [yAxisValueStr UTF8String], (CC_LONG)[yAxisValueStr length]);
		CC_SHA512_Update(ctx, [zAxisValueStr UTF8String], (CC_LONG)[zAxisValueStr length]);
	}
}

void CadenceDataHashCallback(const char* activityId, void* context)
{
	ActivityAttributeType cadenceValue = QueryHistoricalActivityAttributeById(activityId, ACTIVITY_ATTRIBUTE_CADENCE);
	if (cadenceValue.valid)
	{
		CC_SHA512_CTX* ctx = (CC_SHA512_CTX*)context;

		NSNumber* time = [NSNumber numberWithLongLong:cadenceValue.startTime];
		NSNumber* cadence = [NSNumber numberWithDouble:cadenceValue.value.doubleVal];

		NSString* timeStr = [time stringValue];
		NSString* cadenceStr = [cadence stringValue];

		CC_SHA512_Update(ctx, [timeStr UTF8String], (CC_LONG)[timeStr length]);
		CC_SHA512_Update(ctx, [cadenceStr UTF8String], (CC_LONG)[cadenceStr length]);
	}
}

void HeartRateDataHashCallback(const char* activityId, void* context)
{
	ActivityAttributeType hrValue = QueryHistoricalActivityAttributeById(activityId, ACTIVITY_ATTRIBUTE_HEART_RATE);
	if (hrValue.valid)
	{
		CC_SHA512_CTX* ctx = (CC_SHA512_CTX*)context;

		NSNumber* time = [NSNumber numberWithLongLong:hrValue.startTime];
		NSNumber* hr = [NSNumber numberWithDouble:hrValue.value.doubleVal];

		NSString* timeStr = [time stringValue];
		NSString* hrStr = [hr stringValue];

		CC_SHA512_Update(ctx, [timeStr UTF8String], (CC_LONG)[timeStr length]);
		CC_SHA512_Update(ctx, [hrStr UTF8String], (CC_LONG)[hrStr length]);
	}
}

void PowerDataHashCallback(const char* activityId, void* context)
{
	ActivityAttributeType powerValue = QueryHistoricalActivityAttributeById(activityId, ACTIVITY_ATTRIBUTE_POWER);
	if (powerValue.valid)
	{
		CC_SHA512_CTX* ctx = (CC_SHA512_CTX*)context;

		NSNumber* time = [NSNumber numberWithLongLong:powerValue.startTime];
		NSNumber* power = [NSNumber numberWithDouble:powerValue.value.doubleVal];

		NSString* timeStr = [time stringValue];
		NSString* powerStr = [power stringValue];

		CC_SHA512_Update(ctx, [timeStr UTF8String], (CC_LONG)[timeStr length]);
		CC_SHA512_Update(ctx, [powerStr UTF8String], (CC_LONG)[powerStr length]);
	}
}

- (NSString*)calculateWithActivityId:(NSString*)activityId
{
	CC_SHA512_CTX ctx;

	InitializeHistoricalActivityList();
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	// Initialize the context.
	CC_SHA512_Init(&ctx);

	// Load the data.
	CreateHistoricalActivityObject(activityIndex);

	// Hash the locations.
	LoadHistoricalActivitySensorData(activityIndex, SENSOR_TYPE_LOCATION, GpsDataHashCallback, (void*)&ctx);

	// Hash the sensor data - accelerometer.
	LoadHistoricalActivitySensorData(activityIndex, SENSOR_TYPE_ACCELEROMETER, AccelDataHashCallback, (void*)&ctx);

	// Hash the sensor data - cadence.
	LoadHistoricalActivitySensorData(activityIndex, SENSOR_TYPE_CADENCE, CadenceDataHashCallback, (void*)&ctx);
	
	// Hash the sensor data - heart rate.
	LoadHistoricalActivitySensorData(activityIndex, SENSOR_TYPE_HEART_RATE, HeartRateDataHashCallback, (void*)&ctx);
	
	// Hash the sensor data - power.
	LoadHistoricalActivitySensorData(activityIndex, SENSOR_TYPE_POWER, PowerDataHashCallback, (void*)&ctx);
	
	// Compute the hash.
	uint8_t digest[CC_SHA512_DIGEST_LENGTH] = {0};
	CC_SHA512_Final(digest, &ctx);

	// Convert to a string.
	NSData* data = [NSData dataWithBytes:digest length:CC_SHA512_DIGEST_LENGTH];
	return [StringUtils bytesToHexStr:data];
}

@end
