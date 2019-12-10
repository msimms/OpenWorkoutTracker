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
						m_author = (const char*)node->content;
					}
					else if (state.compare(ZWO_TAG_NAME) == 0)
					{
						m_name = (const char*)node->content;
					}
					else if (state.compare(ZWO_TAG_DESCRIPTION) == 0)
					{
						m_description = (const char*)node->content;
					}
					else if (state.compare(ZWO_TAG_SPORTTYPE) == 0)
					{
						m_sportType = (const char*)node->content;
					}
					else if (state.compare(ZWO_TAG_TAGS) == 0)
					{
					}
					else if (state.compare(ZWO_TAG_TAG) == 0)
					{
						std::string tagName = (const char*)node->content;
						m_tags.push_back(tagName);
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
		else if (state.compare(ZWO_TAG_TAG) == 0)
		{
			if (attrName.compare(ZWO_ATTR_NAME_NAME) == 0)
			{
				std::string tagName = (const char*)attr->children->content;
				m_tags.push_back(tagName);
			}
		}
		else if (state.compare(ZWO_TAG_WORKOUT_WARMUP) == 0)
		{
			if (attrName.compare(ZWO_ATTR_NAME_DURATION) == 0)
			{
			}
			else if (attrName.compare(ZWO_ATTR_NAME_POWERLOW) == 0)
			{
			}
			else if (attrName.compare(ZWO_ATTR_NAME_POWERHIGH) == 0)
			{
			}
			else if (attrName.compare(ZWO_ATTR_NAME_PACE) == 0)
			{
			}
			m_currentWorkout.m_attributes.insert(std::pair<std::string, std::string>(attrName, (const char*)attr->children->content));
		}
		else if (state.compare(ZWO_TAG_WORKOUT_COOLDOWN) == 0)
		{
			if (attrName.compare(ZWO_ATTR_NAME_DURATION) == 0)
			{
			}
			else if (attrName.compare(ZWO_ATTR_NAME_POWERLOW) == 0)
			{
			}
			else if (attrName.compare(ZWO_ATTR_NAME_POWERHIGH) == 0)
			{
			}
			else if (attrName.compare(ZWO_ATTR_NAME_PACE) == 0)
			{
			}
			m_currentWorkout.m_attributes.insert(std::pair<std::string, std::string>(attrName, (const char*)attr->children->content));
		}
		else if (state.compare(ZWO_TAG_WORKOUT_STEADYSTATE) == 0)
		{
			m_currentWorkout.m_attributes.insert(std::pair<std::string, std::string>(attrName, (const char*)attr->children->content));
		}
		else if (state.compare(ZWO_TAG_WORKOUT_INTERVALS) == 0)
		{
			if (attrName.compare(ZWO_ATTR_NAME_REPEAT) == 0)
			{
			}
			else if (attrName.compare(ZWO_ATTR_NAME_ONDURATION) == 0)
			{
			}
			else if (attrName.compare(ZWO_ATTR_NAME_OFFDURATION) == 0)
			{
			}
			else if (attrName.compare(ZWO_ATTR_NAME_ONPOWER) == 0)
			{
			}
			else if (attrName.compare(ZWO_ATTR_NAME_OFFPOWER) == 0)
			{
			}
			m_currentWorkout.m_attributes.insert(std::pair<std::string, std::string>(attrName, (const char*)attr->children->content));
		}
		else if (state.compare(ZWO_TAG_WORKOUT_FREERIDE) == 0)
		{
			if (attrName.compare(ZWO_ATTR_NAME_DURATION) == 0)
			{
			}
			else if (attrName.compare(ZWO_ATTR_NAME_FLATROAD) == 0)
			{
			}
			m_currentWorkout.m_attributes.insert(std::pair<std::string, std::string>(attrName, (const char*)attr->children->content));
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
		if (m_state.size() == 0)
		{
			return;
		}

		const std::string& state = CurrentState();

		if (state.compare(ZWO_TAG_WORKOUT_WARMUP) == 0)
		{
			m_workouts.push_back(m_currentWorkout);
		}
		else if (state.compare(ZWO_TAG_WORKOUT_COOLDOWN) == 0)
		{
			m_workouts.push_back(m_currentWorkout);
		}
		else if (state.compare(ZWO_TAG_WORKOUT_STEADYSTATE) == 0)
		{
			m_workouts.push_back(m_currentWorkout);
		}
		else if (state.compare(ZWO_TAG_WORKOUT_INTERVALS) == 0)
		{
			m_workouts.push_back(m_currentWorkout);
		}
		else if (state.compare(ZWO_TAG_WORKOUT_FREERIDE) == 0)
		{
			m_workouts.push_back(m_currentWorkout);
		}

		m_currentWorkout.m_attributes.clear();

		XmlFileReader::PopState();
	}
	
	void ZwoFileReader::Clear()
	{
	}
}
