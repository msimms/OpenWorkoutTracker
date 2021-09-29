// Created by Michael Simms on 7/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

#define NOTIFICATION_NAME_APPLICATION_INITIALIZED     "AppInitialized"           // the application has finished initializing
#define NOTIFICATION_NAME_ACTIVITY_STARTED            "ActivityStarted"          // The user has started an activity
#define NOTIFICATION_NAME_ACTIVITY_STOPPED            "ActivityStopped"          // The user has stopped an activity
#define NOTIFICATION_NAME_FRIEND_LOCATION_UPDATED     "FriendLocationUpdated"
#define NOTIFICATION_NAME_GEAR_LIST_UPDATED           "GearListUpdated"          // An updated gear list was returned from the (optional) server
#define NOTIFICATION_NAME_PLANNED_WORKOUTS_UPDATED    "PlannedWorkoutsUpdated"   // The planned workouts list from the (optional) server was updated
#define NOTIFICATION_NAME_PLANNED_WORKOUT_UPDATED     "PlannedWorkoutUpdated"    // A planned workout from the (optional) server was updated
#define NOTIFICATION_NAME_INTERVAL_WORKOUT_UPDATED    "IntervalWorkoutUpdated"   // The interval workouts list from the (optional) server was updated
#define NOTIFICATION_NAME_PACE_PLANS_UPDATED          "PacePlansUpdated"         // The pace plans list from the (optional) server was updated
#define NOTIFICATION_NAME_FRIENDS_LIST_UPDATED        "FriendsListUpdated"       // The friends list from the (optional) server was updated
#define NOTIFICATION_NAME_LOGIN_PROCESSED             "LoginProcessed"           // The (optional) server responded to a login attempt
#define NOTIFICATION_NAME_CREATE_LOGIN_PROCESSED      "CreateLoginProcessed"     // The (optional) server responded to an attempt to create a new login
#define NOTIFICATION_NAME_LOGIN_CHECKED               "LoginChecked"             // The (optional) server is responding to a login request
#define NOTIFICATION_NAME_LOGGED_OUT                  "LogoutProcessed"          // The (optional) server is responding to a logout request
#define NOTIFICATION_NAME_REQUEST_TO_FOLLOW_RESULT    "RequestToFollowResult"
#define NOTIFICATION_NAME_PRINT_MESSAGE               "PrintMessage"             // Show a message on the activity screen
#define NOTIFICATION_NAME_BROADCAST_STATUS            "BroadcastStatus"          // Updates the broadcast status
#define NOTIFICATION_NAME_HAS_ACTIVITY_RESPONSE       "HasActivityResponse"      // The (optional) server responded to an activity existence check
#define NOTIFICATION_NAME_ACTIVITY_METADATA           "ActivityMetadata"         // The (optional) server returned activity metadata
#define NOTIFICATION_NAME_BROADCAST_MGR_SENT_ACTIVITY "BroadcastMgrSentActivity"
#define NOTIFICATION_NAME_RECEIVED_WATCH_ACTIVITY     "ReceivedWatchActivity"    // An activity was received from the watch

#define KEY_NAME_ACTIVITY_ID                          "ActivityId"
#define KEY_NAME_ACTIVITY_TYPE                        "ActivityType"
#define KEY_NAME_ACTIVITY_HASH                        "ActivityHash"
#define KEY_NAME_START_TIME                           "StartTime"
#define KEY_NAME_END_TIME                             "EndTime"
#define KEY_NAME_DISTANCE                             "Distance"
#define KEY_NAME_UNITS                                "Units"
#define KEY_NAME_CALORIES                             "Calories"
#define KEY_NAME_RESPONSE_CODE                        "ResponseCode"
#define KEY_NAME_RESPONSE_STR                         "ResponseStr"
#define KEY_NAME_DATA                                 "Data"
#define KEY_NAME_URL                                  "URL"
#define KEY_NAME_TAG                                  "Tag"
#define KEY_NAME_MESSAGE                              "Message"
#define KEY_NAME_STATUS                               "Status"

#define NOTIFICATION_NAME_INTERVAL_UPDATED            "IntervalUpdated"
#define NOTIFICATION_NAME_INTERVAL_COMPLETE           "IntervalComplete"

#define KEY_NAME_DEVICE_ID                            "DeviceId"
#define KEY_NAME_USER_NAME                            "Name"
#define KEY_NAME_INTERVAL_SEGMENT                     "IntervalSegment"
