// Created by Michael Simms on 11/7/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __EDGE_DIRECTION__
#define __EDGE_DIRECTION__

typedef enum EdgeDirection
{
	EDGE_DIRECTION_UNKNOWN = 0,
	EDGE_DIRECTION_STILL,
	EDGE_DIRECTION_RISING,
	EDGE_DIRECTION_FALLING
} EdgeDirection;

#endif
