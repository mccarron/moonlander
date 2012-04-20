//
//  LanderDelegate.h
//  Moonlander
//
//  Created by Rick Naro on 4/19/12.
//  Copyright (c) 2012 Silly Goose Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LanderDelegate <NSObject>

- (short)SHOWX;
- (short)SHOWY;
- (short)AVERT;

- (short)RADARY;

- (short)PERTRS;
- (short)THRUST;
- (float)ANGLE;
- (short)ANGLED;

- (void)beep;

@end
