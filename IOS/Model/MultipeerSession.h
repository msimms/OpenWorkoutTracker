// Created by Michael Simms on 9/4/21.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

#import "Defines.h"

#if !OMIT_BROADCAST

@interface MultipeerSession : NSObject<MCSessionDelegate>
{
	MCPeerID* peerID;
	MCSession* session;
	MCAdvertiserAssistant* advertiser;
}

@end

#endif
