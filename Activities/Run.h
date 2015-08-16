// Created by Michael Simms on 8/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __RUN__
#define __RUN__

#include "ActivityName.h"
#include "Walking.h"

class Run : public Walking
{
public:
	Run();
	virtual ~Run();
	
	static std::string Name() { return ACTIVITY_NAME_RUNNING; };
	virtual std::string GetName() const { return Run::Name(); };
};

#endif
