// Created by Michael Simms on 7/29/19.
// Copyright © 2019 Michael J Simms. All rights reserved.

#import <Foundation/Foundation.h>

@interface ActivityHash : NSObject

- (id)init;

- (NSString*)calculateWithActivityId:(NSString*)activityId;

@end
