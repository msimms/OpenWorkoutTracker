// Created by Michael Simms on 10/16/23.
// Copyright (c) 2023 Michael J. Simms. All rights reserved.

#ifndef __ROUTE__
#define __ROUTE__

#include <vector>
#include "Coordinate.h"

typedef struct Route
{
	std::string             routeId;
	std::string             name;
	std::string             description;
	std::vector<Coordinate> coordinates;
} Route;

#endif
