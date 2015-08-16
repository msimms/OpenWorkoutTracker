// Created by Michael Simms on 8/11/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __KMLFILEREADER__
#define __KMLFILEREADER__

#pragma once

#include "XmlFileReader.h"

namespace FileLib
{
	typedef struct KmlCoordinate
	{
		double latitude;
		double longitude;
		double altitude;
	} KmlCoordinate;

	typedef struct KmlPlacemark
	{
		std::string name;
		std::vector<KmlCoordinate> coordinates;
	} KmlPlacemark;

	class KmlFileReader : public XmlFileReader
	{
	public:
		KmlFileReader();
		virtual ~KmlFileReader();

		virtual void ProcessNode(xmlNode* node);
		virtual void ProcessProperties(xmlAttr* attr);

		virtual void PushState(std::string newState);
		virtual void PopState();
		
		std::vector<KmlPlacemark> GetPlacemarks() const { return m_placemarks; };

	private:
		std::vector<KmlPlacemark> m_placemarks;
		KmlPlacemark m_currentPlacemark;

	private:
		void ParseCoordinatesStr(const char* str);
	};
}

#endif
