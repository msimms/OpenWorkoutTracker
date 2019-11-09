// Created by Michael Simms on 8/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "DataExporter.h"
#include "ActivityAttribute.h"
#include "AxisName.h"
#include "Defines.h"
#include "GpxFileWriter.h"
#include "TcxFileWriter.h"
#include "CsvFileWriter.h"
#include "MovingActivity.h"
#include "TcxTags.h"

DataExporter::DataExporter()
{
}

DataExporter::~DataExporter()
{
}

bool DataExporter::NearestSensorReading(uint64_t timeMs, const SensorReadingList& list, SensorReadingList::const_iterator& iter)
{
	while ((iter != list.end()) && ((*iter).time < timeMs))
	{
		++iter;
	}
	while ((iter != list.begin()) && ((*iter).time > timeMs))
	{
		--iter;
	}
	
	if (iter == list.begin() || iter == list.end())
	{
		return false;
	}
	
	uint64_t sensorTime = (*iter).time;
	uint64_t timeDiff;
	if (sensorTime > timeMs)
		timeDiff = sensorTime - timeMs;
	else
		timeDiff = timeMs - sensorTime;
	return (timeDiff < 3000);
}

bool DataExporter::ExportToTcx(const std::string& fileName, Database* const pDatabase, const Activity* const pActivity)
{
	const MovingActivity* const pMovingActivity = dynamic_cast<const MovingActivity* const>(pActivity);
	if (!pMovingActivity)
	{
		return false;
	}

	bool result = false;
	FileLib::TcxFileWriter writer;

	if (writer.CreateFile(fileName))
	{
		if (writer.StartActivity(pActivity->GetType()))
		{
			const CoordinateList& coordinateList = pMovingActivity->GetCoordinates();
			const TimeDistancePairList& distanceList = pMovingActivity->GetDistances();
			LapSummaryList lapList;
			SensorReadingList hrList;
			SensorReadingList cadenceList;
			SensorReadingList powerList;

			pDatabase->RetrieveLaps(pActivity->GetId(), lapList);
			pDatabase->RetrieveSensorReadingsOfType(pActivity->GetId(), SENSOR_TYPE_HEART_RATE, hrList);
			pDatabase->RetrieveSensorReadingsOfType(pActivity->GetId(), SENSOR_TYPE_CADENCE, cadenceList);
			pDatabase->RetrieveSensorReadingsOfType(pActivity->GetId(), SENSOR_TYPE_POWER, powerList);

			CoordinateList::const_iterator coordinateIter = coordinateList.begin();
			TimeDistancePairList::const_iterator distanceIter = distanceList.begin();
			LapSummaryList::const_iterator lapIter = lapList.begin();
			SensorReadingList::const_iterator hrIter = hrList.begin();
			SensorReadingList::const_iterator cadenceIter = cadenceList.begin();
			SensorReadingList::const_iterator powerIter = powerList.begin();

			uint64_t lapStartTimeMs = pActivity->GetStartTimeMs();
			uint64_t lapEndTimeMs = 0;

			bool done = false;

			writer.WriteId((time_t)(lapStartTimeMs / 1000));

			do
			{
				if (lapIter == lapList.end())
				{
					lapEndTimeMs = pActivity->GetEndTimeMs();
					done = true;
				}
				else
				{
					lapEndTimeMs = (*lapIter).startTimeMs;
				}

				if (writer.StartLap(lapStartTimeMs))
				{
					if (writer.StartTrack())
					{
						while ((coordinateIter != coordinateList.end()) && (distanceIter != distanceList.end()))
						{
							const Coordinate& coordinate = (*coordinateIter);
							const TimeDistancePair& timeDistance = (*distanceIter);
							
							if ((coordinate.time > lapEndTimeMs) && (lapEndTimeMs != 0))
							{
								break;
							}

							writer.StartTrackpoint();
							writer.StoreTime(coordinate.time);
							writer.StorePosition(coordinate.latitude, coordinate.longitude);
							writer.StoreAltitudeMeters(coordinate.altitude);

							if (coordinateIter != coordinateList.begin())
							{
								writer.StoreDistanceMeters(timeDistance.distanceM);
								distanceIter++;
							}
							else
							{
								writer.StoreDistanceMeters((double)0.0);
							}

							bool moreHrData = NearestSensorReading(coordinate.time, hrList, hrIter);
							bool moreCadenceData = NearestSensorReading(coordinate.time, cadenceList, cadenceIter);
							bool morePowerData = NearestSensorReading(coordinate.time, powerList, powerIter);
							
							if (moreHrData)
							{
								double rate = (*hrIter).reading.at(ACTIVITY_ATTRIBUTE_HEART_RATE);
								writer.StoreHeartRateBpm((uint8_t)rate);
							}							
							if (moreCadenceData)
							{
								double cadence = (*cadenceIter).reading.at(ACTIVITY_ATTRIBUTE_CADENCE);
								writer.StoreCadenceRpm((uint8_t)cadence);
							}							
							if (morePowerData)
							{
								double power = (*powerIter).reading.at(ACTIVITY_ATTRIBUTE_POWER);
								writer.StartTrackpointExtensions();
								writer.StorePowerInWatts(power);
								writer.EndTrackpointExtensions();
							}
							
							writer.EndTrackpoint();

							coordinateIter++;
						}

						writer.EndTrack();
						
						result = true;
					}
					writer.EndLap();
				}

				lapStartTimeMs = lapEndTimeMs;

				if (lapIter != lapList.end())
				{
					lapIter++;
				}

			} while (!done);

			writer.EndActivity();

			lapList.clear();
			hrList.clear();
			cadenceList.clear();
		}

		writer.CloseFile();
	}
	return result;
}

