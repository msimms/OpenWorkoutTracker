// Created by Michael Simms on 7/4/23.
// Copyright (c) 2023 Michael J. Simms. All rights reserved.

#ifndef __SERVICEHISTORY__
#define __SERVICEHISTORY__

#include <stdint.h>
#include <string>

typedef struct ServiceHistory
{
	std::string gearId;       // database identifier for the associated gear
	std::string serviceId;    // database identifier
	time_t      timeServiced; // timestamp of when the bike was added; the gear should not be available for activities before this date
	std::string description;  // whatever the user wants to say about the bike
} ServiceHistory;

#endif
