// Created by Michael Simms on 8/27/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __TEXTFILEREADER__
#define __TEXTFILEREADER__

#pragma once

#include <vector>
#include <string>

#include "File.h"

namespace FileLib
{
	class TextFileReader : public File
	{
	public:
		TextFileReader();
		virtual ~TextFileReader();
		
		bool ReadValues(std::vector<std::string>& values);
	};
}

#endif
