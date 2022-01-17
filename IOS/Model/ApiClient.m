// Created by Michael Simms on 4/21/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#import "ApiClient.h"
#import "Preferences.h"
#import "Notifications.h"
#import "Params.h"
#import "Urls.h"

@implementation ApiClient

// Sends a request to the server, also includes the asynchronous response handler.
+ (BOOL)makeRequest:(NSString*)urlStr withMethod:(NSString*)method withPostData:(NSMutableData*)postData
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:urlStr]];
	[request setHTTPMethod:method];

	// Attach the post data, if any.
	if (postData)
	{
		NSString* postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
		[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody:postData];
	}

	// Make the request.
	NSURLSession* session = [NSURLSession sharedSession];
	NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request
												completionHandler:^(NSData* data, NSURLResponse* response, NSError* error)
	{
		NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
		NSInteger httpCode = [httpResponse statusCode];

		NSMutableDictionary* downloadedData = [[NSMutableDictionary alloc] init];
		[downloadedData setObject:urlStr forKey:@KEY_NAME_URL];
		[downloadedData setObject:[[NSNumber alloc] initWithInteger:httpCode] forKey:@KEY_NAME_RESPONSE_CODE];

		NSString* dataStr = [NSString stringWithFormat:@""];
		if (data && [data length] > 0)
		{
			NSString* tempStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			if (tempStr)
				dataStr = tempStr;
		}

		[downloadedData setObject:dataStr forKey:@KEY_NAME_RESPONSE_STR];
		[downloadedData setObject:[[NSMutableData alloc] init] forKey:@KEY_NAME_DATA];

		if ([urlStr rangeOfString:@REMOTE_API_IS_LOGGED_IN_URL].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_LOGIN_CHECKED object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_LOGIN_URL].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_LOGIN_PROCESSED object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_CREATE_LOGIN_URL].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_CREATE_LOGIN_PROCESSED object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_LOGOUT_URL].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_LOGGED_OUT object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_LIST_FRIENDS_URL].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_FRIENDS_LIST_UPDATED object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_LIST_GEAR_URL].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_GEAR_LIST_UPDATED object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_LIST_PLANNED_WORKOUTS_URL].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_PLANNED_WORKOUTS_UPDATED object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_LIST_INTERVAL_WORKOUTS_URL].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_INTERVAL_WORKOUT_UPDATED object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_LIST_PACE_PLANS_URL].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_PACE_PLANS_UPDATED object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_LIST_UNSYNCHED_ACTIVITIES_URL].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_UNSYNCHED_ACTIVITIES_LIST object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_HAS_ACTIVITY_URL].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_HAS_ACTIVITY_RESPONSE object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_REQUEST_ACTIVITY_METADATA_URL].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_ACTIVITY_METADATA object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_REQUEST_WORKOUT_DETAILS_URL].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_PLANNED_WORKOUT_UPDATED object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_REQUEST_TO_FOLLOW_URL].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_REQUEST_TO_FOLLOW_RESULT object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_UPDATE_STATUS_URL].location != NSNotFound)
		{
		}
		else if ([urlStr rangeOfString:@REMOTE_API_CREATE_TAG_URL].location != NSNotFound)
		{
		}
		else if ([urlStr rangeOfString:@REMOTE_API_DELETE_TAG_URL].location != NSNotFound)
		{
		}
		else if ([urlStr rangeOfString:@REMOTE_API_CLAIM_DEVICE_URL].location != NSNotFound)
		{
		}
		else if ([urlStr rangeOfString:@REMOTE_API_UPDATE_PROFILE_URL].location != NSNotFound)
		{
		}
		else if ([urlStr rangeOfString:@REMOTE_API_UPLOAD_ACTIVITY_FILE_URL].location != NSNotFound)
		{
		}
		else if ([urlStr rangeOfString:@REMOTE_API_CREATE_INTERVAL_WORKOUT_URL].location != NSNotFound)
		{
		}
		else if ([urlStr rangeOfString:@REMOTE_API_CREATE_PACE_PLAN_URL].location != NSNotFound)
		{
		}
	}];

	[dataTask resume];
	
	return TRUE;
#endif
}

// Login.
+ (BOOL)serverLogin:(NSString*)username withPassword:(NSString*)password
{
#if OMIT_BROADCAST
	return FALSE;
#else
	[Preferences setBroadcastUserName:username];

	NSMutableDictionary* postDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
									 username, @PARAM_USERNAME,
									 password, @PARAM_PASSWORD,
									 [Preferences uuid], @PARAM_DEVICE,
									 nil];
	NSError* error;
	NSData* postData = [NSJSONSerialization dataWithJSONObject:postDict options:NSJSONWritingPrettyPrinted error:&error];
	NSMutableData* mutablePostData = [[NSMutableData alloc] initWithData:postData];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_LOGIN_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:mutablePostData];
#endif
}

