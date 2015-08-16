// Created by Michael Simms on 7/7/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __HEATMAPGENERATOR__
#define __HEATMAPGENERATOR__

#include "CoordinateCalculator.h"
#include "Database.h"

#include <list>

typedef struct HeatMapValue
{
	Coordinate coord;
	uint32_t   count;
} HeatMapValue;

typedef std::list<HeatMapValue> HeatMap;

class HeatMapGenerator
{
public:
	HeatMapGenerator() {};
	virtual ~HeatMapGenerator() {};
	
	bool CreateHeatMap(Database& db, HeatMap& heatMap);
};

#endif
