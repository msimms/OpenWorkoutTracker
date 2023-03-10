//
//  IntervalSessionSegment.cpp
//  Created by Michael Simms on 11/14/22.
//

#include "IntervalSessionSegment.h"
#include "UnitConverter.h"

bool IsDistanceBasedIntervalSegment(const IntervalSessionSegment* segment)
{
	return (segment->firstUnits == INTERVAL_UNIT_METERS ||
			segment->firstUnits == INTERVAL_UNIT_KILOMETERS ||
			segment->firstUnits == INTERVAL_UNIT_FEET ||
			segment->firstUnits == INTERVAL_UNIT_YARDS ||
			segment->firstUnits == INTERVAL_UNIT_MILES);
}

double ConvertDistanceIntervalSegmentToMeters(const IntervalSessionSegment* segment)
{
	switch (segment->firstUnits)
	{
	case INTERVAL_UNIT_NOT_SET:
	case INTERVAL_UNIT_SETS:
	case INTERVAL_UNIT_REPS:
	case INTERVAL_UNIT_SECONDS:
		break;
	case INTERVAL_UNIT_METERS:
		return segment->firstValue;
	case INTERVAL_UNIT_KILOMETERS:
		return segment->firstValue * 1000.0;
	case INTERVAL_UNIT_FEET:
		return UnitConverter::FeetToMeters(segment->firstUnits);
	case INTERVAL_UNIT_YARDS:
		return UnitConverter::YardsToMeters(segment->firstUnits);
	case INTERVAL_UNIT_MILES:
		return UnitConverter::MilesToKilometers(segment->firstUnits) / 1000.0;
	case INTERVAL_UNIT_PACE_US_CUSTOMARY:
	case INTERVAL_UNIT_PACE_METRIC:
	case INTERVAL_UNIT_SPEED_US_CUSTOMARY:
	case INTERVAL_UNIT_SPEED_METRIC:
	case INTERVAL_UNIT_WATTS:
		break;
	}
	return 0.0;
}
