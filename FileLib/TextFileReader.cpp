// Created by Michael Simms on 8/27/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include <iostream>

#include "TextFileReader.h"

namespace FileLib
{
	TextFileReader::TextFileReader()
	{
	}
	
	TextFileReader::~TextFileReader()
	{
	}
	
	bool TextFileReader::ReadValues(std::vector<std::string>& lines)
	{
		bool result = false;
		
		if (File::IsOpen())
		{
			std::string temp;
			while (getline(m_file, temp))
				lines.push_back(temp);
			result = true;
		}
		return result;
	}
}
