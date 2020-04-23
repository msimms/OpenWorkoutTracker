// Created by Michael Simms on 4/20/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __SHOES__
#define __SHOES__

#include <stdint.h>
#include <string>

#define SHOE_ID_NOT_SET 0

typedef struct Shoes
{
	uint64_t    id;
	std::string name;
	std::string description;
	time_t      timeAdded;
	time_t      timeRetired;
} Shoes;

#endif
