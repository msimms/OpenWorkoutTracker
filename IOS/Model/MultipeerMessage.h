// Created by Michael Simms on 4/15/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

#import <Foundation/Foundation.h>

@class MCPeerID;

@interface MultipeerMessage : NSObject
{
}

@property (readonly, nonatomic) MCPeerID* peerID; // PeerID of the sender
@property (readonly, nonatomic) NSNumber* version; // Message version
@property (readonly, nonatomic) NSString* message; // String message (optional)

- (id)initWithPeerID:(MCPeerID*)peerID message:(NSString*)message;

@end