bool DataExporter::ExportToGpx(const std::string& fileName, Database* const pDatabase, const Activity* const pActivity)
{
	bool result = false;
	FileLib::GpxFileWriter writer;

	if (writer.CreateFile(fileName, APP_NAME))
	{
		CoordinateList coordinateList;
		LapSummaryList lapList;
		SensorReadingList hrList;
		SensorReadingList cadenceList;
		SensorReadingList powerList;
		std::string activityId = pActivity->GetId();

		pDatabase->RetrieveActivityCoordinates(activityId, coordinateList);
		pDatabase->RetrieveLaps(activityId, lapList);
		pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_HEART_RATE, hrList);
		pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_CADENCE, cadenceList);
		pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_POWER, powerList);

		CoordinateList::const_iterator coordinateIter = coordinateList.begin();
		LapSummaryList::const_iterator lapIter = lapList.begin();
		SensorReadingList::const_iterator hrIter = hrList.begin();
		SensorReadingList::const_iterator cadenceIter = cadenceList.begin();
		SensorReadingList::const_iterator powerIter = powerList.begin();

		time_t activityStartTimeSec = 0;
		time_t activityEndTimeSec = 0;

		pDatabase->RetrieveActivityStartAndEndTime(activityId, activityStartTimeSec, activityEndTimeSec);

		uint64_t lapStartTimeMs = (uint64_t)activityStartTimeSec * 1000;
		uint64_t lapEndTimeMs = 0;

		bool done = false;

		writer.WriteMetadata((time_t)(lapStartTimeMs / 1000));

		if (writer.StartTrack())
		{
			writer.WriteName("Untitled");

			do
			{
				if (lapIter == lapList.end())
				{
					lapEndTimeMs = (uint64_t)activityEndTimeSec * 1000;
					done = true;
				}
				else
				{
					lapEndTimeMs = (*lapIter).startTimeMs;
				}

				if (writer.StartTrackSegment())
				{
					while (coordinateIter != coordinateList.end())
					{
						const Coordinate& coordinate = (*coordinateIter);

						if ((coordinate.time > lapEndTimeMs) && (lapEndTimeMs != 0))
						{
							break;
						}

						writer.StartTrackPoint(coordinate.latitude, coordinate.longitude, coordinate.altitude, coordinate.time);

						bool moreHrData = NearestSensorReading(coordinate.time, hrList, hrIter);
						bool moreCadenceData = NearestSensorReading(coordinate.time, cadenceList, cadenceIter);
						bool morePowerData = NearestSensorReading(coordinate.time, powerList, powerIter);

						if (moreHrData || moreCadenceData)
						{
							writer.StartExtensions();
							writer.StartTrackPointExtensions();

							if (moreHrData)
							{
								const SensorReading& reading = (*hrIter);
								double rate = reading.reading.at(ACTIVITY_ATTRIBUTE_HEART_RATE);
								writer.StoreHeartRateBpm((uint8_t)rate);
							}
							if (moreCadenceData)
							{
								const SensorReading& reading = (*cadenceIter);
								double cadence = reading.reading.at(ACTIVITY_ATTRIBUTE_CADENCE);
								writer.StoreCadenceRpm((uint8_t)cadence);
							}
							if (morePowerData)
							{
								const SensorReading& reading = (*powerIter);
								double power = reading.reading.at(ACTIVITY_ATTRIBUTE_POWER);
								writer.StorePowerInWatts((uint32_t)power);
							}

							writer.EndTrackPointExtensions();
							writer.EndExtensions();
						}

						writer.EndTrackPoint();

						coordinateIter++;
					}
					writer.EndTrackSegment();
				}

				if (lapIter != lapList.end())
				{
					lapIter++;
				}

			} while (!done);

			writer.EndTrack();

			result = true;
		}

		coordinateList.clear();
		lapList.clear();
		hrList.clear();
		cadenceList.clear();
		
		writer.CloseFile();
	}
	return result;
}

