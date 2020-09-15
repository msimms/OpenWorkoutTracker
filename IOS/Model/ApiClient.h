// Created by Michael Simms on 4/21/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#import <Foundation/Foundation.h>

@interface ApiClient : NSObject

+ (BOOL)serverLoginAsync:(NSString*)username withPassword:(NSString*)password;
+ (BOOL)serverCreateLoginAsync:(NSString*)username withPassword:(NSString*)password1 withConfirmation:(NSString*)password2 withRealName:(NSString*)realname;
+ (BOOL)serverIsLoggedInAsync;
+ (BOOL)serverLogoutAsync;
+ (BOOL)serverListFollowingAsync;
+ (BOOL)serverListFollowedByAsync;
+ (BOOL)serverListGear;
+ (BOOL)serverListPlannedWorkouts;
+ (BOOL)serverRequestWorkoutDetails:(NSString*)workoutId;
+ (BOOL)serverRequestToFollowAsync:(NSString*)targetUsername;
+ (BOOL)serverDeleteActivityAsync:(NSString*)activityId;
+ (BOOL)serverCreateTagAsync:(NSString*)tag forActivity:(NSString*)activityId;
+ (BOOL)serverDeleteTagAsync:(NSString*)tag forActivity:(NSString*)activityId;
+ (BOOL)serverClaimDeviceAsync:(NSString*)deviceId;
+ (BOOL)serverSetUserWeight:(NSNumber*)weightKg;

@end
