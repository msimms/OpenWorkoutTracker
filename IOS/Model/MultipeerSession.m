// Created by Michael Simms on 9/4/21.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "MultipeerSession.h"

#if !OMIT_BROADCAST

#define SERVICE_TYPE "nearby-riders"

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

- (void)setupPeerAndSession
{
	self->peerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];

	self->session = [[MCSession alloc] initWithPeer:self->peerID securityIdentity:nil encryptionPreference:MCEncryptionOptional];
	self->session.delegate = self;

	self->advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self->peerID discoveryInfo:nil serviceType:@SERVICE_TYPE];
	self->advertiser.delegate = self;

	self->browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self->peerID serviceType:@SERVICE_TYPE];
	self->browser.delegate = self;

	[self->advertiser startAdvertisingPeer];
	[self->browser startBrowsingForPeers];
}

#pragma mark MCSessionDelegate methods

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

#pragma mark MCNearbyServiceAdvertiserDelegate methods

- (void)advertiser:(nonnull MCNearbyServiceAdvertiser*)advertiser didNotStartAdvertisingPeer:(NSError*)error
{
}

- (void)advertiser:(nonnull MCNearbyServiceAdvertiser*)advertiser didReceiveInvitationFromPeer:(nonnull MCPeerID*)peerID withContext:(NSData*)context invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler
{
}

#pragma mark

- (void)browser:(nonnull MCNearbyServiceBrowser*)browser didNotStartBrowsingForPeers:(NSError*)error
{
}

- (void)browser:(nonnull MCNearbyServiceBrowser*)browser foundPeer:(nonnull MCPeerID*)peerID withDiscoveryInfo:(NSDictionary<NSString *,NSString *> *)info
{
}

- (void)browser:(nonnull MCNearbyServiceBrowser*)browser lostPeer:(nonnull MCPeerID*)peerID
{
}

@end

#endif
