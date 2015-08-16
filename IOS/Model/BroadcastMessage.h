// Created by Michael Simms on 4/15/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

@class MCPeerID;

@interface BroadcastMessage : NSObject

// PeerID of the sender
@property (readonly, nonatomic) MCPeerID* peerID;
// Message version
@property (readonly, nonatomic) NSNumber* version;
// String message (optional)
@property (readonly, nonatomic) NSString* message;

- (id)initWithPeerID:(MCPeerID*)peerID message:(NSString*)message;

@end
