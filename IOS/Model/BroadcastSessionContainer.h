// Created by Michael Simms on 4/8/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "BroadcastMessage.h"

@interface BroadcastSessionContainer : NSObject <MCSessionDelegate>

@property (readonly, nonatomic) MCSession* session;

// Method for sending text messages to all connected remote peers. Returns a message type transcript
- (BroadcastMessage*)sendMessage:(NSString*)message;

@end
