// Created by Michael Simms on 12/3/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __FILE_FORMAT__
#define __FILE_FORMAT__

#pragma once

typedef enum FileFormat
{
	FILE_UNKNOWN,
	FILE_TEXT,
	FILE_TCX,
	FILE_GPX,
	FILE_CSV,
	FILE_ZWO,
	FILE_FIT
} FileFormat;

#endif
