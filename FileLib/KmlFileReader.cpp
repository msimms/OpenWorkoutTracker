// Created by Michael Simms on 8/11/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "KmlFileReader.h"
#include <stdlib.h>

namespace FileLib
{	
	KmlFileReader::KmlFileReader()
	{
	}
	
	KmlFileReader::~KmlFileReader()
	{
	}

	void KmlFileReader::ProcessNode(xmlNode* node)
	{
		switch (node->type)
		{
			case XML_ELEMENT_NODE:
				break;
			case XML_ATTRIBUTE_NODE:
				break;
			case XML_TEXT_NODE:
				{
					if (m_state.size() >= 3)
					{
						if ((m_state.at(m_state.size() - 1).compare("coordinates") == 0) &&
							(m_state.at(m_state.size() - 2).compare("Point") == 0) &&
							(m_state.at(m_state.size() - 3).compare("Placemark") == 0))
						{
							ParseCoordinatesStr((const char*)node->content);
						}

						if ((m_state.at(m_state.size() - 1).compare("coordinates") == 0) &&
							(m_state.at(m_state.size() - 2).compare("LineString") == 0) &&
							(m_state.at(m_state.size() - 3).compare("Placemark") == 0))
						{
							ParseCoordinatesStr((const char*)node->content);
						}
					}
					if (m_state.size() >= 2)
					{
						if ((m_state.at(m_state.size() - 1).compare("name") == 0) &&
							(m_state.at(m_state.size() - 2).compare("Placemark") == 0))
						{
							m_currentPlacemark.name = (const char*)node->content;
						}
					}
				}
				break;
			case XML_CDATA_SECTION_NODE:
				break;
			case XML_ENTITY_REF_NODE:
				break;
			case XML_ENTITY_NODE:
				break;
			case XML_PI_NODE:
				break;
			case XML_COMMENT_NODE:
				break;
			case XML_DOCUMENT_NODE:
				break;
			case XML_DOCUMENT_TYPE_NODE:
				break;
			case XML_DOCUMENT_FRAG_NODE:
				break;
			case XML_NOTATION_NODE:
				break;
			case XML_HTML_DOCUMENT_NODE:
				break;
			case XML_DTD_NODE:
				break;
			case XML_ELEMENT_DECL:
				break;
			case XML_ATTRIBUTE_DECL:
				break;
			case XML_ENTITY_DECL:
				break;
			case XML_NAMESPACE_DECL:
				break;
			case XML_XINCLUDE_START:
				break;
			case XML_XINCLUDE_END:
				break;
			case XML_DOCB_DOCUMENT_NODE:
				break;
		}
	}

	void KmlFileReader::ProcessProperties(xmlAttr* attr)
	{
		
	}

	void KmlFileReader::PushState(std::string newState)
	{
		XmlFileReader::PushState(newState);		
	}

	void KmlFileReader::PopState()
	{
		if ((m_state.size() > 0) &&
			(m_state.at(m_state.size() - 1).compare("Placemark") == 0))
		{
			m_placemarks.push_back(m_currentPlacemark);
			m_currentPlacemark.coordinates.clear();
		}
		XmlFileReader::PopState();
	}

	void KmlFileReader::ParseCoordinatesStr(const char* str)
	{
		std::string tokenStr;
		std::vector<double> tempCoordinates;
		char* end;

		for (size_t i = 0; i < strlen(str); ++i)
		{
			switch (str[i])
			{
				case ' ':
					if (tempCoordinates.size() == 2)
					{
						KmlCoordinate coordinate;
						coordinate.latitude = tempCoordinates.at(1);
						coordinate.longitude = tempCoordinates.at(0);
						coordinate.altitude = strtod(tokenStr.c_str(), &end);
						m_currentPlacemark.coordinates.push_back(coordinate);
					}
					tempCoordinates.clear();
					tokenStr.clear();
					break;
				case ',':
					tempCoordinates.push_back(strtod(tokenStr.c_str(), &end));
					tokenStr.clear();
					break;
				default:
					tokenStr += str[i];
					break;
			}
		}

		if (tempCoordinates.size() == 2)
		{
			KmlCoordinate coordinate;
			coordinate.latitude = tempCoordinates.at(1);
			coordinate.longitude = tempCoordinates.at(0);
			coordinate.altitude = strtod(tokenStr.c_str(), &end);
			m_currentPlacemark.coordinates.push_back(coordinate);
		}
	}
}
