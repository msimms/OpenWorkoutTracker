// Created by Michael Simms on 7/29/19.
// Copyright © 2019 Michael J Simms. All rights reserved.

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "ActivityAttribute.h"
#import "ActivityHash.h"
#import "ActivityMgr.h"
#import "HashUtils.h"

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

void GpsDataHashCallback(size_t activityIndex, void* context)
{
	ActivityAttributeType latValue = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_LATITUDE);
	ActivityAttributeType lonValue = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_LONGITUDE);
	ActivityAttributeType altValue = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_ALTITUDE);

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

void AccelDataHashCallback(size_t activityIndex, void* context)
{
	ActivityAttributeType xAxisValue;
	ActivityAttributeType yAxisValue;
	ActivityAttributeType zAxisValue;

	xAxisValue = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_X);
	yAxisValue = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_Y);
	zAxisValue = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_Z);

	if (xAxisValue.valid && yAxisValue.valid && zAxisValue.valid)
	{
		CC_SHA512_CTX* ctx = (CC_SHA512_CTX*)context;

		NSNumber* time = [NSNumber numberWithLongLong:xAxisValue.startTime];
		NSString* timeStr = [time stringValue];

		CC_SHA512_Update(ctx, [timeStr UTF8String], (CC_LONG)[timeStr length]);
	}
}

void CadenceDataHashCallback(size_t activityIndex, void* context)
{
	ActivityAttributeType cadenceValue = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_CADENCE);
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

void HeartRateDataHashCallback(size_t activityIndex, void* context)
{
	ActivityAttributeType hrValue = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_HEART_RATE);
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

void PowerDataHashCallback(size_t activityIndex, void* context)
{
	ActivityAttributeType powerValue = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_POWER);
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

- (NSString*)calculateWithActivityIndex:(size_t)activityIndex
{
	CC_SHA512_CTX ctx;
	
	// Initialize the context.
	CC_SHA512_Init(&ctx);

	// Load the data.
	CreateHistoricalActivityObject(activityIndex);

	// Hash the locations.
	LoadHistoricalActivitySensorData(activityIndex, SENSOR_TYPE_GPS, GpsDataHashCallback, (void*)&ctx);

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
	
	NSData* data = [NSData dataWithBytes:digest length:CC_SHA512_DIGEST_LENGTH];
	return [data description];
}

- (NSString*)calculateWithActivityId:(NSString*)activityId
{
	InitializeHistoricalActivityList();
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);
	return [self calculateWithActivityIndex:activityIndex];
}

@end
