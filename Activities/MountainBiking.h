// Created by Michael Simms on 10/8/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __MOUNTAINBIKING__
#define __MOUNTAINBIKING__

#include "ActivityName.h"
#include "Cycling.h"

class MountainBiking : public Cycling
{
public:
	MountainBiking();
	virtual ~MountainBiking();
	
	static std::string Name() { return ACTIVITY_NAME_MOUNTAIN_BIKING; };
	virtual std::string GetName() const { return MountainBiking::Name(); };
};

#endif
