// Created by Michael Simms on 7/7/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "HeatMapGenerator.h"
#include "Distance.h"

#include <math.h>

void HeatMapDatabaseCallback(uint64_t time, double latitude, double longitude, double altitude, void* context)
{
	HeatMap* pHeatmap = (HeatMap*)context;

	Coordinate newCoordinate;
	newCoordinate.latitude = latitude;
	newCoordinate.longitude = longitude;
	newCoordinate.altitude = altitude;

	HeatMap::iterator iter = pHeatmap->begin();
	while (iter != pHeatmap->end())
	{
		const Coordinate& oldCoordinate = (*iter).coord;

		if (oldCoordinate.latitude > newCoordinate.latitude)
		{
			return;
		}

		if ((fabs(oldCoordinate.latitude - newCoordinate.latitude) < 0.005) &&
			(fabs(oldCoordinate.longitude - newCoordinate.longitude) < 0.005))
		{
			double distance = LibMath::Distance::haversineDistance(newCoordinate.latitude, newCoordinate.longitude, newCoordinate.altitude, oldCoordinate.latitude, oldCoordinate.longitude, oldCoordinate.altitude);
			if (distance < 100)
			{
				(*iter).count++;
				return;
			}
		}

		++iter;
	}
}

bool HeatMapGenerator::CreateHeatMap(Database& db, HeatMap& heatMap)
{
	return db.ProcessAllCoordinates(HeatMapDatabaseCallback, (void*)&heatMap);
}
