// Created by Michael Simms on 11/7/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __GRAPH_LINE__
#define __GRAPH_LINE__

#include <map>
#include <math.h>
#include <stdint.h>
#include <vector>

#include "EdgeDirection.h"
#include "GraphPeak.h"
#include "GraphPoint.h"

#define DEFAULT_WINDOW_SIZE 20
#define INDEX_NOT_SET       0

typedef std::vector<GraphPoint> GraphPointList;

class GraphLine
{
public:
	GraphLine()
	{
		m_windowSize = DEFAULT_WINDOW_SIZE;
		m_leftTroughIndex = INDEX_NOT_SET;
		m_peakIndex = INDEX_NOT_SET;
		m_rightTroughIndex = INDEX_NOT_SET;
		m_runningTotal = (double)0.0;
	};

	GraphPeakList FindNewPeaks()
	{
		GraphPeakList peaks;

		size_t numPoints = m_values.size();
		size_t curIndex = numPoints - 1;

		if (numPoints >= 2)
		{
			while (curIndex < numPoints)
			{
				const GraphPoint& curPoint = m_values.at(curIndex);
				const GraphPoint& prevPoint = m_values.at(curIndex - 1);

				double mean = m_runningTotal / numPoints;

				// In which direction are we moving?
				EdgeDirection direction = EDGE_DIRECTION_STILL;
				if (curPoint.y > prevPoint.y)
					direction = EDGE_DIRECTION_RISING;
				else if (curPoint.y < prevPoint.y)
					direction = EDGE_DIRECTION_FALLING;

				// Line is falling.
				if (direction == EDGE_DIRECTION_FALLING)
				{
					// Only consider points <= mean.
					if (curPoint.y <= mean)
					{
						// If we have found a peak value, then this might be a new right trough.
						if (m_peakIndex != INDEX_NOT_SET)
						{
							if (m_rightTroughIndex == INDEX_NOT_SET)
							{
								m_rightTroughIndex = curIndex;
							}
						}

						// If this value is lower than the current left trough then we have a new left trough.
						else if ((m_leftTroughIndex != INDEX_NOT_SET) ||
								 (curPoint.y <= m_values.at(m_leftTroughIndex).y))
						{
							m_leftTroughIndex = curIndex;
							m_peakIndex = INDEX_NOT_SET;
							m_rightTroughIndex = INDEX_NOT_SET;
						}
					}
				}

				// Line is rising.
				else if (direction == EDGE_DIRECTION_RISING)
				{
					// Only consider points >= mean.
					if (curPoint.y >= mean)
					{
						// Possible new peak value.
						if ((m_leftTroughIndex != INDEX_NOT_SET) &&
							((m_peakIndex == INDEX_NOT_SET) || (curPoint.y >= m_values.at(m_peakIndex).y)))
						{
							m_peakIndex = curIndex;
							m_rightTroughIndex = INDEX_NOT_SET;
						}
					}
				}

				// Evaluate.
				if ((m_leftTroughIndex != INDEX_NOT_SET) &&
					(m_peakIndex != INDEX_NOT_SET) &&
					(m_rightTroughIndex != INDEX_NOT_SET) &&
					(m_rightTroughIndex < (curIndex - 2)))
				{
					GraphPeak peak;

					peak.leftTrough = m_values.at(m_leftTroughIndex);
					peak.peak = m_values.at(m_peakIndex);
					peak.rightTrough = m_values.at(m_rightTroughIndex);

					// Compute peak area.
					if (m_leftTroughIndex < m_rightTroughIndex)
					{
						for (size_t index = m_leftTroughIndex + 1; index <= m_rightTroughIndex; ++index)
						{
							const GraphPoint& curPoint = m_values.at(index);
							const GraphPoint& prevPoint = m_values.at(index - 1);
							double b = curPoint.y + prevPoint.y;
							peak.area += ((double)0.5 * b);
						}
					}

					peaks.push_back(peak);

					// Setup for the next peak.
					m_leftTroughIndex = m_rightTroughIndex;
					m_peakIndex = INDEX_NOT_SET;
					m_rightTroughIndex = INDEX_NOT_SET;

					// Continue looking for peaks.
					curIndex = m_leftTroughIndex;
				}

				++curIndex;
			}
		}
		else if (numPoints >= 1)
		{
			m_leftTroughIndex = curIndex;
		}
		return peaks;
	}

	void AppendValue(uint64_t time, double value)
	{
		GraphPoint newPoint;
		newPoint.index = m_values.size();
		newPoint.x = time;
		newPoint.y = value;
		m_values.push_back(newPoint);

		m_runningTotal += value;
	}

