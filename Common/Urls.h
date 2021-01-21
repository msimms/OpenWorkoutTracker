// Created by Michael Simms on 6/15/18.
// Copyright (c) 2018 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#pragma once

//
// URL paths
//

#define REMOTE_API_LOGIN_URL               "api/1.0/login"
#define REMOTE_API_CREATE_LOGIN_URL        "api/1.0/create_login"
#define REMOTE_API_IS_LOGGED_IN_URL        "api/1.0/login_status"
#define REMOTE_API_LOGOUT_URL              "api/1.0/logout"
#define REMOTE_API_LIST_FRIENDS_URL        "api/1.0/list_friends"
#define REMOTE_API_LIST_GEAR               "api/1.0/list_gear"
#define REMOTE_API_LIST_PLANNED_WORKOUTS   "api/1.0/list_planned_workouts"
#define REMOTE_API_LIST_INTERVAL_WORKOUTS  "api/1.0/list_interval_workouts"
#define REMOTE_API_LIST_PACE_PLANS         "api/1.0/list_pace_plans"
#define REMOTE_API_HAS_ACTIVITY            "api/1.0/has_activity"
#define REMOTE_API_REQUEST_WORKOUT_DETAILS "api/1.0/export_workout"
#define REMOTE_API_REQUEST_TO_FOLLOW_URL   "api/1.0/request_to_follow?"
#define REMOTE_API_UPDATE_STATUS_URL       "api/1.0/update_status"
#define REMOTE_API_DELETE_ACTIVITY_URL     "api/1.0/delete_activity?"
#define REMOTE_API_CREATE_TAG_URL          "api/1.0/create_tag"
#define REMOTE_API_DELETE_TAG_URL          "api/1.0/delete_tag"
#define REMOTE_API_CLAIM_DEVICE_URL        "api/1.0/claim_device"
#define REMOTE_API_UPDATE_PROFILE          "api/1.0/update_profile"
#define REMOTE_API_UPLOAD_ACTIVITY_FILE    "api/1.0/upload_activity_file"

//
// URL parameters (for HTTP GET) and JSON params (for HTTP POST).
//

#define URL_KEY_NAME_TARGET_EMAIL              "target_email"
#define URL_KEY_NAME_USERNAME                  "username"
#define URL_KEY_NAME_PASSWORD                  "password"
#define URL_KEY_NAME_PASSWORD1                 "password1"
#define URL_KEY_NAME_PASSWORD2                 "password2"
#define URL_KEY_NAME_REALNAME                  "realname"
#define URL_KEY_NAME_DEVICE                    "device"

#define URL_KEY_NAME_ACTIVITY_ID               "activity_id"
#define URL_KEY_NAME_ACTIVITY_HASH             "activity_hash"
#define URL_KEY_NAME_DEVICE_ID2                "device_id"
#define URL_KEY_NAME_TAG                       "tag"
#define URL_KEY_NAME_CODE                      "code"
#define URL_KEY_NAME_WEIGHT                    "weight"
#define URL_KEY_NAME_UPLOADED_FILE_NAME        "uploaded_file_name"
#define URL_KEY_NAME_UPLOADED_FILE_DATA        "uploaded_file_data"
