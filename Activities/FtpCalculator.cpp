// Created by Michael Simms on 7/20/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "FtpCalculator.h"

FtpCalculator::FtpCalculator()
{
}

FtpCalculator::~FtpCalculator()
{
}

double FtpCalculator::Estimate(double best20MinPower, double best1HourPower)
{
	double max20MinAdjusted = (double)0.0;

	// Loop for each activity summary data.
	if (best20MinPower > 0.0)
	{
		max20MinAdjusted = best20MinPower * 0.95;
	}
	if (best1HourPower > max20MinAdjusted)
	{
		return best1HourPower;
	}
	return max20MinAdjusted;
}
