// Created by Michael Simms on 9/23/18.
// Copyright (c) 2018 Michael J. Simms. All rights reserved.

#import <UIKit/UIKit.h>

#import <MessageUI/MFMailComposeViewController.h>

@interface CommonViewController : UIViewController <UIActionSheetDelegate>
{
}

- (void)showOneButtonAlert:(NSString*)title withMsg:(NSString*)msg;

- (void)displayEmailComposerSheet:(NSString*)subjectStr withBody:(NSString*)bodyStr withFileName:(NSString*)fileName withMimeType:(NSString*)mimeType withDelegate:(id)delegate;

@end
