// Created by Michael Simms on 7/20/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __FTPCALCULATOR__
#define __FTPCALCULATOR__

class FtpCalculator
{
public:
	FtpCalculator();
	virtual ~FtpCalculator();

	double Estimate(double best20MinPower, double best1HourPower);
};

#endif
