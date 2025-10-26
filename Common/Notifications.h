// Created by Michael Simms on 7/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

#define NOTIFICATION_NAME_ACTIVITY_STARTED             "ActivityStarted"            // The user has started an activity
#define NOTIFICATION_NAME_ACTIVITY_STOPPED             "ActivityStopped"            // The user has stopped an activity
#define NOTIFICATION_NAME_GEAR_LIST_UPDATED            "GearListUpdated"            // An updated gear list was returned from the (optional) server
#define NOTIFICATION_NAME_RACE_LIST_UPDATED            "RaceListUpdated"            // The race calendar from the (optional) server was updated
#define NOTIFICATION_NAME_PLANNED_WORKOUTS_UPDATED     "PlannedWorkoutsUpdated"     // The planned workouts list from the (optional) server was updated
#define NOTIFICATION_NAME_INTERVAL_SESSIONS_UPDATED    "IntervalSessionsUpdated"    // The interval sessions list from the (optional) server was updated
#define NOTIFICATION_NAME_INTERVAL_UPDATED             "IntervalUpdated"
#define NOTIFICATION_NAME_INTERVAL_COMPLETE            "IntervalComplete"
#define NOTIFICATION_NAME_PACE_PLANS_UPDATED           "PacePlansUpdated"           // The pace plans list from the (optional) server was updated
#define NOTIFICATION_NAME_UNSYNCHED_ACTIVITIES_LIST    "UnsyncheActivitiesList"     // A list of activity IDs that need to be synched was returned from the server (optional)
#define NOTIFICATION_NAME_ACTIVITY_PHOTOS_LIST         "ActivityPhotosList"         // A list of URLs is returned for photos associated with the requested activity (optional)
#define NOTIFICATION_NAME_ACTIVITY_PHOTOS_UPDATED      "ActivityPhotosUpdated"      // Photos were either added or removed (optional)
#define NOTIFICATION_NAME_FRIENDS_LIST_UPDATED         "FriendsListUpdated"         // The friends list from the (optional) server was updated
#define NOTIFICATION_NAME_REQUEST_TO_FOLLOW_RESULT     "RequestToFollowResult"
#define NOTIFICATION_NAME_REQUEST_USER_SETTINGS_RESULT "RequestUserSettingsResult"
#define NOTIFICATION_NAME_LOGIN_PROCESSED              "LoginProcessed"             // The (optional) server responded to a login attempt
#define NOTIFICATION_NAME_CREATE_LOGIN_PROCESSED       "CreateLoginProcessed"       // The (optional) server responded to an attempt to create a new login
#define NOTIFICATION_NAME_LOGIN_CHECKED                "LoginChecked"               // The (optional) server is responding to a login request
#define NOTIFICATION_NAME_LOGGED_OUT                   "LogoutProcessed"            // The (optional) server is responding to a logout request
#define NOTIFICATION_NAME_DOWNLOADED_ACTIVITY_RECEIVED "DownloadedActivityReceived" // We've received an activity from the (optional) server
#define NOTIFICATION_NAME_PRINT_MESSAGE                "PrintMessage"               // Show a message on the activity screen
#define NOTIFICATION_NAME_HAS_ACTIVITY_RESPONSE        "HasActivityResponse"        // The (optional) server responded to an activity existence check
#define NOTIFICATION_NAME_ACTIVITY_METADATA            "ActivityMetadata"           // The (optional) server returned activity metadata
#define NOTIFICATION_NAME_ACTIVITY_METADATA_UPDATED    "ActivityMetadataUpdated"    // New activity metadata was received and written to the database

// Parameters that are associated with the notifications
#define KEY_NAME_ACTIVITY_ID                           "ActivityId"                 // The unique identifier for the activity
#define KEY_NAME_ACTIVITY_TYPE                         "ActivityType"
#define KEY_NAME_ACTIVITY_HASH                         "ActivityHash"
#define KEY_NAME_START_TIME                            "StartTime"
#define KEY_NAME_END_TIME                              "EndTime"
#define KEY_NAME_DISTANCE                              "Distance"
#define KEY_NAME_UNITS                                 "Units"
#define KEY_NAME_CALORIES                              "Calories"
#define KEY_NAME_LOCATIONS                             "Locations"
#define KEY_NAME_RESPONSE_CODE                         "ResponseCode"
#define KEY_NAME_RESPONSE_DATA                         "ResponseData"
#define KEY_NAME_DATA                                  "Data"
#define KEY_NAME_URL                                   "URL"
#define KEY_NAME_TAG                                   "Tag"
#define KEY_NAME_MESSAGE                               "Message"
#define KEY_NAME_PERIPHERAL_OBJ                        "Peripheral"
#define KEY_NAME_STATUS                                "Status"
#define KEY_NAME_SENSOR_NAME                           "SensorName"
#define KEY_NAME_TIMESTAMP_MS                          "Time"
#define KEY_NAME_DEVICE_ID                             "DeviceId"
#define KEY_NAME_USER_NAME                             "Name"
#define KEY_NAME_INTERVAL_SEGMENT_ID                   "IntervalSegmentId"          // The unique identifier for the interval segment
#define KEY_NAME_INTERVAL_SETS                         "IntervalSets"
#define KEY_NAME_INTERVAL_REPS                         "IntervalReps"
#define KEY_NAME_INTERVAL_DURATION                     "IntervalDuration"
#define KEY_NAME_INTERVAL_DISTANCE                     "IntervalDistance"
#define KEY_NAME_INTERVAL_PACE                         "IntervalPace"
#define KEY_NAME_INTERVAL_POWER                        "IntervalPower"
#define KEY_NAME_INTERVAL_UNITS                        "IntervalUnits"
#define KEY_NAME_HEART_RATE                            "Heart Rate"
#define KEY_NAME_BATTERY_LEVEL                         "Battery Level"
