// Created by Michael Simms on 6/15/13.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __FEATURE__
#define __FEATURE__

typedef enum Feature
{
	FEATURE_BROADCAST = 0,           // Provides the option to send data to the companion seb service
	FEATURE_WORKOUT_PLAN_GENERATION, 
	FEATURE_DROPBOX,                 // Exporting activities to Dropbox
	FEATURE_STRAVA,                  // Exporting activities to Strava
	FEATURE_RUNKEEPER,               // Exporting activities to RunKeeper
	FEATURE_STRENGTH_ACTIVITIES,     // Enables strength-based activities
	FEATURE_SWIM_ACTIVITIES,         // Enables swimming activities
	FEATURE_MULTISPORT,              // Enables triathlon and duathlon modes
	FEATURE_DEBUG,                   // Enables debug information
} Feature;

#endif
