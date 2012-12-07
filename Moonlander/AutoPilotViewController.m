//
//  AutoPilotViewController.m
//  Moonlander
//
//  Created by Rick Naro on 5/5/12.
//  Copyright (c) 2012 Paradigm Systems. All rights reserved.
//

#import "AutoPilotViewController.h"

@interface AutoPilotViewController ()

@end

@implementation AutoPilotViewController


#pragma -
#pragma mark Delegate
- (void)beep
{
}

- (void)explosion
{
}

- (LanderType)landerType
{
    return LanderTypeClassic;
}


#pragma -
#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Set out lander type
    self.landerType = LanderTypeClassic;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Start/restart the simulation
    [self setupTimers]; 
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)initGame:(BOOL)splash
{
    self.landerMessages.hidden = YES;
    [super initGame:NO];
}

- (void)initGame2
{
    [self.landerMessages removeAllLanderMessages];
    [self getStarted];
}

- (BOOL)canBecomeFirstResponder
{
    return NO;
}

- (void)waitNewGame
{
    [self performSelector:@selector(startGameDelay) withObject:nil afterDelay:[self getDelay:DelayNewGame]];
}

- (void)getStarted
{
    [super getStarted];
    [self performSelector:@selector(enableAutoPilot) withObject:nil afterDelay:0];
    
    // Initial instrument displays in autopilot mode
    self.instrument1.instrument = self.heightData;
    self.instrument2.instrument = self.distanceData;
    self.instrument3.instrument = self.thrustData;
    self.instrument4.instrument = self.thrustAngleData;
    [self.instrument1 display];
    [self.instrument2 display];
    [self.instrument3 display];
    [self.instrument4 display];

    // Enable instrumentation
    self.instrument1.hidden = NO;
    self.instrument2.hidden = NO;
    self.instrument3.hidden = NO;
    self.instrument4.hidden = NO;
}

@end
