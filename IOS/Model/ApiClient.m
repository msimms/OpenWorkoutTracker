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
	if (![Preferences shouldBroadcastGlobally])
	{
		return FALSE;
	}

	NSMutableDictionary* downloadedData = [[NSMutableDictionary alloc] init];
	[downloadedData setObject:urlStr forKey:@KEY_NAME_URL];

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

		if (downloadedData)
		{
			[downloadedData setObject:[[NSNumber alloc] initWithInteger:httpCode] forKey:@KEY_NAME_RESPONSE_CODE];

			NSString* dataStr = [NSString stringWithFormat:@""];
			if (data && [data length] > 0)
			{
				NSString* tempStr = [NSString stringWithUTF8String:[data bytes]];
				if (tempStr)
					dataStr = tempStr;
			}

			[downloadedData setObject:dataStr forKey:@KEY_NAME_RESPONSE_STR];
			[downloadedData setObject:[[NSMutableData alloc] init] forKey:@KEY_NAME_DATA];
		}

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
		else if ([urlStr rangeOfString:@REMOTE_API_LIST_FOLLOWING_URL].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_FOLLOWING_LIST_UPDATED object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_LIST_FOLLOWED_BY_URL].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_FOLLOWED_BY_LIST_UPDATED object:downloadedData];
			} );
		}
		else if ([urlStr rangeOfString:@REMOTE_API_LIST_GEAR].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_GEAR_LIST object:downloadedData];
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
	}];
	[dataTask resume];
	
	return TRUE;
#endif
}

+ (BOOL)serverLoginAsync:(NSString*)username withPassword:(NSString*)password
{
#if OMIT_BROADCAST
	return FALSE;
#else
	[Preferences setBroadcastUserName:username];

	NSString* post = [NSString stringWithFormat:@"{"];
	NSMutableData* postData = [[post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] mutableCopy];
	[postData appendData:[[NSString stringWithFormat:@"\"username\": \"%@\",", username] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"\"password\": \"%@\",", password] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"\"device\": \"%@\"", [Preferences uuid]] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"}"] dataUsingEncoding:NSASCIIStringEncoding]];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_LOGIN_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:postData];
#endif
}

+ (BOOL)serverCreateLoginAsync:(NSString*)username withPassword:(NSString*)password1 withConfirmation:(NSString*)password2 withRealName:(NSString*)realname
{
#if OMIT_BROADCAST
	return FALSE;
#else
	[Preferences setBroadcastUserName:username];

	NSString* post = [NSString stringWithFormat:@"{"];
	NSMutableData* postData = [[post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] mutableCopy];
	[postData appendData:[[NSString stringWithFormat:@"\"username\": \"%@\",", username] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"\"password1\": \"%@\",", password1] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"\"password2\": \"%@\",", password2] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"\"realname\": \"%@\",", realname] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"\"device\": \"%@\"", [Preferences uuid]] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"}"] dataUsingEncoding:NSASCIIStringEncoding]];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_CREATE_LOGIN_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:postData];
#endif
}

+ (BOOL)serverIsLoggedInAsync
{
	NSString* str = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_IS_LOGGED_IN_URL];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
}

+ (BOOL)serverLogoutAsync
{
	NSString* str = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_LOGOUT_URL];
	return [self makeRequest:str withMethod:@"POST" withPostData:nil];
}

+ (BOOL)serverListFollowingAsync
{
	NSString* str = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_LIST_FOLLOWING_URL];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
}

+ (BOOL)serverListFollowedByAsync
{
	NSString* str = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_LIST_FOLLOWED_BY_URL];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
}

+ (BOOL)retrieveRemoteGearList
{
	NSString* str = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_LIST_GEAR];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
}

+ (BOOL)serverRequestToFollowAsync:(NSString*)targetUsername
{
	NSString* params = [NSString stringWithFormat:@"target_email=%@", targetUsername];
	NSString* escapedParams = [params stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
	NSString* str = [NSString stringWithFormat:@"%@://%@/%s%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_REQUEST_TO_FOLLOW_URL, escapedParams];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
}

+ (BOOL)serverDeleteActivityAsync:(NSString*)activityId
{
	NSString* params = [NSString stringWithFormat:@"activity_id=%@", activityId];
	NSString* escapedParams = [params stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
	NSString* str = [NSString stringWithFormat:@"%@://%@/%s%@", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_DELETE_ACTIVITY_URL, escapedParams];
	return [self makeRequest:str withMethod:@"GET" withPostData:nil];
}

+ (BOOL)serverCreateTagAsync:(NSString*)tag forActivity:(NSString*)activityId
{
	NSString* post = [NSString stringWithFormat:@"{"];
	NSMutableData* postData = [[post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] mutableCopy];
	[postData appendData:[[NSString stringWithFormat:@"\"tag\": \"%@\",", tag] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"\"activity_id\": \"%@\"", activityId] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"}"] dataUsingEncoding:NSASCIIStringEncoding]];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_CREATE_TAG_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:postData];
}

+ (BOOL)serverDeleteTagAsync:(NSString*)tag forActivity:(NSString*)activityId
{
	NSString* post = [NSString stringWithFormat:@"{"];
	NSMutableData* postData = [[post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] mutableCopy];
	[postData appendData:[[NSString stringWithFormat:@"\"tag\": \"%@\",", tag] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"\"activity_id\": \"%@\"", activityId] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"}"] dataUsingEncoding:NSASCIIStringEncoding]];
	
	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_DELETE_TAG_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:postData];
}

+ (BOOL)serverClaimDeviceAsync:(NSString*)deviceId
{
	NSString* post = [NSString stringWithFormat:@"{"];
	NSMutableData* postData = [[post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] mutableCopy];
	[postData appendData:[[NSString stringWithFormat:@"\"device_id\": \"%@\"", [Preferences uuid]] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"}"] dataUsingEncoding:NSASCIIStringEncoding]];

	NSString* urlStr = [NSString stringWithFormat:@"%@://%@/%s", [Preferences broadcastProtocol], [Preferences broadcastHostName], REMOTE_API_CLAIM_DEVICE_URL];
	return [self makeRequest:urlStr withMethod:@"POST" withPostData:postData];
}

@end
