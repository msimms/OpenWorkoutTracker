// Created by Michael Simms on 7/7/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include <iostream>

#include "File.h"

namespace FileLib
{
	File::File()
	{
	}

	File::~File()
	{
		CloseFile();
	}
	
	bool File::OpenFile(const std::string& fileName)
	{
		if (!m_file.is_open())
		{
			m_file.open(fileName.c_str(), std::ios::in);
			m_fileName = fileName;
			return m_file.is_open();
		}
		return false;		
	}

	bool File::CreateFile(const std::string& fileName)
	{
		if (!m_file.is_open())
		{
			m_file.open(fileName.c_str(), std::ios::out);
			m_fileName = fileName;
			return m_file.is_open();
		}
		return false;
	}

	bool File::CloseFile()
	{
		if (m_file.is_open())
		{
			m_file.close();
			return true;
		}
		return false;
	}

	bool File::IsOpen() const
	{
		return m_file.is_open();
	}

	bool File::SeekFromStart(size_t offset)
	{
		m_file.seekp(offset, std::ios::beg);
		return true;
	}

	bool File::WriteString(const std::string& str)
	{
		if (m_file.is_open())
		{
			m_file << str;
			return true;
		}
		return false;
	}

	bool File::WriteBinaryData(const uint8_t* data, size_t len)
	{
		if (m_file.is_open())
		{
			m_file.write((const char*)data, len);
			return true;
		}
		return false;
	}
}
