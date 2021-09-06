// Created by Michael Simms on 9/4/21.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "MultipeerSession.h"

#if !OMIT_BROADCAST

@implementation MultipeerSession

- (id)init
{
	if (self = [super init])
	{
		self->peerID = nil;
		self->session = nil;
		self->advertiser = nil;
	}
	return self;
}

- (void)dealloc
{
}

- (void)setupPeerAndSessionWithDisplayName:(NSString*)displayName
{
	self->peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
	self->session = [[MCSession alloc] initWithPeer:self->peerID];
	self->session.delegate = self;
}

- (void)session:(MCSession*)session peer:(MCPeerID*)peerID didChangeState:(MCSessionState)state
{
}

- (void)session:(MCSession*)session didReceiveData:(NSData*)data fromPeer:(MCPeerID*)peerID
{
}

- (void)session:(MCSession*)session didStartReceivingResourceWithName:(NSString*)resourceName fromPeer:(MCPeerID*)peerID withProgress:(NSProgress*)progress
{
}

- (void)session:(MCSession*)session didFinishReceivingResourceWithName:(NSString*)resourceName fromPeer:(MCPeerID*)peerID atURL:(NSURL*)localURL withError:(NSError*)error
{	
}

- (void)session:(MCSession*)session didReceiveStream:(NSInputStream*)stream withName:(NSString*)streamName fromPeer:(MCPeerID*)peerID
{	
}

@end

#endif
