//
//  VGDialog.m
//  Moonlander
//
//  Created by Rick Naro on 10/3/11.
//  Copyright (c) 2011 Paradigm Systems. All rights reserved.
//

#import "VGDialog.h"

@implementation VGDialog

@synthesize yesButtonView=_yesButtonView;
@synthesize dialogYesButton=_dialogYesButton;
@synthesize dialogNoButton=_dialogNoButton;
@synthesize dialogText=_dialogText;

@synthesize buttonBackgroundNormal=_buttonBackgroundNormal;
@synthesize buttonBackgroundHighlighted=_buttonBackgroundHighlighted;

@synthesize userSelection=_userSelection;

@synthesize onSelection=_onSelection;
@synthesize callerMethod=_callerMethod; 


- (id)initWithFrame:(CGRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        // Need to flip the view for proper viewing with UIKit
        self.transform = CGAffineTransformConcat(self.transform, CGAffineTransformMake(1, 0, 0, -1, 0, 0));
        
        // Rectangles for dialog components
        CGFloat ButtonWidth = frameRect.size.width/4;
        CGFloat ButtonHeight = frameRect.size.height/4;
        CGFloat oneEigth = 0.125;
        CGFloat fiveEights = 0.625;
        CGRect textRect = CGRectMake(0, 0, frameRect.size.width, frameRect.size.height/2);
        CGRect yesRect = CGRectMake(oneEigth * frameRect.size.width, fiveEights * frameRect.size.height, ButtonWidth, ButtonHeight);
        CGRect noRect = CGRectMake(fiveEights * frameRect.size.width, fiveEights * frameRect.size.height, ButtonWidth, ButtonHeight);
        
        // Font info
        UIFont *fontInfo = [UIFont fontWithName:@"Courier-Bold" size:16.0f];
        
        // Button font/background colors
        UIColor *buttonText = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.8f];
        self.buttonBackgroundNormal = [UIColor colorWithRed:0.026f green:1.0f blue:0.00121f alpha:1.0f];
        self.buttonBackgroundHighlighted = [UIColor colorWithRed:0.026f green:1.0f blue:0.00121f alpha:1.0f];

        // Text label font/background colors
        UIColor *labelText = [UIColor colorWithRed:0.026f green:1.0f blue:0.00121f alpha:1.0f];
        UIColor *labelBackground = [UIColor blackColor] ;

        // Create the text label 
        self.dialogText = [[UILabel alloc] initWithFrame:textRect];
        self.dialogText.text = @"New game?";
        self.dialogText.font = fontInfo;
        self.dialogText.textColor = labelText;
        self.dialogText.textAlignment = UITextAlignmentCenter;
        self.dialogText.backgroundColor = labelBackground;
        [self addSubview:self.dialogText];

        // Buttons are black text on a green background
        self.dialogYesButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.dialogYesButton.frame = yesRect;
        [self.dialogYesButton setTitle:@"Yes" forState:UIControlStateNormal];
        [self.dialogYesButton setTitleColor:buttonText forState:UIControlStateNormal];
        self.dialogYesButton.titleLabel.font = fontInfo;
        self.dialogYesButton.titleLabel.textColor = buttonText;
        self.dialogYesButton.backgroundColor = self.buttonBackgroundNormal;
        self.dialogYesButton.titleLabel.backgroundColor = self.buttonBackgroundNormal;
        self.dialogYesButton.titleLabel.textAlignment = UITextAlignmentCenter;
        self.dialogYesButton.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
//        self.dialogYesButton.adjustsImageWhenHighlighted = NO;
        [self addSubview:self.dialogYesButton];

        self.dialogNoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.dialogNoButton.frame = noRect;
        [self.dialogNoButton setTitle:@"No" forState:UIControlStateNormal];
        [self.dialogNoButton setTitleColor:buttonText forState:UIControlStateNormal];
        self.dialogNoButton.titleLabel.font = fontInfo;
        self.dialogNoButton.titleLabel.textColor = buttonText;
        self.dialogNoButton.backgroundColor = self.buttonBackgroundNormal;
        self.dialogNoButton.titleLabel.backgroundColor = self.buttonBackgroundNormal;
        self.dialogNoButton.titleLabel.textAlignment = UITextAlignmentCenter;
        self.dialogNoButton.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        [self addSubview:self.dialogNoButton];

        // Register the button events
        UIControlEvents TouchInsideEvents = UIControlEventTouchDown | UIControlEventTouchDragInside | UIControlEventTouchDragEnter;
        [self.dialogYesButton addTarget:self action:@selector(insideEvent:) forControlEvents:TouchInsideEvents];
        [self.dialogNoButton addTarget:self action:@selector(insideEvent:) forControlEvents:TouchInsideEvents];
        
        UIControlEvents TouchOutsideEvents = UIControlEventTouchUpOutside | UIControlEventTouchDragOutside | UIControlEventTouchDragExit;
        [self.dialogYesButton addTarget:self action:@selector(outsideEvent:) forControlEvents:TouchOutsideEvents];
        [self.dialogNoButton addTarget:self action:@selector(outsideEvent:) forControlEvents:TouchOutsideEvents];
        
        UIControlEvents SelectedEvents = UIControlEventTouchUpInside;
        [self.dialogYesButton addTarget:self action:@selector(selectedEvent:) forControlEvents:SelectedEvents];
        [self.dialogNoButton addTarget:self action:@selector(selectedEvent:) forControlEvents:SelectedEvents];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frameRect addTarget:(id)target onSelection:(SEL)sel
{
    self = [self initWithFrame:frameRect];
    if (self) {
        self.callerMethod = target;
        self.onSelection = sel;
    }
    return self;
}

- (IBAction)insideEvent:(id)sender
{
    UIButton *touched = sender;
    touched.backgroundColor = self.buttonBackgroundHighlighted;
    touched.titleLabel.backgroundColor = self.buttonBackgroundHighlighted;
}

- (IBAction)outsideEvent:(id)sender
{
    UIButton *touched = sender;
    touched.backgroundColor = self.buttonBackgroundNormal;
    touched.titleLabel.backgroundColor = self.buttonBackgroundNormal;
}

- (IBAction)selectedEvent:(id)sender
{
    UIButton *touched = sender;
    self.userSelection = (touched == self.dialogYesButton);
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.callerMethod performSelector:self.onSelection];
#pragma clang diagnostic pop
}

- (BOOL)dialogResult
{
    return self.userSelection;
}


@end