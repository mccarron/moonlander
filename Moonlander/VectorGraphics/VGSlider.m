//
//  VGSlider.m
//  Moonlander
//
//  Created by Silly Goose on 5/15/11.
//  Copyright 2011 Silly Goose Software. All rights reserved.
//

#import "VGSlider.h"


@implementation VGSlider

@synthesize drawPaths=_drawPaths;
@synthesize vectorName=_vectorName;

@synthesize actualBounds=_actualBounds;

@synthesize value=_value;
@synthesize thrusterIndicator=thrusterIndicator;


- (void)setValue:(float)value
{
    _value = value;
    CGRect newFrame = CGRectMake(self.thrusterIndicator.frame.origin.x, (self.frame.size.height - (2 * self.value)) - self.thrusterIndicator.frame.size.height/2, self.thrusterIndicator.frame.size.width, self.thrusterIndicator.frame.size.height);
    [self.thrusterIndicator setFrame:newFrame];
}

- (id)initWithFrame:(CGRect)frameRect
{
    if ((self = [super initWithFrame:frameRect])) {
        self.actualBounds = CGRectMake(FLT_MAX, FLT_MAX, -FLT_MAX, -FLT_MAX);

        [self addTarget:self action:@selector(buttonDown:) forControlEvents:(UIControlEventTouchDown|UIControlEventTouchDragEnter)];
        [self addTarget:self action:@selector(buttonRepeat:) forControlEvents:(UIControlEventTouchDownRepeat|UIControlEventTouchDragInside)];
        [self addTarget:self action:@selector(buttonUp:) forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel|UIControlEventTouchDragExit|UIControlEventTouchDragOutside)];

        // Thruster indicator
        NSString *tiPath = [[NSBundle mainBundle] pathForResource:@"ThrusterNeedle" ofType:@"plist"];
        //NSLog(@"self: [%3.0f,%3.0f] and [%3.0f,%3.0f]", self.frame.origin.x, self.frame.origin.y, self.frame.origin.y, self.frame.size.height);
        CGRect needleFrameRect = CGRectMake(100, 0/*self.frame.size.height - (self.frame.size.height * self.value*/, 75, 10);
        //NSLog(@"newFraemrect: [%3.0f,%3.0f] and [%3.0f,%3.0f]", needleFrameRect.origin.x, needleFrameRect.origin.y, needleFrameRect.size.width, needleFrameRect.size.height);
        self.thrusterIndicator = [[[VGView alloc] initWithFrame:needleFrameRect withPaths:tiPath] retain];
        self.thrusterIndicator.userInteractionEnabled = NO;
        [self addSubview:self.thrusterIndicator];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frameRect withPaths:(NSString *)fileName
{
    self = [self initWithFrame:frameRect];
    
    NSDictionary *viewObject = [NSDictionary dictionaryWithContentsOfFile:fileName];
    self.vectorName = [viewObject objectForKey:@"name"];
    self.drawPaths = [viewObject objectForKey:@"paths"];
    return self;
}

- (void)dealloc
{
    [_drawPaths release];
    //[_thrusterIndicator release];
    [super dealloc];
}

- (void)addPathFile:(NSString *)fileName
{
    NSDictionary *viewObject = [NSDictionary dictionaryWithContentsOfFile:fileName];
    self.vectorName = [viewObject objectForKey:@"name"];
    self.drawPaths = [viewObject objectForKey:@"paths"];
}

- (void)drawRect:(CGRect)rect
{
	CGPoint prevPoint = CGPointMake(0.0f, 0.0f);
    
	CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetShouldAntialias (context, YES);
    CGContextSetAllowsAntialiasing(context, YES);
    
    NSEnumerator *pathEnumerator = [self.drawPaths objectEnumerator];
    NSArray *currentPath;
    while ((currentPath = [pathEnumerator nextObject])) {
        NSEnumerator *vectorEnumerator = [currentPath objectEnumerator];
        NSDictionary *currentVector;
        while ((currentVector = [vectorEnumerator nextObject])) {
            // Choices are "moveto", "color", "line", "x", "y", "center"
            if ([currentVector objectForKey:@"stop"]) {
                BOOL stopCommand = [[currentVector objectForKey:@"stop"] boolValue];
                if (stopCommand) break;
            }
            
            if ([currentVector objectForKey:@"break"]) {
                BOOL breakCommand = [[currentVector objectForKey:@"break"] boolValue];
                if (breakCommand) {
                    NSLog(@"Set breakpoint point here");;
                }
            }
            
            // Move to a point
            if ([currentVector objectForKey:@"moveto"]) {
                NSDictionary *moveTo = [currentVector objectForKey:@"moveto"];
                if ([moveTo objectForKey:@"center"]) {
                    // Centering uses the view bounds and is not scaled
                    CGPoint midPoint = CGPointMake(self.bounds.origin.x + self.bounds.size.width / 2, self.bounds.origin.y + self.bounds.size.height / 2);
                    CGContextMoveToPoint(context, midPoint.x, midPoint.y);
                    //NSLog(@"Move (%3.0f,%3.0f)", midPoint.x, midPoint.y);
                    prevPoint = midPoint;
                    //CGContextStrokePath(context);
                }
                else if ([moveTo objectForKey:@"x"]) {
                    // Moving to a point in the view requires scaling
                    CGFloat x = [[moveTo objectForKey:@"x"] floatValue];
                    CGFloat y = [[moveTo objectForKey:@"y"] floatValue];
                    CGPoint newPoint = CGPointMake(x, y);
                    // ### Scaling here
                    CGContextMoveToPoint(context, newPoint.x, newPoint.y);
                    
                    //NSLog(@"Move To (%3.0f,%3.0f)", newPoint.x, newPoint.y);
                    prevPoint = newPoint;
                    self.actualBounds = CGRectMake(MIN(newPoint.x, self.actualBounds.origin.x), MIN(newPoint.y, self.actualBounds.origin.y), MAX(newPoint.x, self.actualBounds.size.width), MAX(newPoint.y, self.actualBounds.size.height));
                }
            }
            
            // Move to a point relative to the current position
            if ([currentVector objectForKey:@"moverel"]) {
                NSDictionary *moveRelative = [currentVector objectForKey:@"moverel"];
                if ([moveRelative objectForKey:@"x"]) {
                    // Moving to a point in the view requires scaling
                    CGFloat x = [[moveRelative objectForKey:@"x"] floatValue];
                    CGFloat y = [[moveRelative objectForKey:@"y"] floatValue];
                    CGPoint newPoint = CGPointMake(prevPoint.x + x, prevPoint.y + y);
                    // ### Scaling here
                    CGContextMoveToPoint(context, newPoint.x, newPoint.y);
                    
                    //NSLog(@"Move Relative (%3.0f,%3.0f)", newPoint.x, newPoint.y);
                    prevPoint = newPoint;
                    self.actualBounds = CGRectMake(MIN(newPoint.x, self.actualBounds.origin.x), MIN(newPoint.y, self.actualBounds.origin.y), MAX(newPoint.x, self.actualBounds.size.width), MAX(newPoint.y, self.actualBounds.size.height));
                }
            }
            
            // Process color stuff
            if ([currentVector objectForKey:@"color"]) {
                NSDictionary *colorStuff = [currentVector objectForKey:@"color"];
                CGFloat r = [[colorStuff objectForKey:@"r"] floatValue];
                CGFloat g = [[colorStuff objectForKey:@"g"] floatValue];
                CGFloat b = [[colorStuff objectForKey:@"b"] floatValue];
                CGFloat alpha = [[colorStuff objectForKey:@"alpha"] floatValue];
                CGContextStrokePath(context);
                CGContextSetRGBStrokeColor(context, r, g, b, alpha);
                CGContextMoveToPoint(context, prevPoint.x, prevPoint.y);
            }
            
            // Process line stuff
            if ([currentVector objectForKey:@"line"]) {
                if ([currentVector objectForKey:@"line"]) {
                    NSDictionary *lineStuff = [currentVector objectForKey:@"line"];
                    if ([lineStuff objectForKey:@"width"]) {
                        CGFloat width = [[lineStuff objectForKey:@"width"] floatValue];
                        CGContextStrokePath(context);
                        CGContextSetLineWidth(context, width);
                        CGContextMoveToPoint(context, prevPoint.x, prevPoint.y);
                    }
                }
            }
            
            // Process a new path segment
            if ([currentVector objectForKey:@"x"]) {
                CGFloat x = [[currentVector objectForKey:@"x"] floatValue];
                CGFloat y = [[currentVector objectForKey:@"y"] floatValue];
                CGPoint newPoint = CGPointMake(prevPoint.x + x, prevPoint.y + y);
                
                // ### Scaling here
                CGContextAddLineToPoint(context, newPoint.x, newPoint.y);
                
                //NSLog(@"Draw from %-3.0f,%-3.0f to %-3.0f,%-3.0f", prevPoint.x, prevPoint.y, newPoint.x, newPoint.y);
                prevPoint = newPoint;
                self.actualBounds = CGRectMake(MIN(newPoint.x, self.actualBounds.origin.x), MIN(newPoint.y, self.actualBounds.origin.y), MAX(newPoint.x, self.actualBounds.size.width), MAX(newPoint.y, self.actualBounds.size.height));
            }
        }
    }
    CGContextStrokePath(context);
    NSLog(@"Max coordinates for %@: %@", self.vectorName, NSStringFromCGRect(self.actualBounds));
}

#pragma mark Touch tracking

// If views are directly on top of each other, they move together.
-(void)dispatchTouchEvent:(UIView *)theView toPosition:(CGPoint)position
{
    //NSLog(@"dispatchTouchEvent: (%f,%f)", position.x, position.y);
    self.value = 100.0f - position.y / theView.bounds.size.height * 100.0f;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)touchesBegan:(NSSet*)touches  withEvent:(UIEvent*)event
{
    for (UITouch *touch in touches) {
        if ([self pointInside:[touch locationInView:self] withEvent:event]) {
            [self dispatchTouchEvent:[touch view] toPosition:[touch locationInView:self]];
        }
	}	
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    for (UITouch *touch in touches) {
        if ([self pointInside:[touch locationInView:self] withEvent:event]) {
            [self dispatchTouchEvent:[touch view] toPosition:[touch locationInView:self]];
        }
	}	
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    for (UITouch *touch in touches) {
        if ([self pointInside:[touch locationInView:self] withEvent:event]) {
            [self dispatchTouchEvent:[touch view] toPosition:[touch locationInView:self]];
        }
	}	
}

@end
