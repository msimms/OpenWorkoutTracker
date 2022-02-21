// Created by Michael Simms on 2/4/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#import <Foundation/Foundation.h>
#import <NearbyInteraction/NearbyInteraction.h>

@interface NearbyInteractionsMgr : NSObject<NISessionDelegate>
{
	NISession* session;
}

+ (BOOL)isAvailable;

- (void)start;
- (void)stop;

@end
