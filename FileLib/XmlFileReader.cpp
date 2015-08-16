// Created by Michael Simms on 9/27/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "XmlFileReader.h"

namespace FileLib
{
	XmlFileReader::XmlFileReader()
	{
	}

	XmlFileReader::~XmlFileReader()
	{
	}

	void ParseNode(XmlFileReader* reader, xmlNode* node)
	{
		for (xmlNode* curNode = node; curNode; curNode = curNode->next)
		{
			if (curNode->type == XML_ELEMENT_NODE)
			{
				reader->PushState((const char*)curNode->name);
			}

			reader->ProcessNode(curNode);
			ParseNode(reader, curNode->children);

			xmlAttr* curAttr = curNode->properties;
			while (curAttr)
			{
				reader->ProcessProperties(curAttr);
				curAttr = curAttr->next;
			}
			if (curNode->type == XML_ELEMENT_NODE)
			{
				reader->PopState();
			}
		}
	}

	bool XmlFileReader::ParseFile(const std::string& fileName)
	{
		bool result = false;

		xmlInitParser();

		// This initialize the library and check potential ABI mismatches between
		// the version it was compiled for and the actual shared.
		LIBXML_TEST_VERSION

		xmlDoc* doc = xmlParseFile(fileName.c_str());
		if (doc)
		{
			xmlNode* rootElement = xmlDocGetRootElement(doc);
			if (rootElement)
			{
				ParseNode(this, rootElement);
				result = true;
			}

			xmlFreeDoc(doc);
		}

		// Cleanup function for the XML library.
		xmlCleanupParser();

		return result;
	}
}
