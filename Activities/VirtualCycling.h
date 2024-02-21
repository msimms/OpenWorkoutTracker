// Created by Michael Simms on 2/21/24.
// Copyright (c) 2024 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __VIRTUALCYCLING__
#define __VIRTUALCYCLING__

#include "StationaryCycling.h"

class VirtualCycling : public StationaryCycling
{
public:
	VirtualCycling();
	virtual ~VirtualCycling();
	
	static std::string Type(void) { return ACTIVITY_TYPE_VIRTUAL_CYCLING; };
	virtual std::string GetType(void) const { return VirtualCycling::Type(); };
};

#endif
