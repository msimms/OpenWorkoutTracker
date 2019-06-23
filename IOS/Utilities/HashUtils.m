// Created by Michael Simms on 6/21/19.
// Copyright © 2019 Michael J Simms Software. All rights reserved.

#include <CommonCrypto/CommonDigest.h>

#import "HashUtils.h"

@implementation HashUtils

+ (NSString*)createSHA512:(NSString*)source
{
	const char* strData = [source cStringUsingEncoding:NSASCIIStringEncoding];
	NSData* byteData = [NSData dataWithBytes:strData length:strlen(strData)];

	uint8_t digest[CC_SHA512_DIGEST_LENGTH] = {0};
	CC_SHA512(byteData.bytes, byteData.length, digest);

	NSData* data = [NSData dataWithBytes:digest length:CC_SHA512_DIGEST_LENGTH];
	return [data description];
}

@end
