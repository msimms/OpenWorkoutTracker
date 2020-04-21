// Created by Michael Simms on 4/20/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#ifndef __SHOES__
#define __SHOES__

#include <stdint.h>
#include <string>

#define SHOE_ID_NOT_SET 0

typedef struct Shoes
{
	uint64_t    id;
	std::string name;
	std::string description;
} Shoes;

#endif
