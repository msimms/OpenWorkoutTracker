// Created by Michael Simms on 4/21/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#import "ApiClient.h"
#import "Preferences.h"
#import "Notifications.h"
#import "Urls.h"

@implementation ApiClient

+ (BOOL)makeRequest:(NSString*)urlStr withMethod:(NSString*)method withPostData:(NSMutableData*)postData
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:urlStr]];
	[request setHTTPMethod:method];

	if (postData)
	{
		NSString* postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
		[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody:postData];
	}

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
		else if ([urlStr rangeOfString:@REMOTE_API_LIST_GEAR].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_GEAR_LIST_UPDATED object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_LIST_WORKOUTS].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_PLANNED_WORKOUTS_UPDATED object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_REQUEST_WORKOUT_DETAILS].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_WORKOUT_UPDATED object:downloadedData];
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
		else if ([urlStr rangeOfString:@REMOTE_API_UPDATE_PROFILE].location != NSNotFound)
		{
		}
		else if ([urlStr rangeOfString:@REMOTE_API_HAS_ACTIVITY].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_HAS_ACTIVITY_RESPONSE object:downloadedData];
			} );
		}
	}];

	[dataTask resume];
	
	return TRUE;
#endif
}

+ (BOOL)serverLogin:(NSString*)username withPassword:(NSString*)password
{
#if OMIT_BROADCAST
	return FALSE;
#else
	[Preferences setBroadcastUserName:username];

	NSMutableDictionary* postDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:username, KEY_NAME_USERNAME,
									 password, KEY_NAME_PASSWORD,
									 [Preferences uuid], KEY_NAME_DEVICE,
									 nil];
	NSError* error;
	NSData* postData = [NSJSONSerialization dataWithJSONObject:postDict options:NSJSONWritingPrettyPrinted error:&error];
	NSMutableData* mutablePostData = [[NSMutableData alloc] initWithData:postData];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_LOGIN_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:mutablePostData];
#endif
}

+ (BOOL)serverCreateLogin:(NSString*)username withPassword:(NSString*)password1 withConfirmation:(NSString*)password2 withRealName:(NSString*)realname
{
#if OMIT_BROADCAST
	return FALSE;
#else
	[Preferences setBroadcastUserName:username];

	NSMutableDictionary* postDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:username, KEY_NAME_USERNAME,
									 password1, KEY_NAME_PASSWORD1,
									 password2, KEY_NAME_PASSWORD2,
									 realname, KEY_NAME_REALNAME,
									 [Preferences uuid], KEY_NAME_DEVICE,
									 nil];
	NSError* error;
	NSData* postData = [NSJSONSerialization dataWithJSONObject:postDict options:NSJSONWritingPrettyPrinted error:&error];
	NSMutableData* mutablePostData = [[NSMutableData alloc] initWithData:postData];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_CREATE_LOGIN_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:mutablePostData];
#endif
}

+ (BOOL)serverIsLoggedIn
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_IS_LOGGED_IN_URL];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

+ (BOOL)serverLogout
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_LOGOUT_URL];
	return [self makeRequest:str withMethod:@"POST" withPostData:nil];
#endif
}

+ (BOOL)serverListFriends
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_LIST_FRIENDS_URL];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

+ (BOOL)serverListGear
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_LIST_GEAR];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

+ (BOOL)serverListPlannedWorkouts
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_LIST_WORKOUTS];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

+ (BOOL)serverRequestWorkoutDetails:(NSString*)workoutId
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%s?", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_REQUEST_WORKOUT_DETAILS];

	str = [str stringByAppendingString:[NSString stringWithFormat:@"%s=%@&", KEY_NAME_WORKOUT_ID, workoutId]];
	str = [str stringByAppendingString:[NSString stringWithFormat:@"format=json"]];

	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

