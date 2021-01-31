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
	if (m_pDb)
	{
		sqlite3_close(m_pDb);
		m_pDb = NULL;
	}
	
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

bool Database::Open(const std::string& dbFileName)
{
	return (sqlite3_open(dbFileName.c_str(), &m_pDb) == SQLITE_OK);
}

bool Database::Close()
{
	return (sqlite3_close(m_pDb) == SQLITE_OK);
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

bool Database::DropTable(const std::string& tableName)
{
	std::string sql = "drop table '";
	sql += tableName;
	sql += "'";

	int result = ExecuteQuery(sql);
	return (result == SQLITE_ROW);
}

bool Database::CreateTables()
{
	std::vector<std::string> queries;
	std::string sql;

	if (!DoesTableExist("bike"))
	{
		sql = "create table bike (id integer primary key, name text, weight_kg double, wheel_circumference_mm double, time_added unsigned big int, time_retired unsigned big int, last_updated_time big int)";
		queries.push_back(sql);
	}
	else if (!DoesTableHaveColumn("bike", "last_updated_time"))
	{
		sql = "alter table bike add column last_updated_time big int";
		queries.push_back(sql);
	}
	if (!DoesTableExist("shoe"))
	{
		sql = "create table shoe (id integer primary key, name text, description text, time_added unsigned big int, time_retired unsigned big int, last_updated_time big int)";
		queries.push_back(sql);
	}
	else if (!DoesTableHaveColumn("shoe", "last_updated_time"))
	{
		sql = "alter table shoe add column last_updated_time big int";
		queries.push_back(sql);
	}
	if (!DoesTableExist("bike_activity"))
	{
		sql = "create table bike_activity (id integer primary key, bike_id integer, activity_id text)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("interval_workout"))
	{
		sql = "create table interval_workout (id integer primary key, workout_id test, name text, sport text, last_updated_time big int)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("interval_workout_segment"))
	{
		sql = "create table interval_workout_segment (id integer primary key, workout_id test, sets integer, reps integer, duration integer, distance double, pace double, power double, units integer)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("workout"))
	{
		sql = "create table workout (id integer primary key, workout_id text, type unsigned big int, sport text, estimated_stress double, scheduled_time unsigned big int)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("workout_interval"))
	{
		sql = "create table workout_interval (id integer primary key, workout_id text, repeat integer, duration double, power_low double, power_high double, distance double, pace double, recovery_distance double, recovery_pace double)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("pace_plan"))
	{
		sql = "create table pace_plan (id integer primary key, plan_id text, name text, target_pace double, target_distance double, splits double, route text, display_units_distance integer, display_units_pace integer, last_updated_time big int)";
		queries.push_back(sql);
	}
	else
	{
		if (!DoesTableHaveColumn("pace_plan", "display_units_distance"))
		{
			sql = "alter table pace_plan add column display_units_distance integer";
			queries.push_back(sql);
		}
		if (!DoesTableHaveColumn("pace_plan", "display_units_pace"))
		{
			sql = "alter table pace_plan add column display_units_pace integer";
			queries.push_back(sql);
		}
		if (!DoesTableHaveColumn("pace_plan", "last_updated_time"))
		{
			sql = "alter table pace_plan add column last_updated_time big int";
			queries.push_back(sql);
		}
	}
	if (!DoesTableExist("custom_activity"))
	{
		sql = "create table custom_activity (id integer primary key, name text, type integer)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("activity"))
	{
		sql = "create table activity (id integer primary key, activity_id text, user_id text, type text, name text, start_time unsigned big int, end_time unsigned big int)";
		queries.push_back(sql);
	}
	if (!DoesTableExist("lap"))
	{
		sql = "create table lap (id integer primary key, activity_id text, start_time unsigned big int)";
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
		sql = "create table activity_summary (id integer primary key, activity_id text, attribute text, value double, start_time unsigned big int, end_time unsigned big int, value_type integer, measure_type integer, units integer, unique(activity_id, attribute) on conflict replace)";
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

	int result = ExecuteQueries(queries);
	return (result == SQLITE_OK || result == SQLITE_DONE);
}

bool Database::CreateStatements()
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
	if (sqlite3_prepare_v2(m_pDb, "select * from activity_summary where activity_id = ?", -1, &m_selectActivitySummaryStatement, 0) != SQLITE_OK)
		return false;
	if (sqlite3_prepare_v2(m_pDb, "select activity_id from activity_hash where hash = ? limit 1", -1, &m_selectActivityIdFromHashStatement, 0) != SQLITE_OK)
		return false;
	if (sqlite3_prepare_v2(m_pDb, "select hash from activity_hash where activity_id = ? limit 1", -1, &m_selectActivityHashFromIdStatement, 0) != SQLITE_OK)
		return false;
	return true;
}

bool Database::Reset()
{
	std::vector<std::string> queries;
	std::string sql;

	sql = "delete from bike";
	queries.push_back(sql);
	sql = "delete from shoe";
	queries.push_back(sql);
	sql = "delete from bike_activity";
	queries.push_back(sql);
	sql = "delete from interval_workout";
	queries.push_back(sql);
	sql = "delete from interval_workout_segment";
	queries.push_back(sql);
	sql = "delete from workout";
	queries.push_back(sql);
	sql = "delete from workout_interval";
	queries.push_back(sql);
	sql = "delete from pace_plan";
	queries.push_back(sql);
	sql = "delete from custom_activity";
	queries.push_back(sql);
	sql = "delete from activity";
	queries.push_back(sql);
	sql = "delete from lap";
	queries.push_back(sql);
	sql = "delete from gps";
	queries.push_back(sql);
	sql = "delete from accelerometer";
	queries.push_back(sql);
	sql = "delete from cadence";
	queries.push_back(sql);
	sql = "delete from hrm";
	queries.push_back(sql);
	sql = "delete from wheel_speed";
	queries.push_back(sql);
	sql = "delete from power_meter";
	queries.push_back(sql);
	sql = "delete from foot_pod";
	queries.push_back(sql);
	sql = "delete from weight";
	queries.push_back(sql);
	sql = "delete from tag";
	queries.push_back(sql);
	sql = "delete from activity_summary";
	queries.push_back(sql);
	sql = "delete from activity_hash";
	queries.push_back(sql);
	sql = "delete from activity_sync";
	queries.push_back(sql);
	
	int result = ExecuteQueries(queries);
	return (result == SQLITE_OK || result == SQLITE_DONE);
}

bool Database::CreateBike(const Bike& bike)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "insert into bike values (NULL,?,?,?,?,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, bike.name.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_double(statement, 2, bike.weightKg);
		sqlite3_bind_double(statement, 3, bike.computedWheelCircumferenceMm);
		sqlite3_bind_int64(statement, 4, bike.timeAdded);
		sqlite3_bind_int64(statement, 5, bike.timeRetired);
		sqlite3_bind_int64(statement, 6, time(NULL));
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::RetrieveBike(uint64_t bikeId, Bike& bike)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select id, name, weight_kg, wheel_circumference_mm, time_added, time_retired from bike where id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_int64(statement, 1, bikeId);

		if (sqlite3_step(statement) == SQLITE_ROW)
		{
			bike.id = sqlite3_column_int64(statement, 0);
			bike.name.append((const char*)sqlite3_column_text(statement, 1));
			bike.weightKg = sqlite3_column_double(statement, 2);
			bike.computedWheelCircumferenceMm = sqlite3_column_double(statement, 3);
			bike.timeAdded = (time_t)sqlite3_column_int64(statement, 4);
			bike.timeRetired = (time_t)sqlite3_column_int64(statement, 5);
			result = true;
		}
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::RetrieveBikes(std::vector<Bike>& bikes)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select id, name, weight_kg, wheel_circumference_mm, time_added, time_retired from bike order by id", -1, &statement, 0) == SQLITE_OK)
	{
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			Bike bike;
			
			bike.id = sqlite3_column_int64(statement, 0);
			bike.name.append((const char*)sqlite3_column_text(statement, 1));
			bike.weightKg = sqlite3_column_double(statement, 2);
			bike.computedWheelCircumferenceMm = sqlite3_column_double(statement, 3);
			bike.timeAdded = (time_t)sqlite3_column_int64(statement, 4);
			bike.timeRetired = (time_t)sqlite3_column_int64(statement, 5);
			
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
	
	int result = sqlite3_prepare_v2(m_pDb, "update bike set weight_kg = ?, wheel_circumference_mm = ?, name = ?, time_added = ?, time_retired = ? where id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_double(statement, 1, bike.weightKg);
		sqlite3_bind_double(statement, 2, bike.computedWheelCircumferenceMm);
		sqlite3_bind_text(statement, 3, bike.name.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(statement, 4, bike.timeAdded);
		sqlite3_bind_int64(statement, 5, bike.timeRetired);
		sqlite3_bind_int64(statement, 6, bike.id);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::DeleteBike(uint64_t bikeId)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "delete from bike where id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_int64(statement, 1, bikeId);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::CreateShoe(Shoes& shoes)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "insert into shoe values (NULL,?,?,?,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, shoes.name.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, shoes.description.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(statement, 3, shoes.timeAdded);
		sqlite3_bind_int64(statement, 4, shoes.timeRetired);
		sqlite3_bind_int64(statement, 5, time(NULL));
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::RetrieveShoe(uint64_t shoeId, Shoes& shoes)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select id, name, description, time_added, time_retired from shoe where id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_int64(statement, 1, shoeId);

		if (sqlite3_step(statement) == SQLITE_ROW)
		{
			shoes.id = shoeId;
			shoes.name.append((const char*)sqlite3_column_text(statement, 2));
			shoes.description.append((const char*)sqlite3_column_text(statement, 3));
			shoes.timeAdded = (time_t)sqlite3_column_int64(statement, 4);
			shoes.timeRetired = (time_t)sqlite3_column_int64(statement, 5);
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
	
	if (sqlite3_prepare_v2(m_pDb, "select id, name, description, time_added, time_retired from shoe order by id", -1, &statement, 0) == SQLITE_OK)
	{
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			Shoes shoes;
			
			shoes.id = sqlite3_column_int64(statement, 0);
			shoes.name.append((const char*)sqlite3_column_text(statement, 1));
			shoes.description.append((const char*)sqlite3_column_text(statement, 2));
			shoes.timeAdded = (time_t)sqlite3_column_int64(statement, 4);
			shoes.timeRetired = (time_t)sqlite3_column_int64(statement, 5);
			
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
	
	int result = sqlite3_prepare_v2(m_pDb, "update shoe set name = ?, description = ?, time_added = ?, time_retired = ? where id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, shoes.name.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, shoes.description.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(statement, 3, shoes.timeAdded);
		sqlite3_bind_int64(statement, 4, shoes.timeRetired);
		sqlite3_bind_int64(statement, 5, shoes.id);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::DeleteShoe(uint64_t shoeId)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "delete from shoe where id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_int64(statement, 1, shoeId);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::CreateBikeActivity(uint64_t bikeId, const std::string& activityId)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "insert into bike_activity values (NULL,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_double(statement, 1, bikeId);
		sqlite3_bind_text(statement, 2, activityId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::RetrieveBikeActivity(const std::string& activityId, uint64_t& bikeId)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select bike_id from bike_activity where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		
		if (sqlite3_step(statement) == SQLITE_ROW)
		{
			bikeId = sqlite3_column_int64(statement, 0);
			result = true;
		}
		
		sqlite3_finalize(statement);
	}
	return result;
}

bool Database::UpdateBikeActivity(uint64_t bikeId, const std::string& activityId)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "update bike_activity set bike_id = ? where activity_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_double(statement, 1, bikeId);
		sqlite3_bind_text(statement, 2, activityId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::CreateIntervalWorkout(const std::string& workoutId, const std::string& name, const std::string& sport)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "insert into interval_workout values (NULL,?,?,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, workoutId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, name.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 3, sport.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(statement, 4, time(NULL));
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}	
	return result == SQLITE_DONE;
}

bool Database::RetrieveIntervalWorkouts(std::vector<IntervalWorkout>& workouts)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select workout_id, name, sport from interval_workout order by name", -1, &statement, 0) == SQLITE_OK)
	{
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			IntervalWorkout workout;
			
			workout.workoutId.append((const char*)sqlite3_column_text(statement, 0));
			workout.name.append((const char*)sqlite3_column_text(statement, 1));
			workout.sport.append((const char*)sqlite3_column_text(statement, 2));
			workouts.push_back(workout);
		}
		
		sqlite3_finalize(statement);
		result = true;
	}
	return result;
}

bool Database::DeleteIntervalWorkout(const std::string& workoutId)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "delete from interval_workout where workout_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, workoutId.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::CreateIntervalSegment(const std::string& workoutId, const IntervalWorkoutSegment& segment)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "insert into interval_workout_segment values (NULL,?,?,?,?,?,?,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, workoutId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(statement, 2, segment.sets);
		sqlite3_bind_int64(statement, 3, segment.reps);
		sqlite3_bind_int64(statement, 4, segment.duration);
		sqlite3_bind_double(statement, 5, segment.distance);
		sqlite3_bind_double(statement, 6, segment.pace);
		sqlite3_bind_double(statement, 7, segment.power);
		sqlite3_bind_int64(statement, 8, segment.units);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::RetrieveIntervalSegments(const std::string& workoutId, std::vector<IntervalWorkoutSegment>& segments)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "select id, sets, reps, duration, distance, pace, power, units from interval_workout_segment where workout_id = ? order by id", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, workoutId.c_str(), -1, SQLITE_TRANSIENT);
		
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			IntervalWorkoutSegment segment;
			
			segment.segmentId = sqlite3_column_int64(statement, 0);
			segment.sets = (uint32_t)sqlite3_column_int64(statement, 1);
			segment.reps = (uint32_t)sqlite3_column_int64(statement, 2);
			segment.duration = (uint32_t)sqlite3_column_int64(statement, 3);
			segment.distance = (double)sqlite3_column_double(statement, 4);
			segment.pace = (double)sqlite3_column_double(statement, 5);
			segment.power = (double)sqlite3_column_double(statement, 6);
			segment.units = (IntervalUnit)sqlite3_column_double(statement, 7);
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
	
	int result = sqlite3_prepare_v2(m_pDb, "delete from interval_workout_segment where id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_int64(statement, 1, segmentId);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::DeleteIntervalSegmentsForWorkout(const std::string& workoutId)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "delete from interval_workout_segment where workout_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, workoutId.c_str(), -1, SQLITE_TRANSIENT);
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
		sqlite3_bind_text(statement, 3, workout.GetSport().c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_double(statement, 4, workout.GetEstimatedTrainingStress());
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
			std::string sport;

			WorkoutType workoutType = (WorkoutType)sqlite3_column_int64(statement, 0);
			sport.append((const char*)sqlite3_column_text(statement, 1));
			double estimatedStress = (double)sqlite3_column_double(statement, 2);
			time_t scheduledTime = (time_t)sqlite3_column_int64(statement, 3);

			workout.SetId(workoutId);
			workout.SetSport(sport);
			workout.SetType(workoutType);
			workout.SetEstimatedStress(estimatedStress);
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

	if (sqlite3_prepare_v2(m_pDb, "select workout_id, type, sport, estimated_stress, scheduled_time from workout", -1, &statement, 0) == SQLITE_OK)
	{
		result = true;

		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			std::string workoutId;
			std::string sport;

			workoutId.append((const char*)sqlite3_column_text(statement, 0));
			WorkoutType workoutType = (WorkoutType)sqlite3_column_int64(statement, 1);
			sport.append((const char*)sqlite3_column_text(statement, 2));
			double estimatedStress = (double)sqlite3_column_double(statement, 3);
			time_t scheduledTime = (time_t)sqlite3_column_int64(statement, 4);

			Workout workoutObj;
			workoutObj.SetId(workoutId);
			workoutObj.SetSport(sport);
			workoutObj.SetType(workoutType);
			workoutObj.SetEstimatedStress(estimatedStress);
			workoutObj.SetScheduledTime(scheduledTime);

			// Retrieve the intervals too.
			result &= this->RetrieveWorkoutIntervals(workoutObj);

			workouts.push_back(workoutObj);
		}
		
		sqlite3_finalize(statement);
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
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "delete from workout", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::CreateWorkoutInterval(const Workout& workout, const WorkoutInterval& interval)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "insert into workout_interval values (NULL,?,?,?,?,?,?,?,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, workout.GetId().c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int(statement, 2, interval.m_repeat);
		sqlite3_bind_double(statement, 3, interval.m_duration);
		sqlite3_bind_double(statement, 4, interval.m_powerLow);
		sqlite3_bind_double(statement, 5, interval.m_powerHigh);
		sqlite3_bind_double(statement, 6, interval.m_distance);
		sqlite3_bind_double(statement, 7, interval.m_pace);
		sqlite3_bind_double(statement, 8, interval.m_recoveryDistance);
		sqlite3_bind_double(statement, 9, interval.m_recoveryPace);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::RetrieveWorkoutIntervals(Workout& workout)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "select repeat, distance, pace, recovery_distance, recovery_pace from workout_interval where workout_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, workout.GetId().c_str(), -1, SQLITE_TRANSIENT);

		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			WorkoutInterval interval;

			interval.m_repeat = (uint8_t)sqlite3_column_int(statement, 0);
			interval.m_duration = (double)0.0;
			interval.m_powerLow = (double)0.0;
			interval.m_powerHigh = (double)0.0;
			interval.m_distance = (double)sqlite3_column_double(statement, 1);
			interval.m_pace = (double)sqlite3_column_double(statement, 2);
			interval.m_recoveryDistance = (double)sqlite3_column_double(statement, 3);
			interval.m_recoveryPace = (double)sqlite3_column_double(statement, 4);
			workout.AddInterval(interval);
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

bool Database::CreatePacePlan(const PacePlan& plan)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "insert into pace_plan values (NULL,?,?,?,?,?,?,?,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, plan.planId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, plan.name.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_double(statement, 3, plan.targetPaceInMinKm);
		sqlite3_bind_double(statement, 4, plan.targetDistanceInKms);
		sqlite3_bind_double(statement, 5, plan.splits);
		sqlite3_bind_text(statement, 6, plan.route.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int(statement, 7, plan.displayUnitsDistance);
		sqlite3_bind_int(statement, 8, plan.displayUnitsPace);
		sqlite3_bind_int64(statement, 9, plan.lastUpdatedTime);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}	
	return result == SQLITE_DONE;
}

bool Database::RetrievePacePlans(std::vector<PacePlan>& plans)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select plan_id, name, target_pace, target_distance, splits, route, display_units_distance, display_units_pace, last_updated_time from pace_plan", -1, &statement, 0) == SQLITE_OK)
	{
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			PacePlan plan;

			plan.planId.append((const char*)sqlite3_column_text(statement, 0));
			plan.name.append((const char*)sqlite3_column_text(statement, 1));
			plan.targetPaceInMinKm = sqlite3_column_double(statement, 2);
			plan.targetDistanceInKms = sqlite3_column_double(statement, 3);
			plan.splits = sqlite3_column_double(statement, 4);
			plan.route.append((const char*)sqlite3_column_text(statement, 5));
			plan.displayUnitsDistance = (UnitSystem)sqlite3_column_int(statement, 6);
			plan.displayUnitsPace = (UnitSystem)sqlite3_column_int(statement, 7);
			plan.lastUpdatedTime = (time_t)sqlite3_column_int64(statement, 8);

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

	int result = sqlite3_prepare_v2(m_pDb, "update pace_plan set name = ?, target_pace = ?, target_distance = ?, splits = ?, display_units_distance = ?, display_units_pace = ?, last_updated_time = ? where plan_id = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, plan.name.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_double(statement, 2, plan.targetPaceInMinKm);
		sqlite3_bind_double(statement, 3, plan.targetDistanceInKms);
		sqlite3_bind_double(statement, 4, plan.splits);
		sqlite3_bind_text(statement, 5, plan.planId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int(statement, 6, plan.displayUnitsDistance);
		sqlite3_bind_int(statement, 7, plan.displayUnitsPace);
		sqlite3_bind_int64(statement, 8, plan.lastUpdatedTime);
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

bool Database::CreateCustomActivity(const std::string& activityType, ActivityViewType viewType)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "insert into custom_activity values (NULL,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, activityType.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::DeleteCustomActivity(const std::string& activityType)
{
	sqlite3_stmt* statement = NULL;
	
	int result = sqlite3_prepare_v2(m_pDb, "delete from custom_activity where name = ?", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, activityType.c_str(), -1, SQLITE_TRANSIENT);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::StartActivity(const std::string& activityId, const std::string& userId, const std::string& activityType, time_t startTime)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "insert into activity values (NULL,?,?,?,?,?,0)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		std::string activityName;

		sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, userId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 3, activityType.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 4, activityName.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(statement, 5, startTime);
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

	sqlStream << "delete from bike_activity where activity_id = '" << activityId << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();

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
		}
		
		sqlite3_finalize(statement);
		result = true;
	}
	return result;
}

bool Database::RetrieveActivities(ActivitySummaryList& activities)
{
	const size_t SIZE_INCREMENT = 128;

	bool result = false;
	sqlite3_stmt* statement = NULL;
	
	if (sqlite3_prepare_v2(m_pDb, "select activity_id, user_id, type, name, start_time, end_time from activity order by start_time", -1, &statement, 0) == SQLITE_OK)
	{
		activities.reserve(SIZE_INCREMENT);

		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			ActivitySummary summary;

			summary.activityId.append((const char*)sqlite3_column_text(statement, 0));
			summary.userId = sqlite3_column_int64(statement, 1);
			summary.type.append((const char*)sqlite3_column_text(statement, 2));
			summary.name.append((const char*)sqlite3_column_text(statement, 3));
			summary.startTime = (time_t)sqlite3_column_int64(statement, 4);
			summary.endTime = (time_t)sqlite3_column_int64(statement, 5);
			summary.pActivity = NULL;

			activities.push_back(summary);
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
	
	sqlStream << "update bike_activity set activity_id = '" << activityId1 << "' where activity_id = '" << activityId2 << "'";
	queries.push_back(sqlStream.str());
	sqlStream.str(std::string());
	sqlStream.clear();
	
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
		}
		
		sqlite3_finalize(statement);
		result = true;
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
			name = (const char*)sqlite3_column_text(statement, 0);
		}
		
		sqlite3_finalize(statement);
		result = true;
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

bool Database::CreateNewLap(const std::string& activityId, uint64_t startTimeMs)
{
	sqlite3_stmt* statement = NULL;

	int result = sqlite3_prepare_v2(m_pDb, "insert into lap values (NULL,?,?)", -1, &statement, 0);
	if (result == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(statement, 2, startTimeMs);
		result = sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	return result == SQLITE_DONE;
}

bool Database::RetrieveLaps(const std::string& activityId, LapSummaryList& laps)
{
	bool result = false;
	sqlite3_stmt* statement = NULL;

	if (sqlite3_prepare_v2(m_pDb, "select start_time from lap where activity_id = ?", -1, &statement, 0) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, activityId.c_str(), -1, SQLITE_TRANSIENT);

		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			LapSummary lap;
			lap.startTimeMs = (u_int64_t)sqlite3_column_int64(statement, 0);
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

		attributeName.append((const char*)sqlite3_column_text(m_selectActivitySummaryStatement, 2));
		if (attributeName.length() > 0)
		{
			value.startTime = (u_int64_t)sqlite3_column_int64(m_selectActivitySummaryStatement, 4);
			value.endTime = (u_int64_t)sqlite3_column_int64(m_selectActivitySummaryStatement, 5);
			value.valueType = (ActivityAttributeValueType)sqlite3_column_int(m_selectActivitySummaryStatement, 6);
			value.measureType = (ActivityAttributeMeasureType)sqlite3_column_int(m_selectActivitySummaryStatement, 7);
			value.unitSystem = (UnitSystem)sqlite3_column_int(m_selectActivitySummaryStatement, 8);
			
			switch (value.valueType)
			{
				case TYPE_DOUBLE:
					value.value.doubleVal = sqlite3_column_double(m_selectActivitySummaryStatement, 3);
					value.valid = true;
					break;
				case TYPE_INTEGER:
					value.value.intVal = sqlite3_column_double(m_selectActivitySummaryStatement, 3);
					value.valid = true;
					break;
				case TYPE_TIME:
					value.value.timeVal = sqlite3_column_double(m_selectActivitySummaryStatement, 3);
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
		sqlite3_bind_int64(m_accelerometerInsertStatement,  2, reading.time);
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
		sqlite3_bind_int64(m_locationInsertStatement,  2, reading.time);
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
			break;
		case SENSOR_TYPE_GOPRO:
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
		case NUM_SENSOR_TYPES:
			break;
	}
	return false;
}

bool Database::RetrieveActivityCoordinates(const std::string& activityId, CoordinateList& coordinates)
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