bool DataExporter::ExportPositionDataToCsv(FileLib::CsvFileWriter& writer, const MovingActivity* const pMovingActivity)
{
	bool result = true;

	const CoordinateList& coordinateList = pMovingActivity->GetCoordinates();
	const TimeDistancePairList& distanceList = pMovingActivity->GetDistances();

	if (coordinateList.size() > 0)
	{
		std::vector<std::string> titles;
		titles.push_back(ACTIVITY_ATTRIBUTE_ELAPSED_TIME);
		titles.push_back(ACTIVITY_ATTRIBUTE_LATITUDE);
		titles.push_back(ACTIVITY_ATTRIBUTE_LONGITUDE);
		titles.push_back(ACTIVITY_ATTRIBUTE_ALTITUDE);
		titles.push_back(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED);

		result = writer.WriteValues(titles);

		CoordinateList::const_iterator coordinateIter = coordinateList.begin();
		TimeDistancePairList::const_iterator distanceIter = distanceList.begin();
		
		while ((coordinateIter != coordinateList.end()) && (distanceIter != distanceList.end()) && result)
		{
			const Coordinate& coordinate = (*coordinateIter);
			const TimeDistancePair& timeDistance = (*distanceIter);
			
			std::vector<double> values;
			values.push_back(coordinate.time);
			values.push_back(coordinate.latitude);
			values.push_back(coordinate.longitude);
			values.push_back(coordinate.altitude);
			
			if (coordinateIter != coordinateList.begin())
			{
				values.push_back(timeDistance.distanceM);
				distanceIter++;
			}
			else
			{
				values.push_back((double)0.0);
			}
			coordinateIter++;
			
			result = writer.WriteValues(values);
		}
	}
	return result;
}

bool DataExporter::ExportAccelerometerDataToCsv(FileLib::CsvFileWriter& writer, const std::string& activityId, Database* const pDatabase)
{
	SensorReadingList accelList;
	bool loaded = pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_ACCELEROMETER, accelList);
	bool result = true;

	if (loaded && (accelList.size() > 0))
	{
		std::vector<std::string> titles;
		titles.push_back(ACTIVITY_ATTRIBUTE_ELAPSED_TIME);
		titles.push_back(ACTIVITY_ATTRIBUTE_X);
		titles.push_back(ACTIVITY_ATTRIBUTE_Y);
		titles.push_back(ACTIVITY_ATTRIBUTE_Z);
		
		result = writer.WriteValues(titles);

		SensorReadingList::const_iterator accelIter = accelList.begin();

		while (accelIter != accelList.end() && result)
		{
			const SensorReading& reading = (*accelIter);

			double x = reading.reading.at(AXIS_NAME_X);
			double y = reading.reading.at(AXIS_NAME_Y);
			double z = reading.reading.at(AXIS_NAME_Z);

			std::vector<double> values;
			values.push_back(reading.time);
			values.push_back(x);
			values.push_back(y);
			values.push_back(z);
			
			result = writer.WriteValues(values);
			
			++accelIter;
		}
	}
	return result;
}

bool DataExporter::ExportHeartRateDataToCsv(FileLib::CsvFileWriter& writer, const std::string& activityId, Database* const pDatabase)
{
	SensorReadingList hrList;
	bool loaded = pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_HEART_RATE, hrList);
	bool result = true;

	if (loaded && (hrList.size() > 0))
	{
		std::vector<std::string> titles;
		titles.push_back(ACTIVITY_ATTRIBUTE_ELAPSED_TIME);
		titles.push_back(ACTIVITY_ATTRIBUTE_HEART_RATE);
		
		result = writer.WriteValues(titles);
		
		SensorReadingList::const_iterator hrIter = hrList.begin();
		
		while (hrIter != hrList.end() && result)
		{
			const SensorReading& reading = (*hrIter);
			
			double rate = reading.reading.at(ACTIVITY_ATTRIBUTE_HEART_RATE);
			
			std::vector<double> values;
			values.push_back(reading.time);
			values.push_back(rate);
			
			result = writer.WriteValues(values);
			
			++hrIter;
		}
	}
	return result;
}

bool DataExporter::ExportCadenceDataToCsv(FileLib::CsvFileWriter& writer, const std::string& activityId, Database* const pDatabase)
{
	SensorReadingList cadenceList;
	bool loaded = pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_CADENCE, cadenceList);
	bool result = true;

	if (loaded && (cadenceList.size() > 0))
	{
		std::vector<std::string> titles;
		titles.push_back(ACTIVITY_ATTRIBUTE_ELAPSED_TIME);
		titles.push_back(ACTIVITY_ATTRIBUTE_CADENCE);
		
		result = writer.WriteValues(titles);
		
		SensorReadingList::const_iterator cadenceIter = cadenceList.begin();
		
		while (cadenceIter != cadenceList.end() && result)
		{
			const SensorReading& reading = (*cadenceIter);
			
			double rate = reading.reading.at(ACTIVITY_ATTRIBUTE_CADENCE);
			
			std::vector<double> values;
			values.push_back(reading.time);
			values.push_back(rate);
			
			result = writer.WriteValues(values);
			
			++cadenceIter;
		}
	}
	return result;
}

