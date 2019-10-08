// Created by Michael Simms on 10/07/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#include "ZwoFileReader.h"
#include "ZwoTags.h"

namespace FileLib
{	
	ZwoFileReader::ZwoFileReader()
	{
		Clear();
	}
	
	ZwoFileReader::~ZwoFileReader()
	{
	}

	void ZwoFileReader::ProcessNode(xmlNode* node)
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
		
		switch (node->type)
		{
			case XML_ELEMENT_NODE:
				break;
			case XML_ATTRIBUTE_NODE:
				break;
			case XML_TEXT_NODE:
				{
					if (state.compare(ZWO_TAG_WORKOUT_FILE) == 0)
					{
					}
					else if (state.compare(ZWO_TAG_AUTHOR) == 0)
					{
					}
					else if (state.compare(ZWO_TAG_NAME) == 0)
					{
					}
					else if (state.compare(ZWO_TAG_DESCRIPTION) == 0)
					{
					}
					else if (state.compare(ZWO_TAG_SPORTTYPE) == 0)
					{
					}
					else if (state.compare(ZWO_TAG_TAGS) == 0)
					{
					}
					else if (state.compare(ZWO_TAG_WORKOUT) == 0)
					{
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

	void ZwoFileReader::ProcessProperties(xmlAttr* attr)
	{
		if (!attr)
		{
			return;
		}

		const std::string& state = CurrentState();
		std::string attrName;

		if (attr->name)
		{
			attrName = (char*)attr->name;
		}

		if (state.compare(ZWO_TAG_WORKOUT_FILE) == 0)
		{
		}
	}

	void ZwoFileReader::PushState(std::string newState)
	{
		if (newState.compare(ZWO_TAG_WORKOUT_FILE) == 0)
		{
			Clear();
		}
		XmlFileReader::PushState(newState);
	}

	void ZwoFileReader::PopState()
	{
		XmlFileReader::PopState();
	}
	
	void ZwoFileReader::Clear()
	{
	}
}
