//
//  Instrument.m
//  Moonlander
//
//  Created by Rick on 5/24/11.
//  Copyright 2012 Rick Naro. All rights reserved.
//

#import "Instrument.h"


@implementation Instrument

@synthesize instrument=_instrument;


- (id)initWithFrame:(CGRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        // Default for instruments is intensity 6 and hidden
        self.titleLabel.intensity = 6;
        self.hidden = YES;
#ifdef DEBUG
        self.titleLabel.vectorName = @"instrument";
#endif
    }
    return self;
}

- (void)display
{
    NSString *format = self.instrument.format;
    NSString *title = self.instrument.name;
    short datum = self.instrument.data();
    NSString *instrumentText = [NSString stringWithFormat:format, datum, title];
    self.titleLabel.text = instrumentText;
}

@end
