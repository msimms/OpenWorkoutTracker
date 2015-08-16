// Created by Michael Simms on 7/10/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import "CloudService.h"

@interface SocialCloud : CloudService

- (void)buildAcctNameList;
- (BOOL)postUpdate:(NSString*)text;

@end
