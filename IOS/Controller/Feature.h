// Created by Michael Simms on 6/15/13.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __FEATURE__
#define __FEATURE__

typedef enum Feature
{
	FEATURE_IMPORT_DATA = 0,
	FEATURE_CORE_PLOT_GRAPHS,
	FEATURE_MAP_OVERLAYS,
	FEATURE_HEATMAP,
	FEATURE_LOCAL_BROADCAST,
	FEATURE_GLOBAL_BROADCAST,
	FEATURE_DROPBOX,
	FEATURE_ICLOUD,
	FEATURE_STRAVA,
	FEATURE_GARMIN_CONNECT,
	FEATURE_RUNKEEPER
} Feature;

#endif
