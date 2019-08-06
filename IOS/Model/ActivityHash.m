// Created by Michael Simms on 7/29/19.
// Copyright © 2019 Michael J Simms. All rights reserved.

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "ActivityHash.h"
#import "HashUtils.h"

@implementation ActivityHash

- (NSString*)calculate:(NSString*)activityId
{
	// Hash the locations.
	
	// Hash the sensor data.

	uint8_t digest[CC_SHA512_DIGEST_LENGTH] = {0};
	//CC_SHA512(byteData.bytes, (CC_LONG)byteData.length, digest);
	
	NSData* data = [NSData dataWithBytes:digest length:CC_SHA512_DIGEST_LENGTH];
	return [data description];
}

@end
