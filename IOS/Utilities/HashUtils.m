// Created by Michael Simms on 6/21/19.
// Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <CommonCrypto/CommonDigest.h>
#import "HashUtils.h"

@implementation HashUtils

+ (NSString*)createSHA512:(NSString*)source
{
	const char* strData = [source cStringUsingEncoding:NSASCIIStringEncoding];
	NSData* byteData = [NSData dataWithBytes:strData length:strlen(strData)];

	uint8_t digest[CC_SHA512_DIGEST_LENGTH] = {0};
	CC_SHA512(byteData.bytes, (CC_LONG)byteData.length, digest);

	NSData* data = [NSData dataWithBytes:digest length:CC_SHA512_DIGEST_LENGTH];
	return [data description];
}

@end
