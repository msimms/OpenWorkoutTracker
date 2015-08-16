// Created by Michael Simms on 10/11/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <time.h>

#import "ActivityLevel.h"
#import "Gender.h"

@interface UserProfile : NSObject

+ (void)setActivityLevel:(ActivityLevel)level;
+ (void)setGender:(Gender)gender;
+ (void)setBirthDate:(NSDate*)birthday;
+ (void)setHeightInCm:(double)height;
+ (void)setWeightInKg:(double)weight;
+ (void)setHeightInInches:(double)height;
+ (void)setWeightInLbs:(double)weight;

+ (ActivityLevel)activityLevel;
+ (Gender)gender;
+ (struct tm)birthDate;
+ (double)heightInCm;
+ (double)weightInKg;
+ (double)heightInInches;
+ (double)weightInLbs;

@end
