// Created by Michael Simms on 4/15/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "BroadcastMessage.h"

@implementation BroadcastMessage

- (id)initWithPeerID:(MCPeerID*)peerID message:(NSString*)message
{
	if (self = [super init])
	{
		_peerID = peerID;
		_version = [[NSNumber alloc] initWithInt:1];
		_message = message;
	}
	return self;
}

@end
