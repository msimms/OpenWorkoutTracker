// Created by Michael Simms on 8/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "Database.h"
#include "ActivityAttribute.h"
#include "AxisName.h"

#include <iostream>
#include <stdlib.h>

Database::Database()
{
	m_pDb = NULL;
}

Database::~Database()
{
	Close();
	DeleteStatements();
}

bool Database::Open(const std::string& dbFileName)
{
	return (sqlite3_open(dbFileName.c_str(), &m_pDb) == SQLITE_OK);
}

bool Database::Close(void)
{
	bool result = false;

	if (m_pDb)
	{
		result = (sqlite3_close(m_pDb) == SQLITE_OK);
		m_pDb = NULL;
	}
	return result;
}

bool Database::DoesTableHaveColumn(const std::string& tableName, const std::string& columnName)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	std::string sql = "pragma table_info(";
	sql += tableName;
	sql += ");";

	if (sqlite3_prepare_v2(m_pDb, sql.c_str(), -1, &statement, 0) == SQLITE_OK)
	{
		while ((sqlite3_step(statement) == SQLITE_ROW) && (!result))
		{
			std::string temp;
			temp.append((const char*)sqlite3_column_text(statement, 1));
			result = (temp.compare(columnName) == 0);
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::DoesTableExist(const std::string& tableName)
{
	std::string sql = "select name from sqlite_master where type='table' AND name='";
	sql += tableName;
	sql += "'";

	int result = ExecuteQuery(sql);
	return (result == SQLITE_ROW);
}

bool Database::CreateTables(void)
{
	std::vector<std::string> queries;
	std::string sql;

	if (!DoesTableExist("gear_bike"))
	{
		sql = "create table gear_bike (id integer primary key, gear_id text, name text, description text, " \
			"weight_kg double, wheel_circumference_mm double, time_added unsigned big int, time_retired unsigned big int, last_updated_time big int)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("gear_shoe"))
	{
		sql = "create table gear_shoe (id integer primary key, gear_id text, name text, description text, " \
			"time_added unsigned big int, time_retired unsigned big int, last_updated_time big int)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("gear_service_history"))
	{
		sql = "create table gear_service_history (id integer primary key, gear_id text, service_id text, time_serviced unsigned big int, description text, " \
			"unique(service_id) on conflict replace)";
		queries.push_back(sql);
		sql = "create index gear_service_history_index on gear_service_history (service_id)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("interval_session"))
	{
		sql = "create table interval_session (id integer primary key, session_id text, name text, " \
			"sport text, description text, last_updated_time big int)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("interval_session_segment"))
	{
		sql = "create table interval_session_segment (id integer primary key, session_id text, sets integer," \
			"reps integer, first_value double, second_value double, first_units int, second_units int, position int)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("workout"))
	{
		sql = "create table workout (id integer primary key, workout_id text, type unsigned big int, sport text, " \
			"estimated_stress double, scheduled_time unsigned big int)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("workout_interval"))
	{
		sql = "create table workout_interval (id integer primary key, workout_id text, repeat integer, duration big int, " \
			"power_low double, power_high double, distance double, pace double, recovery_duration big int, recovery_distance double, recovery_pace double)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("pace_plan"))
	{
		sql = "create table pace_plan (id integer primary key, plan_id text, name text, description text, " \
			"target_distance double, target_distance_units integer, target_time integer, target_splits integer, " \
			"target_splits_units integer, route text, last_updated_time big int)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("activity"))
	{
		sql = "create table activity (id integer primary key, activity_id text, user_id text, type text, name text, " \
			"description text, start_time unsigned big int, end_time unsigned big int)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("lap"))
	{
		sql = "create table lap (id integer primary key, activity_id text, start_time unsigned big int, calories_burned double, distance double)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("gps"))
	{
		sql = "create table gps (id integer primary key, activity_id text, time unsigned big int, latitude double, longitude double, altitude double)";
		queries.push_back(sql);
		sql = "create index gps_index on gps (activity_id)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("accelerometer"))
	{
		sql = "create table accelerometer (id integer primary key, activity_id text, time unsigned big int, x double, y double, z double)";
		queries.push_back(sql);
		sql = "create index accelerometer_index on accelerometer (activity_id)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("cadence"))
	{
		sql = "create table cadence (id integer primary key, activity_id text, time unsigned big int, value double)";
		queries.push_back(sql);
		sql = "create index cadence_index on cadence (activity_id)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("hrm"))
	{
		sql = "create table hrm (id integer primary key, activity_id text, time unsigned big int, value double)";
		queries.push_back(sql);
		sql = "create index hrm_index on hrm (activity_id)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("wheel_speed"))
	{
		sql = "create table wheel_speed (id integer primary key, activity_id text, time unsigned big int, value double)";
		queries.push_back(sql);
		sql = "create index wheel_speed_index on wheel_speed (activity_id)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("power_meter"))
	{
		sql = "create table power_meter (id integer primary key, activity_id text, time unsigned big int, value double)";
		queries.push_back(sql);
		sql = "create index power_meter_index on power_meter (activity_id)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("foot_pod"))
	{
		sql = "create table foot_pod (id integer primary key, activity_id text, time unsigned big int, value double)";
		queries.push_back(sql);
		sql = "create index foot_pod_index on foot_pod (activity_id)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("event"))
	{
		sql = "create table event (id integer primary key, activity_id text, time unsigned big int, event_type unsigned int, value unsigned int)";
		queries.push_back(sql);
		sql = "create index event_index on event (activity_id)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("weight"))
	{
		sql = "create table weight (id integer primary key, time unsigned big int, value double)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("tag"))
	{
		sql = "create table tag (id integer primary key, activity_id text, tag text)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("activity_summary"))
	{
		sql = "create table activity_summary (id integer primary key, activity_id text, attribute text, value double, " \
			"start_time unsigned big int, end_time unsigned big int, value_type integer, measure_type integer, units integer, " \
			"unique(activity_id, attribute) on conflict replace)";
		queries.push_back(sql);
		sql = "create index activity_summary_index on activity_summary (activity_id)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("activity_hash"))
	{
		sql = "create table activity_hash (id integer primary key, activity_id text, hash text)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("activity_sync"))
	{
		sql = "create table activity_sync (id integer primary key, activity_id text, destination text, direction integer)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("route"))
	{
		sql = "create table route (id integer primary key, route_id text, name text, description text)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("route_coordinate"))
	{
		sql = "create table route_coordinate (id integer primary key, route_id text, latitude double, longitude double, altitude double)";
		queries.push_back(sql);
	}

	int result = ExecuteQueries(queries);
	return (result == SQLITE_OK || result == SQLITE_DONE);
}

bool Database::DeleteTables(void)
{
	std::vector<std::string> queries;
	std::string sql;
	
	sql = "drop table gear_bike";
	queries.push_back(sql);
	sql = "drop table gear_shoe";
	queries.push_back(sql);
	sql = "drop table gear_service_history";
	queries.push_back(sql);
	sql = "drop table interval_session";
	queries.push_back(sql);
	sql = "drop table interval_session_segment";
	queries.push_back(sql);
	sql = "drop table workout";
	queries.push_back(sql);
	sql = "drop table workout_interval";
	queries.push_back(sql);
	sql = "drop table pace_plan";
	queries.push_back(sql);
	sql = "drop table activity";
	queries.push_back(sql);
	sql = "drop table lap";
	queries.push_back(sql);
	sql = "drop table gps";
	queries.push_back(sql);
	sql = "drop table accelerometer";
	queries.push_back(sql);
	sql = "drop table cadence";
	queries.push_back(sql);
	sql = "drop table hrm";
	queries.push_back(sql);
	sql = "drop table wheel_speed";
	queries.push_back(sql);
	sql = "drop table power_meter";
	queries.push_back(sql);
	sql = "drop table foot_pod";
	queries.push_back(sql);
	sql = "drop table event";
	queries.push_back(sql);
	sql = "drop table weight";
	queries.push_back(sql);
	sql = "drop table tag";
	queries.push_back(sql);
	sql = "drop table activity_summary";
	queries.push_back(sql);
	sql = "drop table activity_hash";
	queries.push_back(sql);
	sql = "drop table activity_sync";
	queries.push_back(sql);
	sql = "drop table route";
	queries.push_back(sql);
	sql = "drop table route_coordinate";
	queries.push_back(sql);

	int result = ExecuteQueries(queries);
	return (result == SQLITE_OK || result == SQLITE_DONE);
}

bool Database::CreateStatements(void)
{
	if (sqlite3_prepare_v2(m_pDb, "insert into accelerometer values (NULL,?,?,?,?,?)", -1, &m_accelerometerInsertStatement, 0) != SQLITE_OK)
		return false;
	if (sqlite3_prepare_v2(m_pDb, "insert into gps values (NULL,?,?,?,?,?)", -1, &m_locationInsertStatement, 0) != SQLITE_OK)
		return false;
	if (sqlite3_prepare_v2(m_pDb, "insert into hrm values (NULL,?,?,?)", -1, &m_heartRateInsertStatement, 0) != SQLITE_OK)
		return false;
	if (sqlite3_prepare_v2(m_pDb, "insert into cadence values (NULL,?,?,?)", -1, &m_cadenceInsertStatement, 0) != SQLITE_OK)
		return false;
	if (sqlite3_prepare_v2(m_pDb, "insert into wheel_speed values (NULL,?,?,?)", -1, &m_wheelSpeedInsertStatement, 0) != SQLITE_OK)
		return false;
	if (sqlite3_prepare_v2(m_pDb, "insert into power_meter values (NULL,?,?,?)", -1, &m_powerInsertStatement, 0) != SQLITE_OK)
		return false;
	if (sqlite3_prepare_v2(m_pDb, "insert into foot_pod values (NULL,?,?,?)", -1, &m_footPodStatement, 0) != SQLITE_OK)
		return false;
	if (sqlite3_prepare_v2(m_pDb, "insert into event values (NULL,?,?,?,?)", -1, &m_eventStatement, 0) != SQLITE_OK)
		return false;
	if (sqlite3_prepare_v2(m_pDb, "select activity_id, attribute, value, start_time, end_time, value_type, measure_type, units from activity_summary where activity_id = ?", -1, &m_selectActivitySummaryStatement, 0) != SQLITE_OK)
		return false;
	if (sqlite3_prepare_v2(m_pDb, "select activity_id from activity_hash where hash = ? limit 1", -1, &m_selectActivityIdFromHashStatement, 0) != SQLITE_OK)
		return false;
	if (sqlite3_prepare_v2(m_pDb, "select hash from activity_hash where activity_id = ? limit 1", -1, &m_selectActivityHashFromIdStatement, 0) != SQLITE_OK)
		return false;
	return true;
}

void Database::DeleteStatements(void)
{
	if (m_accelerometerInsertStatement)
	{
		sqlite3_finalize(m_accelerometerInsertStatement);
	}
	if (m_locationInsertStatement)
	{
		sqlite3_finalize(m_locationInsertStatement);
	}
	if (m_heartRateInsertStatement)
	{
		sqlite3_finalize(m_heartRateInsertStatement);
	}
	if (m_cadenceInsertStatement)
	{
		sqlite3_finalize(m_cadenceInsertStatement);
	}
	if (m_wheelSpeedInsertStatement)
	{
		sqlite3_finalize(m_wheelSpeedInsertStatement);
	}
	if (m_powerInsertStatement)
	{
		sqlite3_finalize(m_powerInsertStatement);
	}
	if (m_footPodStatement)
	{
		sqlite3_finalize(m_footPodStatement);
	}
	if (m_eventStatement)
	{
		sqlite3_finalize(m_eventStatement);
	}
	if (m_selectActivitySummaryStatement)
	{
		sqlite3_finalize(m_selectActivitySummaryStatement);
	}
	if (m_selectActivityIdFromHashStatement)
	{
		sqlite3_finalize(m_selectActivityIdFromHashStatement);
	}
	if (m_selectActivityHashFromIdStatement)
	{
		sqlite3_finalize(m_selectActivityHashFromIdStatement);
	}
}

bool Database::Reset(void)
{
	bool result = DeleteTables();
	DeleteStatements();
	result &= CreateTables();
	result &= CreateStatements();
	return result;
}

bool Database::CreateBike(const Bike& bike)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "insert into gear_bike values (NULL,?,?,?,?,?,?,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, bike.gearId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, bike.name.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 3, bike.description.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_double(statement, 4, bike.weightKg);
		sqlite3_bind_double(statement, 5, bike.computedWheelCircumferenceMm);
		sqlite3_bind_int64(statement, 6, bike.timeAdded);
		sqlite3_bind_int64(statement, 7, bike.timeRetired);
		sqlite3_bind_int64(statement, 8, bike.lastUpdatedTime);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::RetrieveBike(const std::string& gearId, Bike& bike)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select name, description, weight_kg, wheel_circumference_mm, time_added, time_retired, last_updated_time from gear_bike where gear_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, gearId.c_str(), -1, SQLITE_TRANSIENT);

		if (sqlite3_step(statement) == SQLITE_ROW)
		{
			bike.gearId = gearId;
			bike.name.append((const char*)sqlite3_column_text(statement, 0));
			bike.description.append((const char*)sqlite3_column_text(statement, 1));
			bike.weightKg = sqlite3_column_double(statement, 2);
			bike.computedWheelCircumferenceMm = sqlite3_column_double(statement, 3);
			bike.timeAdded = (time_t)sqlite3_column_int64(statement, 4);
			bike.timeRetired = (time_t)sqlite3_column_int64(statement, 5);
			bike.lastUpdatedTime = (time_t)sqlite3_column_int64(statement, 6);
			result = true;
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveAllBikes(std::vector<Bike>& bikes)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select gear_id, name, description, weight_kg, wheel_circumference_mm, time_added, time_retired, last_updated_time from gear_bike order by id", -1, &statement, 0) == SQLITE_OK)
	{
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			Bike bike;
			
			bike.gearId.append((const char*)sqlite3_column_text(statement, 0));
			bike.name.append((const char*)sqlite3_column_text(statement, 1));
			bike.description.append((const char*)sqlite3_column_text(statement, 2));
			bike.weightKg = sqlite3_column_double(statement, 3);
			bike.computedWheelCircumferenceMm = sqlite3_column_double(statement, 4);
			bike.timeAdded = (time_t)sqlite3_column_int64(statement, 5);
			bike.timeRetired = (time_t)sqlite3_column_int64(statement, 6);
			bike.lastUpdatedTime = (time_t)sqlite3_column_int64(statement, 7);

			bikes.push_back(bike);
		}
		
		sqlite3_finalize(statement);
		result = true;
	}
	return result;
}

bool Database::UpdateBike(const Bike& bike)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "update gear_bike set weight_kg = ?, wheel_circumference_mm = ?, name = ?, description = ?, time_added = ?, time_retired = ?, last_updated_time = ? where gear_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_double(statement, 1, bike.weightKg);
		sqlite3_bind_double(statement, 2, bike.computedWheelCircumferenceMm);
		sqlite3_bind_text(statement, 3, bike.name.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 4, bike.description.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(statement, 5, bike.timeAdded);
		sqlite3_bind_int64(statement, 6, bike.timeRetired);
		sqlite3_bind_int64(statement, 7, bike.lastUpdatedTime);
		sqlite3_bind_text(statement, 8, bike.gearId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::DeleteBike(const std::string& gearId)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "delete from gear_bike where gear_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, gearId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::CreateShoe(Shoes& shoes)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "insert into gear_shoe values (NULL,?,?,?,?,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, shoes.gearId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, shoes.name.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 3, shoes.description.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(statement, 4, shoes.timeAdded);
		sqlite3_bind_int64(statement, 5, shoes.timeRetired);
		sqlite3_bind_int64(statement, 6, shoes.lastUpdatedTime);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::RetrieveShoe(const std::string& gearId, Shoes& shoes)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select name, description, time_added, time_retired, last_updated_time from gear_shoe where gear_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, gearId.c_str(), -1, SQLITE_TRANSIENT);

		if (sqlite3_step(statement) == SQLITE_ROW)
		{
			shoes.gearId = gearId;
			shoes.name.append((const char*)sqlite3_column_text(statement, 1));
			shoes.description.append((const char*)sqlite3_column_text(statement, 2));
			shoes.timeAdded = (time_t)sqlite3_column_int64(statement, 3);
			shoes.timeRetired = (time_t)sqlite3_column_int64(statement, 4);
			shoes.lastUpdatedTime = (time_t)sqlite3_column_int64(statement, 5);
			result = true;
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveAllShoes(std::vector<Shoes>& allShoes)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select gear_id, name, description, time_added, time_retired, last_updated_time from gear_shoe order by id", -1, &statement, 0) == SQLITE_OK)
	{
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			Shoes shoes;
			
			shoes.gearId.append((const char*)sqlite3_column_text(statement, 0));
			shoes.name.append((const char*)sqlite3_column_text(statement, 1));
			shoes.description.append((const char*)sqlite3_column_text(statement, 2));
			shoes.timeAdded = (time_t)sqlite3_column_int64(statement, 3);
			shoes.timeRetired = (time_t)sqlite3_column_int64(statement, 4);
			shoes.lastUpdatedTime = (time_t)sqlite3_column_int64(statement, 5);

			allShoes.push_back(shoes);
		}
		
		sqlite3_finalize(statement);
		result = true;
	}
	return result;
}

bool Database::UpdateShoe(Shoes& shoes)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "update gear_shoe set name = ?, description = ?, time_added = ?, time_retired = ?, last_updated_time = ? where gear_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, shoes.name.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, shoes.description.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(statement, 3, shoes.timeAdded);
		sqlite3_bind_int64(statement, 4, shoes.timeRetired);
		sqlite3_bind_int64(statement, 5, shoes.lastUpdatedTime);
		sqlite3_bind_text(statement, 6, shoes.gearId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::DeleteShoe(const std::string& gearId)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "delete from gear_shoe where gear_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, gearId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::CreateServiceHistory(const std::string& gearId, const std::string& serviceId, time_t timeServiced, const std::string& description)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "insert into gear_service_history values (NULL,?,?,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, gearId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, serviceId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(statement, 3, timeServiced);
		sqlite3_bind_text(statement, 4, description.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::RetrieveServiceHistory(const std::string& gearId, std::vector<ServiceHistory>& history)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select service_id, time_serviced, description from gear_service_history where gear_id = ? order by time_serviced", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, gearId.c_str(), -1, SQLITE_TRANSIENT);
		
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			ServiceHistory historyItem;

			historyItem.serviceId.append((const char*)sqlite3_column_text(statement, 0));
			historyItem.timeServiced = (time_t)sqlite3_column_int64(statement, 1);
			historyItem.description.append((const char*)sqlite3_column_text(statement, 2));
			history.push_back(historyItem);
		}
		
		sqlite3_finalize(statement);
		result = true;
	}
	return result;
}

bool Database::UpdateServiceHistory(const std::string& serviceId, time_t timeServiced, const std::string& description)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "update gear_service_history set time_serviced = ?, description = ? where service_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_int64(statement, 1, timeServiced);
		sqlite3_bind_text(statement, 2, description.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 3, serviceId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::DeleteServiceHistory(const std::string& serviceId)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "delete from gear_service_history where service_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, serviceId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::CreateIntervalSession(const std::string& sessionId, const std::string& name, const std::string& sport, const std::string& description)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "insert into interval_session values (NULL,?,?,?,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, sessionId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, name.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 3, sport.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 4, description.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(statement, 5, time(NULL));
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}	
	return result == SQLITE_DONE;
}

bool Database::RetrieveIntervalSession(const std::string& sessionId, std::string& name, std::string& sport, std::string& description)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select name, sport from interval_session where session_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, sessionId.c_str(), -1, SQLITE_TRANSIENT);
		
		if (sqlite3_step(statement) == SQLITE_ROW)
		{
			name.append((const char*)sqlite3_column_text(statement, 0));
			sport.append((const char*)sqlite3_column_text(statement, 1));
			description.append((const char*)sqlite3_column_text(statement, 2));
			result = true;
		}
		
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveIntervalSessions(std::vector<IntervalSession>& sessions)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select session_id, name, sport, description from interval_session order by name", -1, &statement, 0) == SQLITE_OK)
	{
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			IntervalSession session;
			
			session.sessionId.append((const char*)sqlite3_column_text(statement, 0));
			session.name.append((const char*)sqlite3_column_text(statement, 1));
			session.activityType.append((const char*)sqlite3_column_text(statement, 2));
			session.description.append((const char*)sqlite3_column_text(statement, 3));
			sessions.push_back(session);
		}

		sqlite3_finalize(statement);
		result = true;
	}
	return result;
}

bool Database::DeleteIntervalSession(const std::string& sessionId)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "delete from interval_session where session_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, sessionId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::CreateIntervalSegment(const std::string& sessionId, const IntervalSessionSegment& segment)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "insert into interval_session_segment values (NULL,?,?,?,?,?,?,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, sessionId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int(statement, 2, segment.sets);
		sqlite3_bind_int(statement, 3, segment.reps);
		sqlite3_bind_double(statement, 4, segment.firstValue);
		sqlite3_bind_double(statement, 5, segment.secondValue);
		sqlite3_bind_int64(statement, 6, segment.firstUnits);
		sqlite3_bind_int64(statement, 7, segment.secondUnits);
		sqlite3_bind_int(statement, 8, segment.position);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::RetrieveIntervalSegments(const std::string& sessionId, std::vector<IntervalSessionSegment>& segments)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "select id, sets, reps, first_value, second_value, first_units, second_units, position from interval_session_segment where session_id = ? order by id", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, sessionId.c_str(), -1, SQLITE_TRANSIENT);
		
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			IntervalSessionSegment segment;
			
			segment.segmentId = sqlite3_column_int64(statement, 0);
			segment.sets = (uint8_t)sqlite3_column_int(statement, 1);
			segment.reps = (uint8_t)sqlite3_column_int(statement, 2);
			segment.firstValue = (double)sqlite3_column_double(statement, 3);
			segment.secondValue = (double)sqlite3_column_double(statement, 4);
			segment.firstUnits = (IntervalUnit)sqlite3_column_int64(statement, 5);
			segment.secondUnits = (IntervalUnit)sqlite3_column_int64(statement, 6);
			segment.position = (uint8_t)sqlite3_column_int(statement, 7);
			segments.push_back(segment);
		}
		
		sqlite3_finalize(statement);
		result = true;
	}
	return result;
}

bool Database::DeleteIntervalSegment(uint64_t segmentId)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "delete from interval_session_segment where id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_int64(statement, 1, segmentId);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::DeleteIntervalSegmentsForSession(const std::string& sessionId)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "delete from interval_session_segment where session_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, sessionId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::CreateWorkout(const Workout& workout)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "insert into workout values (NULL,?,?,?,?,?)", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, workout.GetId().c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(statement, 2, workout.GetType());
		sqlite3_bind_text(statement, 3, workout.GetActivityType().c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_double(statement, 4, workout.GetEstimatedIntensityScore());
		sqlite3_bind_int64(statement, 5, workout.GetScheduledTime());
		result = sqlite3_step(statement) == SQLITE_DONE;
		sqlite3_finalize(statement);

		// Save the intervals too.
		std::vector<WorkoutInterval> intervals = workout.GetIntervals();
		for (auto intervalIter = intervals.begin(); intervalIter != intervals.end(); ++intervalIter)
		{
			result &= this->CreateWorkoutInterval(workout, (*intervalIter));
		}
	}
	return result;
}

bool Database::RetrieveWorkout(const std::string& workoutId, Workout& workout)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "select type, sport, estimated_stress, scheduled_time from workout where workout_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		result = true;

		sqlite3_bind_text(statement, 1, workoutId.c_str(), -1, SQLITE_TRANSIENT);

		if (sqlite3_step(statement) == SQLITE_ROW)
		{
			std::string activityType;

			WorkoutType workoutType = (WorkoutType)sqlite3_column_int64(statement, 0);
			activityType.append((const char*)sqlite3_column_text(statement, 1));
			double estimatedStress = (double)sqlite3_column_double(statement, 2);
			time_t scheduledTime = (time_t)sqlite3_column_int64(statement, 3);

			workout.SetId(workoutId);
			workout.SetActivityType(activityType);
			workout.SetType(workoutType);
			workout.SetEstimatedIntensityScore(estimatedStress);
			workout.SetScheduledTime(scheduledTime);

			// Retrieve the intervals too.
			result &= this->RetrieveWorkoutIntervals(workout);
		}

		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveWorkouts(std::vector<Workout>& workouts)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "select workout_id, type, sport, estimated_stress, scheduled_time from workout order by scheduled_time", -1, &statement, 0) == SQLITE_OK)
	{
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			std::string workoutId;
			std::string activityType;

			workoutId.append((const char*)sqlite3_column_text(statement, 0));
			WorkoutType workoutType = (WorkoutType)sqlite3_column_int64(statement, 1);
			activityType.append((const char*)sqlite3_column_text(statement, 2));
			double estimatedIntensity = (double)sqlite3_column_double(statement, 3);
			time_t scheduledTime = (time_t)sqlite3_column_int64(statement, 4);

			Workout workoutObj;
			workoutObj.SetId(workoutId);
			workoutObj.SetActivityType(activityType);
			workoutObj.SetType(workoutType);
			workoutObj.SetEstimatedIntensityScore(estimatedIntensity);
			workoutObj.SetScheduledTime(scheduledTime);

			// Retrieve the intervals too.
			result &= this->RetrieveWorkoutIntervals(workoutObj);

			workouts.push_back(workoutObj);
		}

		sqlite3_finalize(statement);
		result = true;
	}
	return result;
}

bool Database::DeleteWorkout(const std::string& workoutId)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "delete from workout where workout_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, workoutId.c_str(), -1, SQLITE_TRANSIENT);
		result = (sqlite3_step(statement) == SQLITE_DONE);
		sqlite3_finalize(statement);
		
		// Delete the intervals too.
		result &= this->DeleteWorkoutIntervals(workoutId);
	}
	return result;
}

bool Database::DeleteAllWorkouts(void)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "delete from workout", -1, &statement, 0) == SQLITE_OK)
	{
		result = (sqlite3_step(statement) == SQLITE_DONE);
		sqlite3_finalize(statement);
		
		// Delete the intervals too.
		result &= this->DeleteAllWorkoutIntervals();
	}
	return result;
}

bool Database::CreateWorkoutInterval(const Workout& workout, const WorkoutInterval& interval)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "insert into workout_interval values (NULL,?,?,?,?,?,?,?,?,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, workout.GetId().c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int(statement, 2, interval.m_repeat);
		sqlite3_bind_int64(statement, 3, interval.m_duration);
		sqlite3_bind_double(statement, 4, interval.m_powerLow);
		sqlite3_bind_double(statement, 5, interval.m_powerHigh);
		sqlite3_bind_double(statement, 6, interval.m_distance);
		sqlite3_bind_double(statement, 7, interval.m_pace);
		sqlite3_bind_int64(statement, 8, interval.m_recoveryDuration);
		sqlite3_bind_double(statement, 9, interval.m_recoveryDistance);
		sqlite3_bind_double(statement, 10, interval.m_recoveryPace);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::RetrieveWorkoutIntervals(Workout& workout)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "select repeat, duration, power_low, power_high, distance, pace, recovery_duration, recovery_distance, recovery_pace from workout_interval where workout_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		if (sqlite3_bind_text(statement, 1, workout.GetId().c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK)
		{
			while (sqlite3_step(statement) == SQLITE_ROW)
			{
				WorkoutInterval interval;
				
				interval.m_repeat = (uint8_t)sqlite3_column_int(statement, 0);
				interval.m_duration = (uint64_t)sqlite3_column_int64(statement, 1);
				interval.m_powerLow = (double)sqlite3_column_double(statement, 2);
				interval.m_powerHigh = (double)sqlite3_column_double(statement, 3);
				interval.m_distance = (double)sqlite3_column_double(statement, 4);
				interval.m_pace = (double)sqlite3_column_double(statement, 5);
				interval.m_recoveryDuration = (uint64_t)sqlite3_column_int64(statement, 6);
				interval.m_recoveryDistance = (double)sqlite3_column_double(statement, 7);
				interval.m_recoveryPace = (double)sqlite3_column_double(statement, 8);
				
				workout.AddInterval(interval);
			}
		}

		sqlite3_finalize(statement);
		result = true;
	}
	return result;
}

bool Database::DeleteWorkoutIntervals(const std::string& workoutId)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "delete from workout_interval where workout_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, workoutId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::DeleteAllWorkoutIntervals(void)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "delete from workout_interval", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::CreatePacePlan(const PacePlan& plan)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "insert into pace_plan values (NULL,?,?,?,?,?,?,?,?,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, plan.planId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, plan.name.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 3, plan.description.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_double(statement, 4, plan.targetDistance);
		sqlite3_bind_int64(statement, 5, plan.targetTime);
		sqlite3_bind_int64(statement, 6, plan.targetSplits);
		sqlite3_bind_int(statement, 7, plan.distanceUnits);
		sqlite3_bind_int(statement, 8, plan.splitsUnits);
		sqlite3_bind_text(statement, 9, plan.route.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(statement, 10, plan.lastUpdatedTime);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}	
	return result == SQLITE_DONE;
}

bool Database::RetrievePacePlans(std::vector<PacePlan>& plans)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "select plan_id, name, description, target_distance, target_distance_units, target_time, target_splits, target_splits_units, route, last_updated_time from pace_plan", -1, &statement, 0) == SQLITE_OK)
	{
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			PacePlan plan;

			plan.planId.append((const char*)sqlite3_column_text(statement, 0));
			plan.name.append((const char*)sqlite3_column_text(statement, 1));
			plan.description.append((const char*)sqlite3_column_text(statement, 2));
			plan.targetDistance = sqlite3_column_double(statement, 3);
			plan.distanceUnits = (UnitSystem)sqlite3_column_int(statement, 4);
			plan.targetTime = (time_t)sqlite3_column_int64(statement, 5);
			plan.targetSplits = (time_t)sqlite3_column_int64(statement, 6);
			plan.splitsUnits = (UnitSystem)sqlite3_column_int(statement, 7);
			plan.route.append((const char*)sqlite3_column_text(statement, 8));
			plan.lastUpdatedTime = (time_t)sqlite3_column_int64(statement, 9);

			plans.push_back(plan);
		}

		sqlite3_finalize(statement);
		result = true;
	}
	return result;
}

bool Database::UpdatePacePlan(const PacePlan& plan)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "update pace_plan set name = ?, description = ?, target_distance = ?, target_distance_units = ?, target_time = ?, target_splits = ?, target_splits_units = ?, route = ?, last_updated_time = ? where plan_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, plan.name.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, plan.description.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_double(statement, 3, plan.targetDistance);
		sqlite3_bind_int(statement, 4, plan.distanceUnits);
		sqlite3_bind_int64(statement, 5, plan.targetTime);
		sqlite3_bind_int64(statement, 6, plan.targetSplits);
		sqlite3_bind_int(statement, 7, plan.splitsUnits);
		sqlite3_bind_text(statement, 8, plan.route.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(statement, 9, plan.lastUpdatedTime);
		sqlite3_bind_text(statement, 10, plan.planId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::DeletePacePlan(const std::string& planId)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "delete from pace_plan where plan_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, planId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::CreateRoute(const std::string& routeId, const std::string& name, const std::string& description)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "insert into route (id,route_id,name,description) values (NULL,?,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		std::string activityName;
		
		sqlite3_bind_text(statement, 1, routeId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, name.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 3, description.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::CreateRoutePoint(const std::string& routeId, const Coordinate& coordinate)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "insert into route_coordinate (id,route_id,latitude,longitude,altitude) values (NULL,?,?,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		std::string activityName;
		
		sqlite3_bind_text(statement, 1, routeId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_double(statement, 2, coordinate.latitude);
		sqlite3_bind_double(statement, 3, coordinate.longitude);
		sqlite3_bind_double(statement, 4, coordinate.altitude);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::RetrieveRoutes(std::vector<Route>& routes)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select route_id,name,description from route", -1, &statement, 0) == SQLITE_OK)
	{
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			Route route;
			
			route.routeId.append((const char*)sqlite3_column_text(statement, 0));
			route.name.append((const char*)sqlite3_column_text(statement, 1));
			route.description.append((const char*)sqlite3_column_text(statement, 2));
			this->RetrieveRouteCoordinates(route.routeId, route.coordinates);
			
			routes.push_back(route);
		}
		
		sqlite3_finalize(statement);
		result = true;
	}
	return result;
}

bool Database::RetrieveRoute(const std::string& routeId)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "select name,description from route where route_id = ? limit 1", -1, &statement, 0) == SQLITE_OK)
	{
		if (sqlite3_bind_text(statement, 1, routeId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK)
		{
			if (sqlite3_step(statement) == SQLITE_ROW)
			{
				result = true;
			}
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveRouteCoordinates(const std::string& routeId, CoordinateList& coordinates)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	coordinates.clear();
	
	if (sqlite3_prepare_v2(m_pDb, "select latitude,longitude,altitude from route_coordinate where route_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		if (sqlite3_bind_text(statement, 1, routeId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK)
		{
			coordinates.reserve(1024);

			while (sqlite3_step(statement) == SQLITE_ROW)
			{
				Coordinate coordinate;
				
				coordinate.time      = 0;
				coordinate.latitude  = sqlite3_column_double(statement, 0);
				coordinate.longitude = sqlite3_column_double(statement, 1);
				coordinate.altitude  = sqlite3_column_double(statement, 2);
				coordinate.horizontalAccuracy = (double)0.0;
				coordinate.verticalAccuracy   = (double)0.0;
				coordinates.push_back(coordinate);
			}
			
			result = true;
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::DeleteRoute(const std::string& routeId)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "delete from route where route_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, routeId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::DeleteRouteCoordinates(const std::string& routeId)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "delete from route_coordinate where route_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, routeId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::StartActivity(const std::string& activityId, const std::string& userId, const std::string& activityType, const std::string& activityDescription, time_t startTime)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "insert into activity (id,activity_id,user_id,type,name,description,start_time,end_time) values (NULL,?,?,?,?,?,?,0)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		std::string activityName;

		sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, userId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 3, activityType.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 4, activityName.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 5, activityDescription.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(statement, 6, startTime);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::StopActivity(time_t endTime, const std::string& activityId)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "update activity set end_time = ? where activity_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_int64(statement, 1, endTime);
		sqlite3_bind_text(statement, 2, activityId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::DeleteActivity(const std::string& activityId)
{
	std::vector<std::string> queries;
	std::ostringstream sqlStream;

	sqlStream << "delete from activity where activity_id = '" << activityId << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

	sqlStream << "delete from lap where activity_id = '" << activityId << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

	sqlStream << "delete from gps where activity_id = '" << activityId << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

	sqlStream << "delete from accelerometer where activity_id = '" << activityId << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

	sqlStream << "delete from cadence where activity_id = '" << activityId << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

	sqlStream << "delete from hrm where activity_id = '" << activityId << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

	sqlStream << "delete from wheel_speed where activity_id = '" << activityId << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

	sqlStream << "delete from power_meter where activity_id = '" << activityId << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

	sqlStream << "delete from foot_pod where activity_id = '" << activityId << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

	sqlStream << "delete from event where activity_id = '" << activityId << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

	sqlStream << "delete from tag where activity_id = '" << activityId << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

	sqlStream << "delete from activity_summary where activity_id = '" << activityId << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

	int result = ExecuteQueries(queries);
	return (result == SQLITE_OK || result == SQLITE_DONE);
}

bool Database::RetrieveActivity(const std::string& activityId, ActivitySummary& summary)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "select user_id, type, name, start_time, end_time from activity where activity_id = ? limit 1", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);

		if (sqlite3_step(statement) == SQLITE_ROW)
		{
			summary.activityId = activityId;
			summary.userId = sqlite3_column_int64(statement, 0);
			summary.type.append((const char*)sqlite3_column_text(statement, 1));
			summary.name.append((const char*)sqlite3_column_text(statement, 2));
			summary.startTime = (time_t)sqlite3_column_int64(statement, 3);
			summary.endTime = (time_t)sqlite3_column_int64(statement, 4);
			summary.pActivity = NULL;
			result = true;
		}
		
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveActivities(ActivitySummaryList& activities)
{
	const size_t SIZE_INCREMENT = 128;

	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select activity_id, user_id, type, name, description, start_time, end_time from activity order by start_time", -1, &statement, 0) == SQLITE_OK)
	{
		activities.reserve(SIZE_INCREMENT);

		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			ActivitySummary summary;

			summary.activityId.append((const char*)sqlite3_column_text(statement, 0));
			summary.userId = sqlite3_column_int64(statement, 1);
			summary.type.append((const char*)sqlite3_column_text(statement, 2));
			const char* name = (const char*)sqlite3_column_text(statement, 3);
			if (name)
				summary.name.append(name);
			const char* desc = (const char*)sqlite3_column_text(statement, 4);
			if (desc)
				summary.description.append(desc);
			summary.startTime = (time_t)sqlite3_column_int64(statement, 5);
			summary.endTime = (time_t)sqlite3_column_int64(statement, 6);
			summary.pActivity = NULL;

			activities.push_back(std::move(summary));
		}

		sqlite3_finalize(statement);
		result = true;
	}
	return result;
}

bool Database::MergeActivities(const std::string& activityId1, const std::string& activityId2)
{
	std::vector<std::string> queries;
	std::ostringstream sqlStream;
		
	sqlStream << "update lap set activity_id = '" << activityId1 << "' where activity_id = '" << activityId2 << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();
	
	sqlStream << "update gps set activity_id = '" << activityId1 << "' where activity_id = '" << activityId2 << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();
	
	sqlStream << "update accelerometer set activity_id = '" << activityId1 << "' where activity_id = '" << activityId2 << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

	sqlStream << "update cadence set activity_id = '" << activityId1 << "' where activity_id = '" << activityId2 << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

	sqlStream << "update hrm set activity_id = '" << activityId1 << "' where activity_id = '" << activityId2 << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

	sqlStream << "update wheel_speed set activity_id = '" << activityId1 << "' where activity_id = '" << activityId2 << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();
	
	sqlStream << "update power_meter set activity_id = '" << activityId1 << "' where activity_id = '" << activityId2 << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

	sqlStream << "update foot_pod set activity_id = '" << activityId1 << "' where activity_id = '" << activityId2 << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();
	
	sqlStream << "update tag set activity_id = '" << activityId1 << "' where activity_id = '" << activityId2 << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

	sqlStream << "delete from activity_summary where activity_id = '" << activityId2 << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();
	
	sqlStream << "delete from activity where activity_id = '" << activityId2 << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();
	
	int result = ExecuteQueries(queries);
	return (result == SQLITE_OK || result == SQLITE_DONE);
}

bool Database::RetrieveActivityStartAndEndTime(const std::string& activityId, time_t& startTime, time_t& endTime)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select start_time,end_time from activity where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);

		if (sqlite3_step(statement) == SQLITE_ROW)
		{
			startTime = (time_t)sqlite3_column_int64(statement, 0);
			endTime = (time_t)sqlite3_column_int64(statement, 1);
			result = true;
		}

		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::UpdateActivityStartTime(const std::string& activityId, time_t startTime)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "update activity set start_time = ? where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_int64(statement, 1, startTime);
		sqlite3_bind_text(statement, 2, activityId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::UpdateActivityEndTime(const std::string& activityId, time_t endTime)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "update activity set end_time = ? where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_int64(statement, 1, endTime);
		sqlite3_bind_text(statement, 2, activityId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveActivityName(const std::string& activityId, std::string& name)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select name from activity where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		
		if (sqlite3_step(statement) == SQLITE_ROW)
		{
			if (sqlite3_column_bytes(statement, 0) > 0)
			{
				name = (const char*)sqlite3_column_text(statement, 0);
				result = true;
			}
		}

		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::UpdateActivityName(const std::string& activityId, const std::string& name)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "update activity set name = ? where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, name.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, activityId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::UpdateActivityType(const std::string& activityId, const std::string& activityType)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "update activity set type = ? where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, activityType.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, activityId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::UpdateActivityDescription(const std::string& activityId, const std::string& description)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "update activity set description = ? where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, description.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, activityId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::CreateLap(const std::string& activityId, const LapSummary& lap)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "insert into lap values (NULL,?,?,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(statement, 2, lap.startTimeMs);
		sqlite3_bind_double(statement, 3, lap.startingCalorieCount);
		sqlite3_bind_double(statement, 4, lap.startingDistanceMeters);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::RetrieveLaps(const std::string& activityId, LapSummaryList& laps)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "select start_time, calories_burned, distance from lap where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);

		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			LapSummary lap;

			lap.startTimeMs = (uint64_t)sqlite3_column_int64(statement, 0);
			lap.startingCalorieCount = (double)sqlite3_column_int64(statement, 1);
			lap.startingDistanceMeters = (double)sqlite3_column_int64(statement, 2);
			laps.push_back(lap);
		}

		sqlite3_finalize(statement);
		result = true;
	}
	return result;
}

bool Database::CreateTag(const std::string& activityId, const std::string& tag)
{
	sqlite3_stmt* statement = NULL;
	
	if (tag.length() == 0)
	{
		return false;
	}

	int result = sqlite3_prepare_v2(m_pDb, "insert into tag values (NULL,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, tag.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;	
}

bool Database::RetrieveTags(const std::string& activityId, std::vector<std::string>& tags)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select tag from tag where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			std::string tag = (const char*)sqlite3_column_text(statement, 0);
			tags.push_back(tag);
		}
		
		sqlite3_finalize(statement);
		result = true;
	}
	return result;
}

bool Database::DeleteTag(const std::string& activityId, const std::string& tag)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "delete from tag where activity_id = ? and tag = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, tag.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::SearchForTags(const std::string& searchStr, std::vector<std::string>& matchingActivities)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (searchStr.length() == 0)
	{
		return false;
	}
	
	std::string sql = "select activity_id from tag where tag like '%";
	sql += searchStr;
	sql += "%'";

	if (sqlite3_prepare_v2(m_pDb, sql.c_str(), -1, &statement, 0) == SQLITE_OK)
	{
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			std::string id = (const char*)sqlite3_column_text(statement, 0);
			matchingActivities.push_back(id);
		}

		sqlite3_finalize(statement);
		result = true;
	}
	return result;
}

bool Database::CreateSummaryData(const std::string& activityId, const std::string& attribute, ActivityAttributeType value)
{
	sqlite3_stmt* statement = NULL;

	if (attribute.length() == 0)
	{
		return false;
	}
	if (value.valid == false)
	{
		return false;
	}

	int result = sqlite3_prepare_v2(m_pDb, "insert into activity_summary values (NULL,?,?,?,?,?,?,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		bool valid = true;

		sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, attribute.c_str(), -1, SQLITE_TRANSIENT);

		switch (value.valueType)
		{
			case TYPE_DOUBLE:
				sqlite3_bind_double(statement, 3, value.value.doubleVal);
				break;
			case TYPE_INTEGER:
				sqlite3_bind_double(statement, 3, value.value.intVal);
				break;
			case TYPE_TIME:
				sqlite3_bind_double(statement, 3, value.value.timeVal);
				break;
			case TYPE_NOT_SET:
				valid = false;
				break;
		}
		if (valid)
		{
			sqlite3_bind_int64(statement, 4, value.startTime);
			sqlite3_bind_int64(statement, 5, value.endTime);
			sqlite3_bind_int(statement, 6, value.valueType);
			sqlite3_bind_int(statement, 7, value.measureType);
			sqlite3_bind_int(statement, 8, value.unitSystem);
			result = sqlite3_step(statement);
		}
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::RetrieveSummaryData(const std::string& activityId, ActivityAttributeMap& values)
{
	bool result = false;

	values.clear();

	sqlite3_bind_text(m_selectActivitySummaryStatement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);

	while (sqlite3_step(m_selectActivitySummaryStatement) == SQLITE_ROW)
	{
		std::string attributeName;
		ActivityAttributeType value;

		attributeName.append((const char*)sqlite3_column_text(m_selectActivitySummaryStatement, 1));
		if (attributeName.length() > 0)
		{
			value.startTime = (u_int64_t)sqlite3_column_int64(m_selectActivitySummaryStatement, 3);
			value.endTime = (u_int64_t)sqlite3_column_int64(m_selectActivitySummaryStatement, 4);
			value.valueType = (ActivityAttributeValueType)sqlite3_column_int(m_selectActivitySummaryStatement, 5);
			value.measureType = (ActivityAttributeMeasureType)sqlite3_column_int(m_selectActivitySummaryStatement, 6);
			value.unitSystem = (UnitSystem)sqlite3_column_int(m_selectActivitySummaryStatement, 7);
			
			switch (value.valueType)
			{
				case TYPE_DOUBLE:
					value.value.doubleVal = sqlite3_column_double(m_selectActivitySummaryStatement, 2);
					value.valid = true;
					break;
				case TYPE_INTEGER:
					value.value.intVal = sqlite3_column_double(m_selectActivitySummaryStatement, 2);
					value.valid = true;
					break;
				case TYPE_TIME:
					value.value.timeVal = sqlite3_column_double(m_selectActivitySummaryStatement, 2);
					value.valid = true;
					break;
				case TYPE_NOT_SET:
					value.valid = false;
					break;
			}

			values.insert(std::make_pair(attributeName, value));
			result = true;
		}
	}

	sqlite3_clear_bindings(m_selectActivitySummaryStatement);
	sqlite3_reset(m_selectActivitySummaryStatement);

	return result;
}

bool Database::CreateActivityHash(const std::string& activityId, const std::string& hash)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "insert into activity_hash values (NULL,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, hash.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::RetrieveActivityIdFromHash(const std::string& hash, std::string& activityId)
{
	bool result = false;

	sqlite3_bind_text(m_selectActivityIdFromHashStatement, 1, hash.c_str(), -1, SQLITE_TRANSIENT);

	if (sqlite3_step(m_selectActivityIdFromHashStatement) == SQLITE_ROW)
	{
		activityId = (const char*)sqlite3_column_text(m_selectActivityIdFromHashStatement, 0);
		result = true;
	}

	sqlite3_clear_bindings(m_selectActivityIdFromHashStatement);
	sqlite3_reset(m_selectActivityIdFromHashStatement);

	return result;
}

bool Database::RetrieveHashForActivityId(const std::string& activityId, std::string& hash)
{
	bool result = false;

	sqlite3_bind_text(m_selectActivityHashFromIdStatement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);

	if (sqlite3_step(m_selectActivityHashFromIdStatement) == SQLITE_ROW)
	{
		hash = (const char*)sqlite3_column_text(m_selectActivityHashFromIdStatement, 0);
		result = true;
	}

	sqlite3_clear_bindings(m_selectActivityHashFromIdStatement);
	sqlite3_reset(m_selectActivityHashFromIdStatement);

	return result;
}

bool Database::UpdateActivityHash(const std::string& activityId, const std::string& hash)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "update activity_hash set hash = ? where activity_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, hash.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, activityId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::CreateActivitySync(const std::string& activityId, const std::string& destination)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "insert into activity_sync values (NULL,?,?,1)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, destination.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::RetrieveSyncDestinationsForActivityId(const std::string& activityId, std::vector<std::string>& destinations)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "select destination from activity_sync where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		if (sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK)
		{
			while (sqlite3_step(statement) == SQLITE_ROW)
			{
				std::string destination = (const char*)sqlite3_column_text(statement, 0);
				destinations.push_back(destination);
			}
			result = true;
		}

		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveSyncDestinations(std::map<std::string, std::vector<std::string> >& syncHistory)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "select activity_id, destination from activity_sync", -1, &statement, 0) == SQLITE_OK)
	{
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			std::string activityId = (const char*)sqlite3_column_text(statement, 0);
			std::string destination = (const char*)sqlite3_column_text(statement, 1);

			if (syncHistory.find(activityId) == syncHistory.end())
			{
				std::vector<std::string> dests;

				dests.push_back(destination);
				syncHistory.insert(std::make_pair(activityId, dests));
			}
			else
			{
				std::vector<std::string>& dests = syncHistory.at(activityId);

				dests.push_back(destination);
			}
		}
		result = true;

		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::CreateWeightMeasurement(time_t measurementTime, double weightKg)
{
	int result = SQLITE_ERROR;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "insert into weight values (NULL,?,?)", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_int64(statement,  1, measurementTime);
		sqlite3_bind_double(statement, 2, weightKg);

		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::RetrieveWeightMeasurementForTime(time_t measurementTime, double& weightKg)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "select value from weight where time = ?", -1, &statement, 0) == SQLITE_OK)
	{
		if (sqlite3_bind_int64(statement, 1, measurementTime) == SQLITE_OK)
		{
			if (sqlite3_step(statement) == SQLITE_ROW)
			{
				weightKg = sqlite3_column_double(statement, 0);
				result = true;
			}
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveNearestWeightMeasurement(time_t measurementTime, double& weightKg)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
 
	if (sqlite3_prepare_v2(m_pDb, "select time, value from weight order by time asc", -1, &statement, 0) == SQLITE_OK)
	{
		uint64_t currentTime = 0;
		uint64_t lastTime = 0;
		
		double currentWeight = (double)0.0;
		double lastWeight = (double)0.0;

		while ((sqlite3_step(statement) == SQLITE_ROW) && (currentTime < measurementTime))
		{
			lastTime = currentTime;
			lastWeight = currentWeight;
			currentTime = (u_int64_t)sqlite3_column_int64(statement, 0);
			currentWeight = sqlite3_column_double(statement, 1);
		}

		if (currentTime > 0)
		{
			if (lastTime == 0)
			{
				weightKg = currentWeight;
			}
			else
			{
				weightKg = lastWeight + (currentWeight - lastWeight) * (measurementTime - lastTime) / (currentTime - lastTime);
			}
			result = true;
		}

		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveNewestWeightMeasurement(time_t& measurementTime, double& weightKg)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select time, value from weight order by time desc limit 1", -1, &statement, 0) == SQLITE_OK)
	{
		if (sqlite3_step(statement) == SQLITE_ROW)
		{
			measurementTime = (time_t)sqlite3_column_int64(statement, 0);
			weightKg = sqlite3_column_double(statement, 1);
			result = true;
		}
		
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveAllWeightMeasurements(std::vector<std::pair<time_t, double>>& measurements)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select time, value from weight order by time desc", -1, &statement, 0) == SQLITE_OK)
	{
		result = true;

		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			time_t measurementTime = (time_t)sqlite3_column_int64(statement, 0);
			double weightKg = sqlite3_column_double(statement, 1);

			measurements.push_back(std::make_pair(measurementTime, weightKg));
		}
		
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::CreateAccelerometerReading(const std::string& activityId, const SensorReading& reading)
{
	int result = SQLITE_ERROR;
	
	try
	{
		sqlite3_bind_text(m_accelerometerInsertStatement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(m_accelerometerInsertStatement, 2, reading.time);
		sqlite3_bind_double(m_accelerometerInsertStatement, 3, reading.reading.at(AXIS_NAME_X));
		sqlite3_bind_double(m_accelerometerInsertStatement, 4, reading.reading.at(AXIS_NAME_Y));
		sqlite3_bind_double(m_accelerometerInsertStatement, 5, reading.reading.at(AXIS_NAME_Z));

		result = sqlite3_step(m_accelerometerInsertStatement);

		sqlite3_clear_bindings(m_accelerometerInsertStatement);
		sqlite3_reset(m_accelerometerInsertStatement);
	}
	catch (...)
	{
	}
	return result == SQLITE_DONE;
}

bool Database::CreateLocationReading(const std::string& activityId, const SensorReading& reading)
{
	int result = SQLITE_ERROR;

	try
	{
		sqlite3_bind_text(m_locationInsertStatement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(m_locationInsertStatement, 2, reading.time);
		sqlite3_bind_double(m_locationInsertStatement, 3, reading.reading.at(ACTIVITY_ATTRIBUTE_LATITUDE));
		sqlite3_bind_double(m_locationInsertStatement, 4, reading.reading.at(ACTIVITY_ATTRIBUTE_LONGITUDE));
		sqlite3_bind_double(m_locationInsertStatement, 5, reading.reading.at(ACTIVITY_ATTRIBUTE_ALTITUDE));

		result = sqlite3_step(m_locationInsertStatement);

		sqlite3_clear_bindings(m_locationInsertStatement);
		sqlite3_reset(m_locationInsertStatement);
	}
	catch (...)
	{
	}
	return result == SQLITE_DONE;
}

bool Database::CreateHrmReading(const std::string& activityId, const SensorReading& reading)
{
	int result = SQLITE_ERROR;

	try
	{
		sqlite3_bind_text(m_heartRateInsertStatement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(m_heartRateInsertStatement, 2, reading.time);
		sqlite3_bind_double(m_heartRateInsertStatement, 3, reading.reading.at(ACTIVITY_ATTRIBUTE_HEART_RATE));

		result = sqlite3_step(m_heartRateInsertStatement);

		sqlite3_clear_bindings(m_heartRateInsertStatement);
		sqlite3_reset(m_heartRateInsertStatement);
	}
	catch (...)
	{
	}
	return result == SQLITE_DONE;
}

bool Database::CreateCadenceReading(const std::string& activityId, const SensorReading& reading)
{
	int result = SQLITE_ERROR;

	try
	{
		sqlite3_bind_text(m_cadenceInsertStatement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(m_cadenceInsertStatement, 2, reading.time);
		sqlite3_bind_double(m_cadenceInsertStatement, 3, reading.reading.at(ACTIVITY_ATTRIBUTE_CADENCE));

		result = sqlite3_step(m_cadenceInsertStatement);

		sqlite3_clear_bindings(m_cadenceInsertStatement);
		sqlite3_reset(m_cadenceInsertStatement);
	}
	catch (...)
	{
	}
	return result == SQLITE_DONE;
}

bool Database::CreateWheelSpeedReading(const std::string& activityId, const SensorReading& reading)
{
	int result = SQLITE_ERROR;

	try
	{
		sqlite3_bind_text(m_wheelSpeedInsertStatement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(m_wheelSpeedInsertStatement, 2, reading.time);
		sqlite3_bind_double(m_wheelSpeedInsertStatement, 3, reading.reading.at(ACTIVITY_ATTRIBUTE_NUM_WHEEL_REVOLUTIONS));

		result = sqlite3_step(m_wheelSpeedInsertStatement);

		sqlite3_clear_bindings(m_wheelSpeedInsertStatement);
		sqlite3_reset(m_wheelSpeedInsertStatement);
	}
	catch (...)
	{
	}
	return result == SQLITE_DONE;
}

bool Database::CreatePowerMeterReading(const std::string& activityId, const SensorReading& reading)
{
	int result = SQLITE_ERROR;
	
	try
	{
		sqlite3_bind_text(m_powerInsertStatement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(m_powerInsertStatement, 2, reading.time);
		sqlite3_bind_double(m_powerInsertStatement, 3, reading.reading.at(ACTIVITY_ATTRIBUTE_POWER));

		result = sqlite3_step(m_powerInsertStatement);

		sqlite3_clear_bindings(m_powerInsertStatement);
		sqlite3_reset(m_powerInsertStatement);
	}
	catch (...)
	{
	}
	return result == SQLITE_DONE;
}

bool Database::CreateFootPodReading(const std::string& activityId, const SensorReading& reading)
{
	int result = SQLITE_ERROR;
	
	try
	{
		sqlite3_bind_text(m_footPodStatement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(m_footPodStatement, 2, reading.time);
		sqlite3_bind_double(m_footPodStatement, 3, reading.reading.at(ACTIVITY_ATTRIBUTE_RUN_DISTANCE));

		result = sqlite3_step(m_footPodStatement);

		sqlite3_clear_bindings(m_footPodStatement);
		sqlite3_reset(m_footPodStatement);
	}
	catch (...)
	{
	}
	return result == SQLITE_DONE;
}

bool Database::CreateEventReading(const std::string& activityId, const SensorReading& reading)
{
	int result = SQLITE_ERROR;
	
	try
	{
		sqlite3_bind_text(m_eventStatement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(m_eventStatement, 2, reading.time);
		sqlite3_bind_int64(m_eventStatement, 3, reading.type);

		bool validType = true;

		switch (reading.type)
		{
			case SENSOR_TYPE_RADAR:
				sqlite3_bind_int64(m_eventStatement, 4, reading.reading.at(ACTIVITY_ATTRIBUTE_THREAT_COUNT));
				break;
			default:
				validType = false;
				break;
		}

		if (validType)
		{
			result = sqlite3_step(m_eventStatement);
		}

		sqlite3_clear_bindings(m_eventStatement);
		sqlite3_reset(m_eventStatement);
	}
	catch (...)
	{
	}
	return result == SQLITE_DONE;
}

bool Database::ProcessAllCoordinates(coordinateCallback callback, void* context)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "select time,latitude,longitude,altitude from gps", -1, &statement, 0) == SQLITE_OK)
	{
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			uint64_t time      = sqlite3_column_int64(statement, 0);
			double   latitude  = sqlite3_column_double(statement, 1);
			double   longitude = sqlite3_column_double(statement, 2);
			double   altitude  = sqlite3_column_double(statement, 3);
			
			callback(time, latitude, longitude, altitude, context);
		}

		sqlite3_finalize(statement);
		result = true;
	}
	return result;
}

bool Database::CreateSensorReading(const std::string& activityId, const SensorReading& reading)
{
	switch (reading.type)
	{
		case SENSOR_TYPE_UNKNOWN:
			break;
		case SENSOR_TYPE_ACCELEROMETER:
			return CreateAccelerometerReading(activityId, reading);
		case SENSOR_TYPE_LOCATION:
			return CreateLocationReading(activityId, reading);
		case SENSOR_TYPE_HEART_RATE:
			return CreateHrmReading(activityId, reading);
		case SENSOR_TYPE_CADENCE:
			return CreateCadenceReading(activityId, reading);
		case SENSOR_TYPE_WHEEL_SPEED:
			return CreateWheelSpeedReading(activityId, reading);
		case SENSOR_TYPE_POWER:
			return CreatePowerMeterReading(activityId, reading);
		case SENSOR_TYPE_FOOT_POD:
			return CreateFootPodReading(activityId, reading);
		case SENSOR_TYPE_SCALE:
			break;
		case SENSOR_TYPE_LIGHT:
			break;
		case SENSOR_TYPE_RADAR:
			return CreateEventReading(activityId, reading);
		case SENSOR_TYPE_GOPRO:
			break;
		case SENSOR_TYPE_NEARBY:
			break;
		case NUM_SENSOR_TYPES:
			break;
	}
	return false;
}

bool Database::RetrieveSensorReadingsOfType(const std::string& activityId, SensorType type, SensorReadingList& readings)
{
	switch (type)
	{
		case SENSOR_TYPE_UNKNOWN:
			break;
		case SENSOR_TYPE_ACCELEROMETER:
			return RetrieveActivityAccelerometerReadings(activityId, readings);
		case SENSOR_TYPE_LOCATION:
			return RetrieveActivityPositionReadings(activityId, readings);
		case SENSOR_TYPE_HEART_RATE:
			return RetrieveActivityHeartRateMonitorReadings(activityId, readings);
		case SENSOR_TYPE_CADENCE:
			return RetrieveActivityCadenceReadings(activityId, readings);
		case SENSOR_TYPE_WHEEL_SPEED:
			return RetrieveActivityWheelSpeedReadings(activityId, readings);
		case SENSOR_TYPE_POWER:
			return RetrieveActivityPowerMeterReadings(activityId, readings);
		case SENSOR_TYPE_FOOT_POD:
			return RetrieveActivityFootPodReadings(activityId, readings);
		case SENSOR_TYPE_SCALE:
			break;
		case SENSOR_TYPE_LIGHT:
			break;
		case SENSOR_TYPE_RADAR:
			break;
		case SENSOR_TYPE_GOPRO:
			break;
		case SENSOR_TYPE_NEARBY:
			break;
		case NUM_SENSOR_TYPES:
			break;
	}
	return false;
}

bool Database::RetrieveActivityPositionReadings(const std::string& activityId, CoordinateList& coordinates)
{
	const size_t SIZE_INCREMENT = 2048;
	
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	coordinates.clear();
	
	if (sqlite3_prepare_v2(m_pDb, "select time,latitude,longitude,altitude from gps where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		if (sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK)
		{
			coordinates.reserve(SIZE_INCREMENT);
			
			while (sqlite3_step(statement) == SQLITE_ROW)
			{
				size_t capacity = coordinates.capacity();
				size_t size = coordinates.size();
				
				Coordinate coordinate;
				
				coordinate.time      = sqlite3_column_int64(statement, 0);
				coordinate.latitude  = sqlite3_column_double(statement, 1);
				coordinate.longitude = sqlite3_column_double(statement, 2);
				coordinate.altitude  = sqlite3_column_double(statement, 3);
				coordinate.horizontalAccuracy = (double)0.0;
				coordinate.verticalAccuracy   = (double)0.0;
				
				if (size == capacity)
				{
					coordinates.reserve(capacity + SIZE_INCREMENT);
				}
				
				coordinates.push_back(coordinate);
			}
			
			result = true;
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveActivityPositionReadings(const std::string& activityId, CoordinateCallback coordinateCallback, void* context)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "select time,latitude,longitude,altitude from gps where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		if (sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK)
		{
			while (sqlite3_step(statement) == SQLITE_ROW)
			{
				Coordinate coord;

				coord.latitude  = sqlite3_column_double(statement, 1);
				coord.longitude = sqlite3_column_double(statement, 2);
				coord.altitude  = sqlite3_column_double(statement, 3);
				coord.time = sqlite3_column_int64(statement, 0);
				coord.horizontalAccuracy = (double)0.0;
				coord.verticalAccuracy = (double)0.0;

				(*coordinateCallback)(coord, context);
			}

			result = true;
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveActivityPositionReadings(const std::string& activityId, SensorReadingList& readings)
{
	const size_t SIZE_INCREMENT = 2048;

	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	readings.clear();

	if (sqlite3_prepare_v2(m_pDb, "select time,latitude,longitude,altitude from gps where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		if (sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK)
		{
			readings.reserve(SIZE_INCREMENT);

			while (sqlite3_step(statement) == SQLITE_ROW)
			{
				size_t capacity = readings.capacity();
				size_t size = readings.size();

				SensorReading reading;

				reading.type = SENSOR_TYPE_LOCATION;
				reading.time = sqlite3_column_int64(statement, 0);

				double latitude  = sqlite3_column_double(statement, 1);
				double longitude = sqlite3_column_double(statement, 2);
				double altitude  = sqlite3_column_double(statement, 3);

				reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_LATITUDE, latitude));
				reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_LONGITUDE, longitude));
				reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_ALTITUDE, altitude));

				if (size == capacity)
				{
					readings.reserve(capacity + SIZE_INCREMENT);
				}

				readings.push_back(reading);
			}
			
			result = true;
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveActivityAccelerometerReadings(const std::string& activityId, SensorReadingList& readings)
{
	const size_t SIZE_INCREMENT = 4096;

	bool result = false;
	sqlite3_stmt* statement = NULL;

	readings.clear();
	
	if (sqlite3_prepare_v2(m_pDb, "select time,x,y,z from accelerometer where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		if (sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK)
		{
			readings.reserve(1024);

			while (sqlite3_step(statement) == SQLITE_ROW)
			{
				size_t capacity = readings.capacity();
				size_t size = readings.size();

				SensorReading reading;

				reading.type = SENSOR_TYPE_ACCELEROMETER;
				reading.time = sqlite3_column_int64(statement, 0);
				
				double x = sqlite3_column_double(statement, 1);
				double y = sqlite3_column_double(statement, 2);
				double z = sqlite3_column_double(statement, 3);
				
				reading.reading.insert(SensorNameValuePair(AXIS_NAME_X, x));
				reading.reading.insert(SensorNameValuePair(AXIS_NAME_Y, y));
				reading.reading.insert(SensorNameValuePair(AXIS_NAME_Z, z));
				
				if (size == capacity)
				{
					readings.reserve(capacity + SIZE_INCREMENT);
				}

				readings.push_back(reading);
			}
			
			result = true;
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveActivityHeartRateMonitorReadings(const std::string& activityId, SensorReadingList& readings)
{
	const size_t SIZE_INCREMENT = 4096;

	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	readings.clear();

	if (sqlite3_prepare_v2(m_pDb, "select time,value from hrm where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		if (sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK)
		{
			readings.reserve(1024);
			
			while (sqlite3_step(statement) == SQLITE_ROW)
			{
				size_t capacity = readings.capacity();
				size_t size = readings.size();
				
				SensorReading reading;
				
				reading.type = SENSOR_TYPE_HEART_RATE;
				reading.time = sqlite3_column_int64(statement, 0);
				
				double rate = sqlite3_column_double(statement, 1);
				reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_HEART_RATE, rate));
				
				if (size == capacity)
				{
					readings.reserve(capacity + SIZE_INCREMENT);
				}
				
				readings.push_back(reading);
			}
			
			result = true;
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveActivityCadenceReadings(const std::string& activityId, SensorReadingList& readings)
{
	const size_t SIZE_INCREMENT = 4096;

	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	readings.clear();

	if (sqlite3_prepare_v2(m_pDb, "select time,value from cadence where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		if (sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK)
		{
			readings.reserve(1024);
			
			while (sqlite3_step(statement) == SQLITE_ROW)
			{
				size_t capacity = readings.capacity();
				size_t size = readings.size();
				
				SensorReading reading;
				
				reading.type = SENSOR_TYPE_CADENCE;
				reading.time = sqlite3_column_int64(statement, 0);
				
				double rate = sqlite3_column_double(statement, 1);
				reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_CADENCE, rate));
				
				if (size == capacity)
				{
					readings.reserve(capacity + SIZE_INCREMENT);
				}
				
				readings.push_back(reading);
			}
			
			result = true;
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveActivityWheelSpeedReadings(const std::string& activityId, SensorReadingList& readings)
{
	const size_t SIZE_INCREMENT = 4096;
	
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	readings.clear();

	if (sqlite3_prepare_v2(m_pDb, "select time,value from wheel_speed where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		if (sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK)
		{
			readings.reserve(1024);
			
			while (sqlite3_step(statement) == SQLITE_ROW)
			{
				size_t capacity = readings.capacity();
				size_t size = readings.size();
				
				SensorReading reading;
				
				reading.type = SENSOR_TYPE_CADENCE;
				reading.time = sqlite3_column_int64(statement, 0);
				
				double rate = sqlite3_column_double(statement, 1);
				reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_WHEEL_SPEED, rate));
				
				if (size == capacity)
				{
					readings.reserve(capacity + SIZE_INCREMENT);
				}
				
				readings.push_back(reading);
			}
			
			result = true;
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveActivityPowerMeterReadings(const std::string& activityId, SensorReadingList& readings)
{
	const size_t SIZE_INCREMENT = 4096;
	
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	readings.clear();
	
	if (sqlite3_prepare_v2(m_pDb, "select time,value from power_meter where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		if (sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK)
		{
			readings.reserve(1024);
			
			while (sqlite3_step(statement) == SQLITE_ROW)
			{
				size_t capacity = readings.capacity();
				size_t size = readings.size();
				
				SensorReading reading;
				
				reading.type = SENSOR_TYPE_POWER;
				reading.time = sqlite3_column_int64(statement, 0);
				
				double rate = sqlite3_column_double(statement, 1);
				reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_POWER, rate));
				
				if (size == capacity)
				{
					readings.reserve(capacity + SIZE_INCREMENT);
				}
				
				readings.push_back(reading);
			}
			
			result = true;
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveActivityFootPodReadings(const std::string& activityId, SensorReadingList& readings)
{
	const size_t SIZE_INCREMENT = 4096;
	
	bool result = false;
	sqlite3_stmt* statement = NULL;

	readings.clear();

	if (sqlite3_prepare_v2(m_pDb, "select time,value from foot_pod where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		if (sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK)
		{
			readings.reserve(1024);
			
			while (sqlite3_step(statement) == SQLITE_ROW)
			{
				size_t capacity = readings.capacity();
				size_t size = readings.size();
				
				SensorReading reading;
				
				reading.type = SENSOR_TYPE_CADENCE;
				reading.time = sqlite3_column_int64(statement, 0);
				
				double rate = sqlite3_column_double(statement, 1);
				reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_STEPS_TAKEN, rate));
				
				if (size == capacity)
				{
					readings.reserve(capacity + SIZE_INCREMENT);
				}
				
				readings.push_back(reading);
			}
			
			result = true;
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveActivityEventReadings(const std::string& activityId, SensorReadingList& readings)
{
	const size_t SIZE_INCREMENT = 4096;
	
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	readings.clear();

	if (sqlite3_prepare_v2(m_pDb, "select time,event_type,value from event where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		if (sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK)
		{
			readings.reserve(1024);
			
			while (sqlite3_step(statement) == SQLITE_ROW)
			{
				size_t capacity = readings.capacity();
				size_t size = readings.size();
				
				SensorReading reading;
				
				reading.time = sqlite3_column_int64(statement, 0);
				reading.type = (SensorType)sqlite3_column_int64(statement, 1);
				double value = sqlite3_column_double(statement, 2);

				switch (reading.type)
				{
				case SENSOR_TYPE_RADAR:
					reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_THREAT_COUNT, value));
					break;
				default:
					break;
				}

				if (size == capacity)
				{
					readings.reserve(capacity + SIZE_INCREMENT);
				}
				
				readings.push_back(reading);
			}
			
			result = true;
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::TrimActivityPositionReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	std::string query;

	if (fromStart)
		query = "delete from gps where activity_id = ? and time < ?";
	else
		query = "delete from gps where activity_id = ? and time > ?";

	if (sqlite3_prepare_v2(m_pDb, query.c_str(), -1, &statement, 0) == SQLITE_OK)
	{
		if ((sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK) &&
			(sqlite3_bind_int64(statement, 2, timeStamp) == SQLITE_OK))
		{
			result = sqlite3_step(statement);
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::TrimActivityAccelerometerReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	std::string query;

	if (fromStart)
		query = "delete from accelerometer where activity_id = ? and time < ?";
	else
		query = "delete from accelerometer where activity_id = ? and time > ?";

	if (sqlite3_prepare_v2(m_pDb, query.c_str(), -1, &statement, 0) == SQLITE_OK)
	{
		if ((sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK) &&
			(sqlite3_bind_int64(statement, 2, timeStamp) == SQLITE_OK))
		{
			result = sqlite3_step(statement);
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::TrimActivityHeartRateMonitorReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;	
	std::string query;

	if (fromStart)
		query = "delete from hrm where activity_id = ? and time < ?";
	else
		query = "delete from hrm where activity_id = ? and time > ?";

	if (sqlite3_prepare_v2(m_pDb, query.c_str(), -1, &statement, 0) == SQLITE_OK)
	{
		if ((sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK) &&
			(sqlite3_bind_int64(statement, 2, timeStamp) == SQLITE_OK))
		{
			result = sqlite3_step(statement);
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::TrimActivityCadenceReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	std::string query;

	if (fromStart)
		query = "delete from cadence where activity_id = ? and time < ?";
	else
		query = "delete from cadence where activity_id = ? and time > ?";

	if (sqlite3_prepare_v2(m_pDb, query.c_str(), -1, &statement, 0) == SQLITE_OK)
	{
		if ((sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK) &&
			(sqlite3_bind_int64(statement, 2, timeStamp) == SQLITE_OK))
		{
			result = sqlite3_step(statement);
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::TrimActivityWheelSpeedReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	std::string query;
	
	if (fromStart)
		query = "delete from wheel_speed where activity_id = ? and time < ?";
	else
		query = "delete from wheel_speed where activity_id = ? and time > ?";
	
	if (sqlite3_prepare_v2(m_pDb, query.c_str(), -1, &statement, 0) == SQLITE_OK)
	{
		if ((sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK) &&
			(sqlite3_bind_int64(statement, 2, timeStamp) == SQLITE_OK))
		{
			result = sqlite3_step(statement);
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::TrimActivityPowerMeterReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	std::string query;
	
	if (fromStart)
		query = "delete from power_meter where activity_id = ? and time < ?";
	else
		query = "delete from power_meter where activity_id = ? and time > ?";
	
	if (sqlite3_prepare_v2(m_pDb, query.c_str(), -1, &statement, 0) == SQLITE_OK)
	{
		if ((sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK) &&
			(sqlite3_bind_int64(statement, 2, timeStamp) == SQLITE_OK))
		{
			result = sqlite3_step(statement);
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::TrimActivityFootPodReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	std::string query;
	
	if (fromStart)
		query = "delete from foot_pod where activity_id = ? and time < ?";
	else
		query = "delete from foot_pod where activity_id = ? and time > ?";
	
	if (sqlite3_prepare_v2(m_pDb, query.c_str(), -1, &statement, 0) == SQLITE_OK)
	{
		if ((sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT) == SQLITE_OK) &&
			(sqlite3_bind_int64(statement, 2, timeStamp) == SQLITE_OK))
		{
			result = sqlite3_step(statement);
		}
		sqlite3_finalize(statement);
	}
	return result;
}

int Database::ExecuteQuery(const std::string& query)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, query.c_str(), -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result;
}

int Database::ExecuteQueries(const std::vector<std::string>& queries)
{
	int result = SQLITE_OK;
	for (auto iter = queries.begin(); iter != queries.end(); ++iter)
	{
		result = ExecuteQuery((*iter));
	}
	return result;
}