// Create a new logon identity.
+ (BOOL)serverCreateLogin:(NSString*)username withPassword:(NSString*)password1 withConfirmation:(NSString*)password2 withRealName:(NSString*)realname
{
#if OMIT_BROADCAST
	return FALSE;
#else
	[Preferences setBroadcastUserName:username];

	NSMutableDictionary* postDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
									 username, @PARAM_USERNAME,
									 password1, @PARAM_PASSWORD1,
									 password2, @PARAM_PASSWORD2,
									 realname, @PARAM_REALNAME,
									 [Preferences uuid], @PARAM_DEVICE,
									 nil];
	NSError* error;
	NSData* postData = [NSJSONSerialization dataWithJSONObject:postDict options:NSJSONWritingPrettyPrinted error:&error];
	NSMutableData* mutablePostData = [[NSMutableData alloc] initWithData:postData];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_CREATE_LOGIN_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:mutablePostData];
#endif
}

// Determine if we have a valid session or not.
+ (BOOL)serverIsLoggedIn
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_IS_LOGGED_IN_URL];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

// End our session.
+ (BOOL)serverLogout
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_LOGOUT_URL];
	return [self makeRequest:str withMethod:@"POST" withPostData:nil];
#endif
}

// Ask the server for a list of our friends.
+ (BOOL)serverListFriends
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_LIST_FRIENDS_URL];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

// Ask the server for all the gear (for this user) that it knows about.
+ (BOOL)serverListGear
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_LIST_GEAR_URL];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

// Ask the server for all the planned workouts (for this user) that it knows about.
+ (BOOL)serverListPlannedWorkouts
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_LIST_PLANNED_WORKOUTS_URL];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

// Ask the server for all the interval workouts (for this user) that it knows about.
+ (BOOL)serverListIntervalWorkouts
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_LIST_INTERVAL_WORKOUTS_URL];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

// Ask the server for all the pace plans (for this user) that it knows about.
+ (BOOL)serverListPacePlans
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_LIST_PACE_PLANS_URL];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

// Request meatadata for a given activity from the server.
+ (BOOL)serverRequestActivityMetadata:(NSString*)activityId
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%@?", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_REQUEST_ACTIVITY_METADATA_URL];

	str = [str stringByAppendingString:[NSString stringWithFormat:@"%@=%@&", @PARAM_ACTIVITY_ID, activityId]];

	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

// Request details for a given workout from the server.
+ (BOOL)serverRequestWorkoutDetails:(NSString*)workoutId
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%@?", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_REQUEST_WORKOUT_DETAILS_URL];

	str = [str stringByAppendingString:[NSString stringWithFormat:@"%@=%@&", @PARAM_WORKOUT_ID, workoutId]];
	str = [str stringByAppendingString:[NSString stringWithFormat:@"format=json"]];

	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

// Tell the server that we wish to friend someone.
+ (BOOL)serverRequestToFollow:(NSString*)targetUsername
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* params = [NSString stringWithFormat:@"%@=%@", @PARAM_TARGET_EMAIL, targetUsername];
	NSString* escapedParams = [params stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
	NSString* str = [NSString stringWithFormat:@"%@://%@/%@%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_REQUEST_TO_FOLLOW_URL, escapedParams];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

// Ask the server to delete an activity.
+ (BOOL)serverDeleteActivity:(NSString*)activityId
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* params = [NSString stringWithFormat:@"%@=%@", @PARAM_ACTIVITY_ID, activityId];
	NSString* escapedParams = [params stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
	NSString* str = [NSString stringWithFormat:@"%@://%@/%@%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_DELETE_ACTIVITY_URL, escapedParams];
	return [self makeRequest:str withMethod:@"POST" withPostData:nil];
#endif
}

// Tell the server that we wish to add a tag to an activity.
+ (BOOL)serverCreateTag:(NSString*)tag forActivity:(NSString*)activityId
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSMutableDictionary* postDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
									 activityId, @PARAM_ACTIVITY_ID,
									 tag, @PARAM_TAG,
									 nil];
	NSError* error;
	NSData* postData = [NSJSONSerialization dataWithJSONObject:postDict options:NSJSONWritingPrettyPrinted error:&error];
	NSMutableData* mutablePostData = [[NSMutableData alloc] initWithData:postData];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_CREATE_TAG_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:mutablePostData];
#endif
}

// Tell the server that we wish to delete a tag from an activity.
+ (BOOL)serverDeleteTag:(NSString*)tag forActivity:(NSString*)activityId
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSMutableDictionary* postDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
									 activityId, @PARAM_ACTIVITY_ID,
									 tag, @PARAM_TAG,
									 nil];
	NSError* error;
	NSData* postData = [NSJSONSerialization dataWithJSONObject:postDict options:NSJSONWritingPrettyPrinted error:&error];
	NSMutableData* mutablePostData = [[NSMutableData alloc] initWithData:postData];
	
	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_DELETE_TAG_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:mutablePostData];
#endif
}