	void SelfTest()
	{
		double points1[91] = {
			0.841770413, 0.854868628, 0.827690150, 0.825026947, 0.734910636, 0.902175319, 0.736009843, 0.723444522, 0.860719376, 0.836096143,
			0.884293198, 0.950131129, 0.862929189, 0.769153837, 1.013503541, 1.173500910, 1.256440663, 1.256235433, 1.074077182, 0.949357884,
			1.258802095, 0.817808028, 1.897891336, 1.720614081, 1.428626053, 1.227194452, 1.019657426, 0.772583497, 0.702879197, 0.680972485,
			0.622547384, 0.527228093, 0.702981533, 0.832305412, 0.949952661, 0.825026947, 0.771135673, 1.049142820, 1.124694950, 0.644774504,
			0.878419942, 1.028520830, 0.770358712, 0.773629980, 0.625367803, 0.662017226, 0.759203126, 0.844712899, 0.876018988, 0.903654239,
			0.989863458, 0.990045656, 1.014394692, 1.100744721, 1.170065285, 1.470881584, 1.234948461, 1.262228387, 1.099752394, 0.949625498,
			0.798167312, 0.646294698, 0.619949580, 0.702674530, 0.849347187, 0.945882096, 0.925836499, 0.606804294, 0.797567613, 0.914128090,
			1.072369974, 0.938860924, 0.711167540, 0.523247013, 0.613120352, 0.742674920, 0.788734576, 0.782459237, 0.954061778, 0.848728555,
			0.898266400, 1.014486911, 1.193053534, 1.351243063, 1.349079973, 1.121040732, 0.969354672, 0.848391203, 0.785701982, 0.771350078,
			0.702393155
		};
		
		double points2[100] = {
			0.511307042, 0.544158357, 0.518731397, 0.538343380, 0.505367038, 0.481975259, 0.481064674, 0.646098443, 0.638199508, 0.523026296,
			0.358763276, 0.488650826, 0.855743571, 0.968183205, 0.685513042, 0.875876185, 0.752543550, 0.580122467, 0.549914037, 0.265130084,
			0.007519613, 0.037122781, 0.077029623, 0.353336789, 0.480429876, 0.253521837, 0.295528010, 0.115317531, 0.015731995, 0.005949527,
			0.158533647, 0.233158009, 0.414084078, 0.744701377, 0.524019932, 0.402694975, 0.447732842, 0.314007555, 0.110650434, 0.032457813,
			0.055268324, 0.163209294, 0.281578438, 0.377218940, 0.635325941, 0.709238670, 0.565433495, 0.495909428, 0.241018431, 0.096790334,
			0.160288218, 0.046683847, 0.000535810, 0.276468385, 0.264219470, 0.179164951, 0.425851037, 0.500475938, 0.539867070, 0.443068835,
			0.245700407, 0.297272536, 0.153555012, 0.006247405, 0.072039687, 0.365263242, 0.316131652, 0.446324954, 0.483332169, 0.341947263,
			0.660007490, 0.257827042, 0.161340685, 0.010451768, 0.007429906, 0.043483347, 0.128624500, 0.288502868, 0.474546410, 0.429023402,
			0.435504134, 0.382711837, 0.425592188, 0.310851844, 0.108790454, 0.025071698, 0.012174099, 0.145577365, 0.270277502, 0.176424100,
			0.338565016, 0.750189215, 0.522783545, 0.504629685, 0.123789387, 0.223331819, 1.87792E-05, 0.002979052, 0.110427218, 0.148867675
		};

		for (size_t i = 0; i < 91; ++i)
		{
			AppendValue(i, points1[i]);
			
			GraphPeakList peaks = FindNewPeaks();
			GraphPeakList::const_iterator iter = peaks.begin();
			while (iter != peaks.end())
			{
				++iter;
			}
		}

		for (size_t i = 0; i < 100; ++i)
		{
			AppendValue(i, points2[i]);
			
			GraphPeakList peaks = FindNewPeaks();
			GraphPeakList::const_iterator iter = peaks.begin();
			while (iter != peaks.end())
			{
				++iter;
			}
		}
	}
	
private:
	GraphPointList m_values;
	double         m_runningTotal;  // used for mean calculation
	size_t         m_windowSize;
	size_t         m_leftTroughIndex;
	size_t         m_peakIndex;
	size_t         m_rightTroughIndex;
};

typedef std::vector<GraphLine> GraphLineList;
typedef std::map<std::string, GraphLine> GraphLineMap;

#endif
