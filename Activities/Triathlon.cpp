// Created by Michael Simms on 7/25/21.
// Copyright (c) 2021 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "Triathlon.h"

Triathlon::Triathlon() : MovingActivity()
{
}

Triathlon::~Triathlon()
{
}

void Triathlon::ListUsableSensors(std::vector<SensorType>& sensorTypes) const
{
	m_swim.ListUsableSensors(sensorTypes);
	m_bike.ListUsableSensors(sensorTypes);
	m_run.ListUsableSensors(sensorTypes);
}

bool Triathlon::Stop()
{
	return m_swim.Stop() && m_bike.Stop() && m_run.Stop();
}

void Triathlon::Pause()
{
	m_swim.Pause();
	m_bike.Pause();
	m_run.Pause();
}

ActivityAttributeType Triathlon::QueryActivityAttribute(const std::string& attributeName) const
{
	ActivityAttributeType attr;
	attr.valid = false;
	return attr;
}

double Triathlon::CaloriesBurned() const
{
	double calories = m_swim.CaloriesBurned();
	calories += m_bike.CaloriesBurned();
	calories += m_run.CaloriesBurned();
	return 0.0;
}
