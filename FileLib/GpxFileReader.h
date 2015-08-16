// Created by Michael Simms on 9/16/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __GPXFILEREADER__
#define __GPXFILEREADER__

#pragma once

#include "XmlFileReader.h"

namespace FileLib
{
	class GpxFileReader : public XmlFileReader
	{
	public:
		GpxFileReader();
		virtual ~GpxFileReader();

		virtual void ProcessNode(xmlNode* node);
		virtual void ProcessProperties(xmlAttr* attr);

		virtual void PushState(std::string newState);
		virtual void PopState();
		
		typedef bool (*NewLocationFunc)(double lat, double lon, double ele, uint64_t time, void* context);
		virtual void SetNewLocationCallback(NewLocationFunc func, void* context) { m_newLocCallback = func; m_newLocContext = context; };
		
	protected:
		double          m_curLat;
		double          m_curLon;
		double          m_curEle;
		uint64_t        m_curTime;
		NewLocationFunc m_newLocCallback;
		void*           m_newLocContext;
		
	private:
		void Clear();
	};
}

#endif
