// Created by Michael Simms on 7/20/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

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
