// Created by Michael Simms on 7/7/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include <iostream>
#include <sstream>

#include "XmlFileWriter.h"

namespace FileLib
{
	XmlFileWriter::XmlFileWriter()
	{
	}

	XmlFileWriter::~XmlFileWriter()
	{
	}

	bool XmlFileWriter::CreateFile(const std::string& fileName)
	{
		if (File::CreateFile(fileName))
		{
			std::string str = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n";
			return File::WriteString(str);
		}
		return false;
	}

	bool XmlFileWriter::OpenTag(const std::string& tagName)
	{
		std::string str = FormatIndent();
		str += "<";
		str += tagName;
		str += ">\n";

		m_tags.push(tagName);
		return File::WriteString(str);
	}

	bool XmlFileWriter::OpenTag(const std::string& tagName, const XmlKeyValueList& keyValues, bool valuesOnIndividualLines)
	{
		std::string indent = FormatIndent();

		std::string str = indent;
		str += "<";
		str += tagName;
		str += " ";
		
		XmlKeyValueList::const_iterator iter = keyValues.begin();
		while (iter != keyValues.end())
		{
			if (valuesOnIndividualLines)
			{
				str += "\n";
				str += indent;
				str += " ";
			}
			else if (iter != keyValues.begin())
			{
				str += " ";
			}
			str += (*iter).key;
			str += "=\"";
			str += (*iter).value;
			str += "\"";
			iter++;
		}
		str += ">\n";
		
		m_tags.push(tagName);
		return File::WriteString(str);		
	}

	bool XmlFileWriter::WriteTagAndValue(const std::string& tagName, uint32_t value)
	{
		std::stringstream strValue;
		strValue << value;
		return WriteTagAndValue(tagName, strValue.str());
	}
	
	bool XmlFileWriter::WriteTagAndValue(const std::string& tagName, double value)
	{
		std::stringstream strValue;
		strValue.precision(std::numeric_limits<double>::digits10 + 2);
		strValue << value;
		return WriteTagAndValue(tagName, strValue.str());
	}
	
	bool XmlFileWriter::WriteTagAndValue(const std::string& tagName, const std::string& value)
	{
		std::string str = FormatIndent();
		str += "<";
		str += tagName;
		str += ">";
		str += value;
		str += "</";
		str += tagName;
		str += ">\n";
		return File::WriteString(str);		
	}
	
	bool XmlFileWriter::CloseTag()
	{
		std::string tagName = m_tags.top();
		m_tags.pop();

		std::string str = FormatIndent();
		str += "</";
		str += tagName;
		str += ">\n";
		return File::WriteString(str);		
	}
	
	bool XmlFileWriter::CloseAllTags()
	{
		bool result = true;

		while (m_tags.size() > 0 && result)
		{
			result &= CloseTag();
		}
		return true;
	}

	std::string XmlFileWriter::FormatIndent()
	{
		std::string str;

		for (uint8_t i = 0; i < m_tags.size(); ++i)
		{
			str += "  ";
		}
		return str;
	}
}
