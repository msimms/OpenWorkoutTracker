// Created by Michael Simms on 11/29/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#import <XCTest/XCTest.h>
#import "BaseTest.h"
#import "ActivityMgr.h"
#import "StringUtils.h"

@implementation BaseTest

- (void)printActivityAttributes:(NSString*)activityId
{
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);
	XCTAssert(activityIndex != ACTIVITY_INDEX_UNKNOWN);

	size_t numAttributes = GetNumHistoricalActivityAttributes(activityIndex);
	for (size_t i = 0; i < numAttributes; ++i)
	{
		char* attrName = GetHistoricalActivityAttributeName(activityIndex, i);
		XCTAssert(attrName);

		ActivityAttributeType attr = QueryHistoricalActivityAttribute(activityIndex, attrName);
		if (attr.valid)
		{
			NSString* attrStr = [StringUtils formatActivityViewType:attr];
			printf("%s = %s\n", attrName, [attrStr UTF8String]);
		}

		free((void*)attrName);
	}
}

@end
