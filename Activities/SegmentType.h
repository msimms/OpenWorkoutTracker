// Created by Michael Simms on 12/26/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __SEGMENT_TYPE__
#define __SEGMENT_TYPE__

typedef struct SegmentType
{
	union
	{
		double   doubleVal;
		uint32_t intVal;
	} value;
	uint64_t startTime;
	uint64_t endTime;
} SegmentType;

#endif
