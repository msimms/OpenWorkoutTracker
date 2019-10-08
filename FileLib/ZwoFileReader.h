// Created by Michael Simms on 10/07/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#ifndef __ZWOFILEREADER__
#define __ZWOFILEREADER__

#pragma once

#include "XmlFileReader.h"

namespace FileLib
{
	class ZwoFileReader : public XmlFileReader
	{
	public:
		ZwoFileReader();
		virtual ~ZwoFileReader();

		virtual void ProcessNode(xmlNode* node);
		virtual void ProcessProperties(xmlAttr* attr);

		virtual void PushState(std::string newState);
		virtual void PopState();
		
	private:
		void Clear();
	};
}

#endif