// Associate this device with a user.
+ (BOOL)serverClaimDevice:(NSString*)deviceId
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* post = [NSString stringWithFormat:@"{"];
	NSMutableData* postData = [[post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] mutableCopy];

	[postData appendData:[[NSString stringWithFormat:@"\"%@\": \"%@\"", @PARAM_DEVICE_ID2, deviceId] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"}"] dataUsingEncoding:NSASCIIStringEncoding]];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_CLAIM_DEVICE_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:postData];
#endif
}

// Send the user's weight to the server.
+ (BOOL)serverSetUserWeight:(NSNumber*)weightKg withTimestamp:(NSNumber*)timestamp
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSMutableDictionary* postDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
									 weightKg, @PARAM_USER_WEIGHT,
									 timestamp, @PARAM_TIMESTAMP,
									 nil];
	NSError* error;
	NSData* postData = [NSJSONSerialization dataWithJSONObject:postDict options:NSJSONWritingPrettyPrinted error:&error];
	NSMutableData* mutablePostData = [[NSMutableData alloc] initWithData:postData];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_UPDATE_PROFILE_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:mutablePostData];
#endif
}

// Sends the new activity name to the server.
+ (BOOL)serverSetActivityName:(NSString*)activityId withName:(NSString*)name
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSMutableDictionary* postDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
									 activityId, @PARAM_ACTIVITY_ID,
									 name, @PARAM_ACTIVITY_NAME2,
									 nil];
	NSError* error;
	NSData* postData = [NSJSONSerialization dataWithJSONObject:postDict options:NSJSONWritingPrettyPrinted error:&error];
	NSMutableData* mutablePostData = [[NSMutableData alloc] initWithData:postData];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_UPDATE_ACTIVITY_PROFILE_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:mutablePostData];
#endif
}

// Sends the new activity description to the server.
+ (BOOL)serverSetActivityDescription:(NSString*)activityId withDescription:(NSString*)description
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSMutableDictionary* postDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
									 activityId, @PARAM_ACTIVITY_ID,
									 description, @PARAM_ACTIVITY_DESCRIPTION,
									 nil];
	NSError* error;
	NSData* postData = [NSJSONSerialization dataWithJSONObject:postDict options:NSJSONWritingPrettyPrinted error:&error];
	NSMutableData* mutablePostData = [[NSMutableData alloc] initWithData:postData];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_UPDATE_ACTIVITY_PROFILE_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:mutablePostData];
#endif
}

+ (BOOL)serverRequestUpdatesSince:(time_t)ts
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%@?", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_LIST_UNSYNCHED_ACTIVITIES_URL];

	str = [str stringByAppendingString:[NSString stringWithFormat:@"%@=%ld", @PARAM_TIMESTAMP, ts]];

	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

// Ask the server if it has the activity with the given ID and hash.
+ (BOOL)serverHasActivity:(NSString*)activityId withHash:(NSString*)activityHash
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%@?", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_HAS_ACTIVITY_URL];

	str = [str stringByAppendingString:[NSString stringWithFormat:@"%@=%@&", @PARAM_ACTIVITY_ID, activityId]];
	str = [str stringByAppendingString:[NSString stringWithFormat:@"%@=%@&", @PARAM_ACTIVITY_HASH, activityHash]];

	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

// Send an activity to the server.
+ (BOOL)sendActivityToServer:(NSString*)activityId withName:activityName withContents:(NSData*)contents
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* base64Contents = [contents base64EncodedStringWithOptions:kNilOptions];
	NSMutableDictionary* postDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
									 activityId, @PARAM_ACTIVITY_ID,
									 activityName, @PARAM_UPLOADED_FILE_NAME,
									 base64Contents, @PARAM_UPLOADED_FILE_DATA,
									 nil];
	NSError* error;
	NSData* postData = [NSJSONSerialization dataWithJSONObject:postDict options:NSJSONWritingPrettyPrinted error:&error];
	NSMutableData* mutablePostData = [[NSMutableData alloc] initWithData:postData];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_UPLOAD_ACTIVITY_FILE_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:mutablePostData];
#endif
}

// Send all our interval workouts to the serve.r
+ (BOOL)sendIntervalWorkoutToServer:(NSMutableDictionary*)description
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSError* error;
	NSData* postData = [NSJSONSerialization dataWithJSONObject:description options:NSJSONWritingPrettyPrinted error:&error];
	NSMutableData* mutablePostData = [[NSMutableData alloc] initWithData:postData];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_CREATE_INTERVAL_WORKOUT_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:mutablePostData];
#endif
}

// Send all our pace plans to the server.
+ (BOOL)sendPacePlanToServer:(NSMutableDictionary*)description
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSError* error;
	NSData* postData = [NSJSONSerialization dataWithJSONObject:description options:NSJSONWritingPrettyPrinted error:&error];
	NSMutableData* mutablePostData = [[NSMutableData alloc] initWithData:postData];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], @REMOTE_API_CREATE_PACE_PLAN_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:mutablePostData];
#endif
}

@end
