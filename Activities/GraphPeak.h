// Created by Michael Simms on 4/20/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __GRAPH_PEAK__
#define __GRAPH_PEAK__

#include <map>
#include <stdint.h>
#include <vector>

#include "GraphPoint.h"

class GraphPeak
{
public:
	GraphPoint leftTrough;
	GraphPoint peak;
	GraphPoint rightTrough;
	double area;
	
	GraphPeak()
	{
		area = (double)0.0;
	}
	
	GraphPeak(const GraphPeak& rhs)
	{
		leftTrough = rhs.leftTrough;
		peak = rhs.peak;
		rightTrough = rhs.rightTrough;
		area = rhs.area;
	}
	
	GraphPeak& operator=(const GraphPeak& rhs)
	{
		leftTrough = rhs.leftTrough;
		peak = rhs.peak;
		rightTrough = rhs.rightTrough;
		area = rhs.area;
		return *this;
	}
	
	bool operator < (const GraphPeak& str) const
    {
        return (area < str.area);
    }

	bool operator > (const GraphPeak& str) const
    {
        return (area > str.area);
    }
};

typedef std::vector<GraphPeak> GraphPeakList;
typedef std::map<std::string, GraphPeakList> GraphPeakListMap;

#endif
