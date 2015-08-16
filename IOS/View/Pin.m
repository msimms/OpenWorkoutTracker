// Created by Michael Simms on 12/21/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "Pin.h"

@implementation Pin

@synthesize coordinate;
@synthesize title;
@synthesize subtitle;

- (id)initWithCoordinates:(CLLocationCoordinate2D)location placeName:placeName description:description
{
	self = [super init];
	if (self)
	{
		coordinate = location;
		title = placeName;
		subtitle = description;
	}
	return self;
}

@end
