// Created by Michael Simms on 7/10/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include <iostream>
#include <sstream>

#include "CsvFileWriter.h"

namespace FileLib
{
	CsvFileWriter::CsvFileWriter()
	{
	}
	
	CsvFileWriter::~CsvFileWriter()
	{
	}
	
	bool CsvFileWriter::CreateFile(const std::string& fileName)
	{
		return File::CreateFile(fileName);
	}
	
	bool CsvFileWriter::WriteValues(std::vector<std::string>& values)
	{
		bool result = true;

		std::vector<std::string>::iterator iter = values.begin();
		while (iter != values.end() && result)
		{
			result = File::WriteString((*iter));

			iter++;
			if (iter != values.end() && result)
			{
				result = File::WriteString(",");
			}
		}
		if (result)
		{
			result = File::WriteString("\n");
		}
		return result;
	}
	
	bool CsvFileWriter::WriteValues(std::vector<double>& values)
	{
		bool result = true;
		
		std::vector<double>::iterator iter = values.begin();
		while (iter != values.end() && result)
		{
			result = File::WriteString(FormatDouble((*iter)).c_str());

			iter++;
			if (iter != values.end() && result)
			{
				result = File::WriteString(",");
			}
		}
		if (result)
		{
			result = File::WriteString("\n");
		}
		return result;
	}

	std::string CsvFileWriter::FormatDouble(double d)
	{
		char buf[32];
		snprintf(buf, sizeof(buf) - 1, "%.8lf", d);
		return buf;
	}
}
