// Created by Michael Simms on 12/22/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __GPXTAGS__
#define __GPXTAGS__

#pragma once

const std::string GPX_TAG_NAME              = "gpx";

const std::string GPX_TAG_NAME_METADATA     = "metadata";
const std::string GPX_TAG_NAME_NAME         = "name";
const std::string GPX_TAG_NAME_TYPE         = "type";

const std::string GPX_TAG_NAME_TRACK        = "trk";
const std::string GPX_TAG_NAME_TRACKSEGMENT = "trkseg";
const std::string GPX_TAG_NAME_TRACKPOINT   = "trkpt";
const std::string GPX_TAG_NAME_ELEVATION    = "ele";
const std::string GPX_TAG_NAME_TIME         = "time";

const std::string GPX_ATTR_NAME_VERSION     = "version";
const std::string GPX_ATTR_NAME_CREATOR     = "creator";

const std::string GPX_ATTR_NAME_LATITUDE    = "lat";
const std::string GPX_ATTR_NAME_LONGITUDE   = "lon";

const std::string GPX_TAG_NAME_EXTENSIONS   = "extensions";
const std::string GPX_TPX                   = "gpxtpx:TrackPointExtension";
const std::string GPX_TPX_HR                = "gpxtpx:hr";
const std::string GPX_TPX_CADENCE           = "gpxtpx:cad";
const std::string GPX_TPX_POWER             = "power";

#endif
