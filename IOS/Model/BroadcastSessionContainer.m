// Created by Michael Simms on 4/8/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "BroadcastSessionContainer.h"
#import "AppDelegate.h"
#import "Notifications.h"

@implementation BroadcastSessionContainer

#pragma mark MCSessionDelegate methods

// Override this method to handle changes to peer session state
- (void)session:(MCSession*)session peer:(MCPeerID*)peerID didChangeState:(MCSessionState)state
{
}

// MCSession Delegate callback when receiving data from a peer in a given session
- (void)session:(MCSession*)session didReceiveData:(NSData*)data fromPeer:(MCPeerID*)peerID
{
	@try
	{
		NSError* error;
		NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
															 options:kNilOptions
															   error:&error];
		if (json)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_PEER_LOCATION_UPDATED object:json];
		}
	}
	@catch (NSException* exception)
	{
	}
	@finally
	{
	}
}

// MCSession delegate callback when we start to receive a resource from a peer in a given session
- (void)session:(MCSession*)session didStartReceivingResourceWithName:(NSString*)resourceName fromPeer:(MCPeerID*)peerID withProgress:(NSProgress*)progress
{
}

// MCSession delegate callback when a incoming resource transfer ends (possibly with error)
- (void)session:(MCSession*)session didFinishReceivingResourceWithName:(NSString*)resourceName fromPeer:(MCPeerID*)peerID atURL:(NSURL*)localURL withError:(NSError*)error
{
}

// Streaming API not utilized in this sample code
- (void)session:(MCSession*)session didReceiveStream:(NSInputStream*)stream withName:(NSString*)streamName fromPeer:(MCPeerID*)peerID
{
}

#pragma mark 

// Method for sending text messages to all connected remote peers. Returns a message type transcript
- (BroadcastMessage*)sendMessage:(NSString*)message
{
	// Convert the string into a UTF8 encoded data
	NSData* messageData = [message dataUsingEncoding:NSUTF8StringEncoding];

	// Send text message to all connected peers
	NSError* error;
	[self.session sendData:messageData toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
	if (error)
	{
		return nil;
	}

	// Create a new send transcript
	return [[BroadcastMessage alloc] initWithPeerID:_session.myPeerID message:message];
}

@end
