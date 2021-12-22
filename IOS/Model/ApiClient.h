// Created by Michael Simms on 4/21/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#import <Foundation/Foundation.h>

@interface ApiClient : NSObject

+ (BOOL)serverLogin:(NSString*)username withPassword:(NSString*)password;
+ (BOOL)serverCreateLogin:(NSString*)username withPassword:(NSString*)password1 withConfirmation:(NSString*)password2 withRealName:(NSString*)realname;
+ (BOOL)serverIsLoggedIn;
+ (BOOL)serverLogout;
+ (BOOL)serverListFriends;
+ (BOOL)serverListGear;
+ (BOOL)serverListPlannedWorkouts;
+ (BOOL)serverListIntervalWorkouts;
+ (BOOL)serverListPacePlans;
+ (BOOL)serverRequestActivityMetadata:(NSString*)activityId;
+ (BOOL)serverRequestWorkoutDetails:(NSString*)workoutId;
+ (BOOL)serverRequestToFollow:(NSString*)targetUsername;
+ (BOOL)serverDeleteActivity:(NSString*)activityId;
+ (BOOL)serverCreateTag:(NSString*)tag forActivity:(NSString*)activityId;
+ (BOOL)serverDeleteTag:(NSString*)tag forActivity:(NSString*)activityId;
+ (BOOL)serverClaimDevice:(NSString*)deviceId;
+ (BOOL)serverSetUserWeight:(NSNumber*)weightKg withTimestamp:(NSNumber*)timestamp;
+ (BOOL)serverSetActivityName:(NSString*)activityId withName:(NSString*)name;
+ (BOOL)serverSetActivityDescription:(NSString*)activityId withDescription:(NSString*)description;
+ (BOOL)serverRequestUpdatesSince:(time_t)ts;
+ (BOOL)serverHasActivity:(NSString*)activityId withHash:(NSString*)activityHash;
+ (BOOL)sendActivityToServer:(NSString*)activityId withName:activityName withContents:(NSData*)contents;
+ (BOOL)sendIntervalWorkoutToServer:(NSMutableDictionary*)description;
+ (BOOL)sendPacePlanToServer:(NSMutableDictionary*)description;

@end
