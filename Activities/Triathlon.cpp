// Created by Michael Simms on 7/25/21.
// Copyright (c) 2021 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "Triathlon.h"

Triathlon::Triathlon() : MovingActivity()
{
	m_currentSport = TRI_SWIM;
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

bool Triathlon::Start(void)
{
	switch (m_currentSport)
	{
		case TRI_SWIM:
			m_swim.Start();
		case TRI_T1:
			break;
		case TRI_BIKE:
			m_bike.Start();
		case TRI_T2:
			break;
		case TRI_RUN:
			m_run.Start();
		default:
			break;
	}
	return Activity::Start();
}

bool Triathlon::Stop(void)
{
	m_swim.Stop() && m_bike.Stop() && m_run.Stop();
	return Activity::Stop();
}

void Triathlon::Pause(void)
{
	m_swim.Pause();
	m_bike.Pause();
	m_run.Pause();
}

bool Triathlon::ProcessSensorReading(const SensorReading& reading)
{
	switch (m_currentSport)
	{
		case TRI_SWIM:
			return m_swim.ProcessSensorReading(reading);
		case TRI_T1:
			break;
		case TRI_BIKE:
			return m_bike.ProcessSensorReading(reading);
		case TRI_T2:
			break;
		case TRI_RUN:
			return m_run.ProcessSensorReading(reading);
		default:
			break;
	}
	return false;
}

ActivityAttributeType Triathlon::QueryActivityAttribute(const std::string& attributeName) const
{
	if (HasStopped())
	{
		if (attributeName.find("(Swim)") == 0)
			return m_swim.QueryActivityAttribute(attributeName.substr(7));
		if (attributeName.find("(Bike)") == 0)
			return m_bike.QueryActivityAttribute(attributeName.substr(7));
		if (attributeName.find("(Run)") == 0)
			return m_run.QueryActivityAttribute(attributeName.substr(6));
	}
	else
	{
		switch (m_currentSport)
		{
			case TRI_SWIM:
				return m_swim.QueryActivityAttribute(attributeName);
			case TRI_T1:
				break;
			case TRI_BIKE:
				return m_bike.QueryActivityAttribute(attributeName);
			case TRI_T2:
				break;
			case TRI_RUN:
				return m_run.QueryActivityAttribute(attributeName);
			default:
				break;
		}
	}

	ActivityAttributeType attr;
	attr.valid = false;
	return attr;
}

double Triathlon::CaloriesBurned(void) const
{
	double calories = m_swim.CaloriesBurned();
	calories += m_bike.CaloriesBurned();
	calories += m_run.CaloriesBurned();
	return calories;
}

void Triathlon::BuildAttributeList(std::vector<std::string>& attributes) const
{
	m_swim.BuildAttributeList(attributes);
	m_bike.BuildAttributeList(attributes);
	m_run.BuildAttributeList(attributes);
}

void Triathlon::BuildSummaryAttributeList(std::vector<std::string>& attributes) const
{
	std::vector<std::string> swimAttributes;
	std::vector<std::string> bikeAttributes;
	std::vector<std::string> runAttributes;

	m_swim.BuildSummaryAttributeList(swimAttributes);	
	m_bike.BuildSummaryAttributeList(bikeAttributes);
	m_run.BuildSummaryAttributeList(runAttributes);
	
	for (auto iter = swimAttributes.begin(); iter != swimAttributes.end(); ++iter)
	{
		attributes.push_back("(Swim) " + (*iter));
	}
	for (auto iter = bikeAttributes.begin(); iter != bikeAttributes.end(); ++iter)
	{
		attributes.push_back("(Bike) " + (*iter));
	}
	for (auto iter = runAttributes.begin(); iter != runAttributes.end(); ++iter)
	{
		attributes.push_back("(Run) " + (*iter));
	}
}

bool Triathlon::ProcessAccelerometerReading(const SensorReading& reading)
{
	return Activity::ProcessAccelerometerReading(reading);
}
