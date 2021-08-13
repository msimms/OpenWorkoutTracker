// Created by Michael Simms on 8/26/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "TcxFileReader.h"
#include "TcxTags.h"

namespace FileLib
{	
	TcxFileReader::TcxFileReader()
	{
		Clear();
		m_newLocCallback = NULL;
		m_newLocContext = 0;
	}

	TcxFileReader::~TcxFileReader()
	{
	}

	void TcxFileReader::ProcessNode(xmlNode* node)
	{
		if (m_state.size() == 0)
		{
			return;
		}
		if (!node)
		{
			return;
		}

		const std::string& state = CurrentState();
		std::string prevState = PrevState();

		switch (node->type)
		{
			case XML_ELEMENT_NODE:
				break;
			case XML_ATTRIBUTE_NODE:
				break;
			case XML_TEXT_NODE:
				{
					if (state.compare(TCX_TAG_NAME_LATITUDE) == 0)
					{
						m_curLat = atof((const char*)node->content);
					}
					else if (state.compare(TCX_TAG_NAME_LONGITUDE) == 0)
					{
						m_curLon = atof((const char*)node->content);
					}
					else if (state.compare(TCX_TAG_NAME_ALTITUDE_METERS) == 0)
					{
						m_curEle = atof((const char*)node->content);
					}
					else if (state.compare(TCX_TAG_NAME_VALUE) == 0 && prevState.compare(TCX_TAG_NAME_HEART_RATE_BPM) == 0)
					{
						m_curHeartRate = atof((const char*)node->content);
					}
					else if (state.compare(TCX_TAG_NAME_POWER) == 0)
					{
						m_curPower = atof((const char*)node->content);
					}
					else if (state.compare(TCX_TAG_NAME_CADENCE) == 0)
					{
						m_curCadence = atof((const char*)node->content);
					}
					else if (state.compare(TCX_TAG_NAME_TIME) == 0)
					{
						struct tm tm;

						if (strptime((const char*)node->content, "%Y-%m-%dT%H:%M:%OS", &tm))
						{
							m_curTime = timegm(&tm);
							m_curTime *= 1000;
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

	void TcxFileReader::ProcessProperties(xmlAttr* attr)
	{
		if (!attr)
		{
			return;
		}

		const std::string& state = CurrentState();
		std::string prevState = PrevState();
		std::string attrName;

		if (attr->name)
		{
			attrName = (char*)attr->name;
		}

		if (state.compare(TCX_TAG_NAME_POSITION) == 0)
		{
			if (attrName.compare(TCX_TAG_NAME_LATITUDE) == 0)
			{
				m_curLat = atof((const char*)attr->children->content);
			}
			else if (attrName.compare(TCX_TAG_NAME_LONGITUDE) == 0)
			{
				m_curLon = atof((const char*)attr->children->content);
			}
		}
		else if (state.compare(TCX_TAG_NAME_VALUE) == 0 && prevState.compare(TCX_TAG_NAME_HEART_RATE_BPM) == 0)
		{
			m_curHeartRate = atof((const char*)attr->children->content);
		}
		else if (state.compare(TCX_TAG_NAME_POWER) == 0)
		{
			m_curPower = atof((const char*)attr->children->content);
		}
		else if (state.compare(TCX_TAG_NAME_CADENCE) == 0)
		{
			m_curCadence = atof((const char*)attr->children->content);
		}
	}

	void TcxFileReader::PushState(std::string newState)
	{
		if (newState.compare(TCX_TAG_NAME_TRACKPOINT) == 0)
		{
			Clear();
		}
		XmlFileReader::PushState(newState);
	}

	void TcxFileReader::PopState()
	{
		if (m_state.size() == 0)
		{
			return;
		}

		const std::string& state = CurrentState();

		if (state.compare(TCX_TAG_NAME_TRACKPOINT) == 0)
		{
			if (m_newLocCallback)
			{
				m_newLocCallback(m_curLat, m_curLon, m_curEle, m_curTime, m_curHeartRate, m_curPower, m_curCadence, m_newLocContext);
			}
		}
		XmlFileReader::PopState();
	}

	void TcxFileReader::Clear()
	{
		m_curLat = (double)0.0;
		m_curLon = (double)0.0;
		m_curEle = (double)0.0;
		m_curHeartRate = (double)TCX_VALUE_NOT_SET;
		m_curPower = (double)TCX_VALUE_NOT_SET;
		m_curCadence = (double)TCX_VALUE_NOT_SET;
		m_curTime = 0;
	}
}
