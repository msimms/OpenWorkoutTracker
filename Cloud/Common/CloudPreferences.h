// Created by Michael Simms on 7/17/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

@interface CloudPreferences : NSObject

+ (BOOL)readBooleanValue:(NSString*)key;
+ (NSInteger)readNumericValue:(NSString*)key;
+ (NSString*)readStringValue:(NSString*)key;

+ (void)writeBoolValue:(NSString*)key withValue:(BOOL)value;
+ (void)writeIntValue:(NSString*)key withValue:(NSInteger)value;
+ (void)writeDoubleValue:(NSString*)key withValue:(double)value;
+ (void)writeStringValue:(NSString*)key withValue:(NSString*)value;

+ (BOOL)usingDropbox;
+ (BOOL)usingiCloud;
+ (BOOL)usingGarminConnect;
+ (BOOL)usingRunKeeper;
+ (BOOL)usingStrava;
+ (BOOL)usingFacebook;
+ (BOOL)usingTwitter;
+ (NSString*)preferredFacebookAcctName;
+ (NSString*)preferredTwitterAcctName;

+ (void)setUsingDropbox:(BOOL)value;
+ (void)setUsingiCloud:(BOOL)value;
+ (void)setUsingGarminConnect:(BOOL)value;
+ (void)setUsingRunKeeper:(BOOL)value;
+ (void)setUsingStrava:(BOOL)value;
+ (void)setUsingFacebook:(BOOL)value;
+ (void)setUsingTwitter:(BOOL)value;
+ (void)setPreferredFacebookAcctName:(NSString*)name;
+ (void)setPreferredTwitterAcctName:(NSString*)name;

@end
