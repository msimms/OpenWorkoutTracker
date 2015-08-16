// Created by Michael Simms on 8/26/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __TCXFILEREADER__
#define __TCXFILEREADER__

#pragma once

#include <iostream>

#include "XmlFileReader.h"

namespace FileLib
{
	class TcxFileReader : public XmlFileReader
	{
	public:
		TcxFileReader();
		virtual ~TcxFileReader();

		virtual void ProcessNode(xmlNode* node);
		virtual void ProcessProperties(xmlAttr* attr);
	};
}

#endif
