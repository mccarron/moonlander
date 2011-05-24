//
//  Instrument.h
//  Moonlander
//
//  Created by Silly Goose on 5/24/11.
//  Copyright 2011 Silly Goose Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VGButton.h"
#import "Telemetry.h"

@interface Instrument : VGButton {
    Telemetry *_instrument;
}

@property (nonatomic, retain) Telemetry *instrument;


- (id)initWithFrame:(CGRect)frameRect;

- (void)display;

@end
