// Created by Michael Simms on 7/17/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import "Preferences.h"

@interface CloudPreferences : Preferences

+ (BOOL)usingDropbox;
+ (BOOL)usingiCloud;
+ (BOOL)usingRunKeeper;
+ (BOOL)usingStrava;

+ (void)setUsingDropbox:(BOOL)value;
+ (void)setUsingiCloud:(BOOL)value;
+ (void)setUsingRunKeeper:(BOOL)value;
+ (void)setUsingStrava:(BOOL)value;

@end
