// Created by Michael Simms on 11/23/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
