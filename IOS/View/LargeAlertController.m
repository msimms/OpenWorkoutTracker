// Created by Michael Simms on 9/5/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#import <Foundation/Foundation.h>
#import "LargeAlertController.h"

@implementation LargeAlertController

- (void)loadView
{
	CGRect textViewRect = CGRectMake(0, 0, 300, 1024);

	self.view = [[UIView alloc] initWithFrame:textViewRect];
	self.view.backgroundColor = [UIColor systemGray5Color];

	UIStackView* stackView = [[UIStackView alloc] initWithFrame:textViewRect];
	stackView.translatesAutoresizingMaskIntoConstraints = NO;
	stackView.axis = UILayoutConstraintAxisVertical;

	NSLayoutConstraint* c1 = [NSLayoutConstraint constraintWithItem:self.view
														  attribute:NSLayoutAttributeCenterX
														  relatedBy:NSLayoutRelationEqual
															 toItem:stackView
														  attribute:NSLayoutAttributeCenterX
														 multiplier:1
														   constant:0];

	NSLayoutConstraint* c2 = [NSLayoutConstraint constraintWithItem:self.view
														  attribute:NSLayoutAttributeLeftMargin
														  relatedBy:NSLayoutRelationEqual
															 toItem:stackView
														  attribute:NSLayoutAttributeLeftMargin
														 multiplier:1
														   constant:-16];

	NSLayoutConstraint* c3 = [NSLayoutConstraint constraintWithItem:self.view
														  attribute:NSLayoutAttributeRightMargin
														  relatedBy:NSLayoutRelationEqual
															 toItem:stackView
														  attribute:NSLayoutAttributeRightMargin
														 multiplier:1
														   constant:-16];

	NSLayoutConstraint* c4 = [NSLayoutConstraint constraintWithItem:self.view
														  attribute:NSLayoutAttributeTopMargin
														  relatedBy:NSLayoutRelationEqual
															 toItem:stackView
														  attribute:NSLayoutAttributeTopMargin
														 multiplier:1
														   constant:-16];

	[self.view addConstraint:c1];
	[self.view addConstraint:c2];
	[self.view addConstraint:c3];
	[self.view addConstraint:c4];

	BOOL usingDarkMode = [self isDarkModeEnabled];

	// Title
	UILabel* titleLabel = [[UILabel alloc] init];
	titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
	titleLabel.text = self->title;
	titleLabel.textAlignment = NSTextAlignmentCenter;
	titleLabel.center = self.view.center;
	titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];

	// Subtitle / description
	UILabel* descriptionLabel = [[UILabel alloc] init];
	descriptionLabel.text = self->subtitle;
	descriptionLabel.textAlignment = NSTextAlignmentCenter;
	descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
	descriptionLabel.center = self.view.center;
	descriptionLabel.font = [UIFont fontWithName:@"Helvetica" size:15];

	// Large text edit
	self->textView = [[UITextView alloc] initWithFrame:textViewRect];
	self->textView.delegate = self;
	self->textView.backgroundColor = [UIColor whiteColor];
	self->textView.text = self->defaultText;
	self->textView.textAlignment = NSTextAlignmentLeft;
	self->textView.translatesAutoresizingMaskIntoConstraints = NO;
	self->textView.center = self.view.center;
	self->textView.font = [UIFont fontWithName:@"Helvetica" size:15];
	self->textView.textColor = [UIColor blackColor];
	self->textView.scrollEnabled = NO;
	self->textView.userInteractionEnabled = YES;
	self->textView.editable = YES;
	self->textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
	self->textView.keyboardType = UIKeyboardTypeDefault;
	self->textView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
	self->textView.textContainer.maximumNumberOfLines = 10;

	// Cancel button
	UIButton* cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[cancelBtn setTitle:@"Cancel" forState:UIControlStateNormal];
	[cancelBtn setTitleColor:usingDarkMode ? [UIColor whiteColor] : [UIColor blackColor] forState:UIControlStateNormal];
	[cancelBtn setBackgroundColor:usingDarkMode ? [UIColor systemGrayColor] : [UIColor whiteColor]];
	[cancelBtn addTarget:self action:@selector(cancelButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
	cancelBtn.center = self.view.center;

	// Ok button
	UIButton* okBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[okBtn setTitle:@"Ok" forState:UIControlStateNormal];
	[okBtn setTitleColor:usingDarkMode ? [UIColor whiteColor] : [UIColor blackColor] forState:UIControlStateNormal];
	[okBtn setBackgroundColor:usingDarkMode ? [UIColor systemGrayColor] : [UIColor whiteColor]];
	[okBtn addTarget:self action:@selector(okButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
	okBtn.center = self.view.center;

	// Stack all the elements
	[stackView addArrangedSubview:titleLabel];
	[stackView setCustomSpacing:14 afterView:titleLabel];
	[stackView addArrangedSubview:descriptionLabel];
	[stackView setCustomSpacing:14 afterView:descriptionLabel];
	[stackView addArrangedSubview:self->textView];
	[stackView setCustomSpacing:14 afterView:self->textView];
	[stackView addArrangedSubview:cancelBtn];
	[stackView setCustomSpacing:14 afterView:cancelBtn];
	[stackView addArrangedSubview:okBtn];

	[self.view addSubview:stackView];
}

#pragma mark button handlers

- (IBAction)cancelButtonClicked:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)okButtonClicked:(id)sender
{
	if (self->completionHandler)
	{
		self->completionHandler(self->textView.text);
	}
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField
{
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField*)textField
{
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField*)textField
{
}

- (void)textFieldDidEndEditing:(UITextField*)textField
{
}

#pragma mark UITextViewDelegate methods

- (BOOL)textViewShouldBeginEditing:(UITextView*)textView
{
	return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView*)textView
{
	return YES;
}

- (void)textViewDidBeginEditing:(UITextView*)textView
{
}

- (void)textViewDidEndEditing:(UITextView*)textView
{
}

- (void)textViewDidChange:(UITextView*)textView
{
	CGFloat fixedWidth = textView.frame.size.width;
	CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
	CGRect newFrame = textView.frame;

	newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
	textView.frame = newFrame;
}

@end