+ (BOOL)serverRequestToFollow:(NSString*)targetUsername
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* params = [NSString stringWithFormat:@"%s=%@", KEY_NAME_TARGET_EMAIL, targetUsername];
	NSString* escapedParams = [params stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
	NSString* str = [NSString stringWithFormat:@"%@://%@/%s%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_REQUEST_TO_FOLLOW_URL, escapedParams];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

+ (BOOL)serverDeleteActivity:(NSString*)activityId
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* params = [NSString stringWithFormat:@"%s=%@", KEY_NAME_ACTIVITY_ID2, activityId];
	NSString* escapedParams = [params stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
	NSString* str = [NSString stringWithFormat:@"%@://%@/%s%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_DELETE_ACTIVITY_URL, escapedParams];
	return [self makeRequest:str withMethod:@"POST" withPostData:nil];
#endif
}

+ (BOOL)serverCreateTag:(NSString*)tag forActivity:(NSString*)activityId
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSMutableDictionary* postDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:activityId, @KEY_NAME_ACTIVITY_ID2,
									 tag, KEY_NAME_TAG2,
									 nil];
	NSError* error;
	NSData* postData = [NSJSONSerialization dataWithJSONObject:postDict options:NSJSONWritingPrettyPrinted error:&error];
	NSMutableData* mutablePostData = [[NSMutableData alloc] initWithData:postData];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_CREATE_TAG_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:mutablePostData];
#endif
}

+ (BOOL)serverDeleteTag:(NSString*)tag forActivity:(NSString*)activityId
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSMutableDictionary* postDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:activityId, @KEY_NAME_ACTIVITY_ID2,
									 tag, KEY_NAME_TAG2,
									 nil];
	NSError* error;
	NSData* postData = [NSJSONSerialization dataWithJSONObject:postDict options:NSJSONWritingPrettyPrinted error:&error];
	NSMutableData* mutablePostData = [[NSMutableData alloc] initWithData:postData];
	
	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_DELETE_TAG_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:mutablePostData];
#endif
}

+ (BOOL)serverClaimDevice:(NSString*)deviceId
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* post = [NSString stringWithFormat:@"{"];
	NSMutableData* postData = [[post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] mutableCopy];

	[postData appendData:[[NSString stringWithFormat:@"\"%s\": \"%@\"", KEY_NAME_DEVICE_ID2, [Preferences uuid]] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"}"] dataUsingEncoding:NSASCIIStringEncoding]];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_CLAIM_DEVICE_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:postData];
#endif
}

+ (BOOL)serverSetUserWeight:(NSNumber*)weightKg
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* post = [NSString stringWithFormat:@"{"];
	NSMutableData* postData = [[post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] mutableCopy];

	[postData appendData:[[NSString stringWithFormat:@"\"%s\": \"%@\"", KEY_NAME_WEIGHT, weightKg] dataUsingEncoding:NSASCIIStringEncoding]];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_UPDATE_PROFILE];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:postData];
#endif
}

+ (BOOL)serverHasActivity:(NSString*)activityId withHash:(NSString*)activityHash
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* str = [NSString stringWithFormat:@"%@://%@/%s?", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_HAS_ACTIVITY];

	str = [str stringByAppendingString:[NSString stringWithFormat:@"%s=%@&", KEY_NAME_ACTIVITY_ID2, activityId]];
	str = [str stringByAppendingString:[NSString stringWithFormat:@"%s=%@&", KEY_NAME_ACTIVITY_HASH2, activityHash]];

	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
#endif
}

+ (BOOL)sendActivityToServer:(NSString*)activityId withName:activityName withContents:(NSData*)contents
{
#if OMIT_BROADCAST
	return FALSE;
#else
	NSString* base64Contents = [contents base64EncodedStringWithOptions:kNilOptions];
	NSMutableDictionary* postDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:activityId, @KEY_NAME_ACTIVITY_ID2,
									 activityName, @KEY_NAME_UPLOADED_FILE_NAME,
									 base64Contents, @KEY_NAME_UPLOADED_FILE_DATA,
									 nil];
	NSError* error;
	NSData* postData = [NSJSONSerialization dataWithJSONObject:postDict options:NSJSONWritingPrettyPrinted error:&error];
	NSMutableData* mutablePostData = [[NSMutableData alloc] initWithData:postData];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_UPLOAD_ACTIVITY_FILE];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:mutablePostData];
#endif
}

@end
