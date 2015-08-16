// Created by Michael Simms on 2/11/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import "DataCloud.h"

@interface GarminConnect : DataCloud
{
}

- (NSString*)name;

- (id)init;
- (BOOL)isLinked;
- (BOOL)uploadActivity:(NSString*)name;

@end
