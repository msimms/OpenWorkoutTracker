// Created by Michael Simms on 2/4/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#import "NearbyInteractionsMgr.h"

@implementation NearbyInteractionsMgr

+ (BOOL)isAvailable
{
	return [NISession isSupported];
}

- (void)start
{
	self->session = [[NISession alloc] init];
	session.delegate = self;

//	NINearbyPeerConfiguration* configuration = [NINearbyPeerConfiguration alloc] initWithPeerToken:peerDiscoverToken];
//	[session runWithConfiguration:configuration];
}

- (void)stop
{
}

@end
