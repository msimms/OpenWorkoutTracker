// Created by Michael Simms on 7/10/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __CSVFILEWRITER__
#define __CSVFILEWRITER__

#pragma once

#include <vector>
#include <string>

#include "File.h"

namespace FileLib
{
	class CsvFileWriter : public File
	{
	public:
		CsvFileWriter();
		virtual ~CsvFileWriter();
		
		bool CreateFile(const std::string& fileName);
		bool WriteValues(std::vector<std::string>& values);
		bool WriteValues(std::vector<double>& values);
		
	private:
		std::string FormatDouble(double d);
	};
}

#endif
