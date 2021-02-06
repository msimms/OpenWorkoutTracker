// Created by Michael Simms on 9/23/18.
// Copyright (c) 2018 Michael J. Simms. All rights reserved.

#import <UIKit/UIKit.h>

#import <MessageUI/MFMailComposeViewController.h>

/**
* Base class for holding code common to many view controllers.
*/
@interface CommonViewController : UIViewController <UIActionSheetDelegate>
{
	IBOutlet UINavigationItem* navItem;
	IBOutlet UIToolbar*        toolbar;
}

- (void)initializeNavButtonColor;
- (void)showOneButtonAlert:(NSString*)title withMsg:(NSString*)msg;
- (void)displayEmailComposerSheet:(NSString*)subjectStr withBody:(NSString*)bodyStr withFileName:(NSString*)fileName withMimeType:(NSString*)mimeType withDelegate:(id)delegate;
- (UIImage*)activityTypeToIcon:(NSString*)activityType;
- (BOOL)isDarkModeEnabled;

@property (nonatomic, retain) IBOutlet UINavigationItem* navItem;
@property (nonatomic, retain) IBOutlet UIToolbar*        toolbar;

@end
