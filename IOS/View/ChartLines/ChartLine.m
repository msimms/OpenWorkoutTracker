// Created by Michael Simms on 2/9/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "ChartLine.h"

@interface ChartLine ()

@end

@implementation ChartLine

- (void)setActivityId:(uint64_t)newId
{
	self->activityId = newId;
}

- (void)draw
{
}

@end
