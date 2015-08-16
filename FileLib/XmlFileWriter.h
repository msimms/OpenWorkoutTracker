// Created by Michael Simms on 7/7/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __XMLFILEWRITER__
#define __XMLFILEWRITER__

#pragma once

#include <iostream>
#include <stack>
#include <vector>

#include "File.h"

namespace FileLib
{
	typedef struct XmlKeyValuePair
	{
		std::string key;
		std::string value;
	} XmlKeyValuePair;

	typedef std::vector<XmlKeyValuePair> XmlKeyValueList;

	class XmlFileWriter : public File
	{
	public:
		XmlFileWriter();
		virtual ~XmlFileWriter();
		
		bool CreateFile(const std::string& fileName);
		
		bool OpenTag(const std::string& tagName);
		bool OpenTag(const std::string& tagName, const XmlKeyValueList& keyValues, bool valuesOnIndividualLines = false);

		bool WriteTagAndValue(const std::string& tagName, uint32_t value);
		bool WriteTagAndValue(const std::string& tagName, double value);
		bool WriteTagAndValue(const std::string& tagName, const std::string& value);

		bool CloseTag();
		bool CloseAllTags();
		
		const std::string& CurrentTag() const { return m_tags.top(); }
		
	private:
		std::stack<std::string> m_tags;

		std::string FormatIndent();
	};
}

#endif
