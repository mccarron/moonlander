//
//  VGButtom.h
//  Moonlander
//
//  Created by Silly Goose on 5/14/11.
//  Copyright 2011 Silly Goose Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VGLabel.h"

#define BrightIntensity     1.00
#define NormalIntensity     0.80

#define ButtonRepeatRate    0.5


@interface VGButton : UIControl {
    VGLabel     *_titleLabel;
    
    NSTimer     *_repeatTimer;
    float       _autoRepeatInterval;
    CGRect      _actualBounds;
    
    BOOL        _brighten;
}

@property (nonatomic, strong) VGLabel *titleLabel;

@property (nonatomic) NSTimer *repeatTimer;
@property (nonatomic) float autoRepeatInterval;
@property (nonatomic) CGRect actualBounds;

@property (nonatomic) BOOL brighten;

- (id)initWithFrame:(CGRect)frameRect;
- (id)initWithFrame:(CGRect)frameRect withPaths:(NSString *)fileName;
- (id)initWithFrame:(CGRect)frameRect withPaths:(NSString *)fileName andRepeat:(float)repeatInterval;

- (void)addPathFile:(NSString *)fileName; 

@end
