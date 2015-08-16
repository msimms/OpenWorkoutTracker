//
//  Dropbox.h
//
//  Created by Michael Simms on 6/30/12.
//  Copyright (c) 2012 Michael J. Simms. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DropboxSDK.h"
#import "FileSharingWebsite.h"

@interface Dropbox : FileSharingWebsite <DBSessionDelegate, DBNetworkRequestDelegate, DBRestClientDelegate>
{
//	DBRestClient* restClient;
}

- (NSString*)name;

- (id)init;

- (BOOL)link:(NSString*)appKey :(NSString*)appSecret :(NSString*)root;
- (BOOL)unlink;
- (BOOL)isLinked;

- (BOOL)uploadFile:(NSString*)filePath;

@end
