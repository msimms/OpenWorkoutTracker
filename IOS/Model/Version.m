// Created by Michael Simms on 11/23/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#import "Version.h"

@implementation Version

- (id)init
{
	self = [super init];
	return self;
}

- (NSString*)compileTime
{
	return [NSString stringWithUTF8String:__DATE__];
}

@end
