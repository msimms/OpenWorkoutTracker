// Created by Michael Simms on 9/27/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __XMLFILEREADER__
#define __XMLFILEREADER__

#pragma once

#include "File.h"
#include <libxml2/libxml/xmlreader.h>
#include <vector>

namespace FileLib
{	
	class XmlFileReader : public File
	{
	public:
		XmlFileReader();
		virtual ~XmlFileReader();

		virtual bool ParseFile(const std::string& fileName);
		virtual void ProcessNode(xmlNode* node) = 0;
		virtual void ProcessProperties(xmlAttr* attr) = 0;

		virtual void PushState(std::string newState) { m_state.push_back(newState); };
		virtual void PopState() { m_state.pop_back(); };

		virtual const std::string& CurrentState() const { return m_state.at(m_state.size() - 1); };

	protected:
		std::vector<std::string> m_state;
	};
}

#endif
