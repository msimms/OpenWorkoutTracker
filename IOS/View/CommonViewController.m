// Created by Michael Simms on 9/23/18.
// Copyright (c) 2018 Michael J. Simms. All rights reserved.

#import "CommonViewController.h"
#import "AppStrings.h"

@interface CommonViewController ()

@end

@implementation CommonViewController

- (void)showOneButtonAlert:(NSString*)title withMsg:(NSString*)msg
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title
																			 message:msg
																	  preferredStyle:UIAlertControllerStyleAlert];           
	[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:nil]];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)displayEmailComposerSheet:(NSString*)subjectStr withBody:(NSString*)bodyStr withFileName:(NSString*)fileName withMimeType:(NSString*)mimeType withDelegate:(id)delegate
{
	if ([MFMailComposeViewController canSendMail])
	{
		MFMailComposeViewController* mailController = [[MFMailComposeViewController alloc] init];

		if (mailController)
		{
			[mailController setEditing:TRUE];
			[mailController setSubject:subjectStr];
			[mailController setMessageBody:bodyStr isHTML:NO];
			[mailController setMailComposeDelegate:delegate];
			
			if (fileName)
			{
				NSString* justTheFileName = [[[NSFileManager defaultManager] displayNameAtPath:fileName] lastPathComponent];
				NSData* myData = [NSData dataWithContentsOfFile:fileName];

				[mailController addAttachmentData:myData mimeType:mimeType fileName:justTheFileName];
			}
			
			[self presentViewController:mailController animated:YES completion:nil];
		}
	}
	else
	{
		[self showOneButtonAlert:STR_ERROR withMsg:MSG_MAIL_DISABLED];
	}
}

@end
