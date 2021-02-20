// Created by Michael Simms on 2/19/21.
// Copyright (c) 2021 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import "CloudService.h"

@interface StraenWeb : CloudService
{
}

- (NSString*)name;

- (id)init;
- (BOOL)isLinked;
- (BOOL)uploadActivityFile:(NSString*)fileName forActivityId:(NSString*)activityId forActivityName:(NSString*)activityName;
- (BOOL)uploadFile:(NSString*)fileName;

@end
