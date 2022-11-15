//
//  IntervalSessionSegment.cpp
//  Created by Michael Simms on 11/14/22.
//

#include "IntervalSessionSegment.h"

bool IsDistanceBasedIntervalSegment(const IntervalSessionSegment* segment)
{
	return (segment->firstUnits == INTERVAL_UNIT_METERS ||
			segment->firstUnits == INTERVAL_UNIT_KILOMETERS ||
			segment->firstUnits == INTERVAL_UNIT_FEET ||
			segment->firstUnits == INTERVAL_UNIT_YARDS ||
			segment->firstUnits == INTERVAL_UNIT_MILES);
}

double ConvertDistanceIntervalSegmentToKm(const IntervalSessionSegment* segment)
{
	return 0.0;
}