bool DataExporter::ExportToCsv(const std::string& fileName, Database* const pDatabase, const Activity* const pActivity)
{
	bool result = false;
	FileLib::CsvFileWriter writer;

	if (writer.CreateFile(fileName))
	{
		const MovingActivity* const pMovingActivity = dynamic_cast<const MovingActivity* const>(pActivity);
		if (pMovingActivity)
		{
			result = ExportPositionDataToCsv(writer, pMovingActivity);
		}
		else
		{
			result = true;
		}

		result &= ExportAccelerometerDataToCsv(writer, pActivity->GetId(), pDatabase);
		result &= ExportHeartRateDataToCsv(writer, pActivity->GetId(), pDatabase);
		result &= ExportCadenceDataToCsv(writer, pActivity->GetId(), pDatabase);

		writer.CloseFile();
	}
	return result;
}

bool DataExporter::Export(FileFormat format, std::string& fileName, Database* const pDatabase, const Activity* const pActivity)
{
	if (pActivity)
	{
		time_t startTime = pActivity->GetStartTimeSecs();

		char buf[32];
		strftime(buf, sizeof(buf) - 1, "%Y-%m-%dT%H-%M-%S", localtime(&startTime));

		fileName.append("/");
		fileName.append(buf);
		fileName.append("-");
		fileName.append(pActivity->GetType());

		switch (format)
		{
			case FILE_UNKNOWN:
				return false;
			case FILE_TEXT:
				return false;
			case FILE_TCX:
				fileName.append(".tcx");
				return ExportToTcx(fileName, pDatabase, pActivity);
			case FILE_GPX:
				fileName.append(".gpx");
				return ExportToGpx(fileName, pDatabase, pActivity);
			case FILE_CSV:
				fileName.append(".csv");
				return ExportToCsv(fileName, pDatabase, pActivity);
			case FILE_ZWO:				
			default:
				return false;
		}
	}
	return false;
}

bool DataExporter::ExportActivitySummary(const ActivitySummaryList& activities, std::string& activityType, std::string& fileName)
{
	bool result = false;
	FileLib::CsvFileWriter writer;

	time_t startTime = time(NULL);
	
	char buf[32];
	strftime(buf, sizeof(buf) - 1, "%Y-%m-%dT%H-%M-%S", localtime(&startTime));
	
	fileName.append("/");
	fileName.append(buf);
	fileName.append("-");
	fileName.append(activityType);
	fileName.append("-Summary.csv");

	if (writer.CreateFile(fileName))
	{
		std::vector<std::string> attributes;
		
		result = true;

		ActivitySummaryList::const_iterator activityIter = activities.begin();
		while (activityIter != activities.end())
		{
			const ActivitySummary& summary = (*activityIter);

			if (summary.type.compare(activityType) == 0)
			{
				const Activity* pActivity = summary.pActivity;

				if (attributes.size() == 0)
				{
					pActivity->BuildSummaryAttributeList(attributes);
					std::sort(attributes.begin(), attributes.end());
					result &= writer.WriteValues(attributes);
				}

				std::vector<std::string> values;

				std::vector<std::string>::const_iterator attrIter = attributes.begin();
				while (attrIter != attributes.end())
				{
					const std::string& attrName = (*attrIter);

					try
					{
						ActivityAttributeType value = summary.summaryAttributes.at(attrName);
						switch (value.valueType)
						{
							case TYPE_NOT_SET:
								values.push_back("-");
								break;
							case TYPE_TIME:
								{
									char buf[32];
									snprintf(buf, sizeof(buf) - 1, "%ld", value.value.timeVal);
									values.push_back(buf);
								}
								break;
							case TYPE_DOUBLE:
								{
									char buf[32];
									snprintf(buf, sizeof(buf) - 1, "%.8lf", value.value.doubleVal);
									values.push_back(buf);
								}
								break;
							case TYPE_INTEGER:
								{
									char buf[32];
									snprintf(buf, sizeof(buf) - 1, "%llu", value.value.intVal);
									values.push_back(buf);
								}
								break;
							default:
								values.push_back("-");
								break;
						}
					}
					catch (...)
					{
						values.push_back("-");
					}

					attrIter++;
				}

				result &= writer.WriteValues(values);
			}

			activityIter++;
		}
		
		result = true;

		writer.CloseFile();
	}

	return result;
}
