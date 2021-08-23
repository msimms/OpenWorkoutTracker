// Created by Michael Simms on 7/7/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __FILE1__
#define __FILE1__

#pragma once

#include <iostream>
#include <fstream>

namespace FileLib
{
	class File
	{
	public:
		File();
		virtual ~File();
		
		bool OpenFile(const std::string& fileName);
		bool CreateFile(const std::string& fileName);
		bool CloseFile();
		bool IsOpen() const;
		bool SeekFromStart(size_t offset);

		virtual bool WriteString(const std::string& str);
		virtual bool WriteBinaryData(const uint8_t* data, size_t len);

	protected:
		std::string  m_fileName;
		std::fstream m_file;
	};
}

#endif
