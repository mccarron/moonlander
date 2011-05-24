//
//  VGView.m
//  Moonlander
//
//  Created by Silly Goose on 5/14/11.
//  Copyright 2011 Silly Goose Software. All rights reserved.
//

#import "VGView.h"


@implementation VGView

@synthesize drawPaths=_drawPaths;
@synthesize vectorName=_vectorName;
@synthesize actualBounds=_actualBounds;
@synthesize blinkTimer=_blinkTimer;
@synthesize blinkOn=_blinkOn;
@synthesize fontSize=_fontSize;


- (id)initWithFrame:(CGRect)frameRect
{
    if ((self = [super initWithFrame:frameRect])) {
        self.fontSize = 11;
        self.opaque = NO;
        
        self.actualBounds = CGRectMake(FLT_MAX, FLT_MAX, -FLT_MAX, -FLT_MAX);
        self.vectorName = @"[VGView initWithFrame]";
    }
    return self;
}

- (id)initWithFrame:(CGRect)frameRect withPaths:(NSString *)fileName
{
    self = [self initWithFrame:frameRect];

    NSDictionary *viewObject = [NSDictionary dictionaryWithContentsOfFile:fileName];
    if (!(self.vectorName = [viewObject objectForKey:@"name"]))
        self.vectorName = @"[VGView initWithFrame:withPaths:]";
    self.drawPaths = [viewObject objectForKey:@"paths"];
    return self;
}

- (void)dealloc
{
    [_blinkTimer invalidate];
    [_blinkTimer release];
    [_drawPaths release];
    [_vectorName release];

    [super dealloc];
}

- (void)blinkIntervalPassed:(NSTimer *)timer
{
    self.blinkOn = !self.blinkOn;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    //NSLog(@"UIView:drawRect%@", NSStringFromCGRect(rect));
    
    CGPoint currentPosition = CGPointMake(0.0f, self.bounds.size.height - self.fontSize);
    CGPoint prevPoint = CGPointZero;
    
	CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetShouldAntialias(context, YES);
    CGContextSetAllowsAntialiasing(context, YES);

    CGFontRef fontRef = CGFontCreateWithFontName((CFStringRef)@"Courier");
    CGContextSetFont(context, fontRef);
    CGContextSetFontSize(context, self.fontSize);
    
    CGContextSetRGBFillColor(context, 0.026f, 1.0f, 0.00121f, 1.0f);
    CGContextSetRGBStrokeColor(context, 0.026f, 1.0f, 0.00121f, 1.0f);
    CGContextSetTextDrawingMode(context, kCGTextFillStroke);
    CGContextSetShouldSmoothFonts(context, YES);
    
    NSEnumerator *pathEnumerator = [self.drawPaths objectEnumerator];
    NSArray *currentPath;
    while ((currentPath = [pathEnumerator nextObject])) {
        NSEnumerator *vectorEnumerator = [currentPath objectEnumerator];
        NSDictionary *currentVector;
        while ((currentVector = [vectorEnumerator nextObject])) {
            BOOL doBlink = NO;//### make instance variable?
            
            // "break" allows for complex breakpoints in a display list
            if ([currentVector objectForKey:@"break"]) {
                BOOL breakCommand = [[currentVector objectForKey:@"break"] boolValue];
                if (breakCommand) {
                    raise(SIGTRAP);
                }
            }
            
            // "stop' allows early termination of a display list
            if ([currentVector objectForKey:@"stop"]) {
                BOOL stopCommand = [[currentVector objectForKey:@"stop"] boolValue];
                if (stopCommand) break;
            }
            
            // "color" is used to set the current color
            if ([currentVector objectForKey:@"color"]) {
                NSDictionary *colorStuff = [currentVector objectForKey:@"color"];
                CGFloat r = [[colorStuff objectForKey:@"r"] floatValue];
                CGFloat g = [[colorStuff objectForKey:@"g"] floatValue];
                CGFloat b = [[colorStuff objectForKey:@"b"] floatValue];
                CGFloat alpha = [[colorStuff objectForKey:@"alpha"] floatValue];
                CGContextStrokePath(context);
                CGContextSetRGBStrokeColor(context, r, g, b, alpha);
                CGContextSetRGBFillColor(context, r, g, b, alpha);
                CGContextMoveToPoint(context, prevPoint.x, prevPoint.y);
            }
            
            // "textmode" is used to set the text drawing mode
            if ([currentVector objectForKey:@"mode"]) {
                int textMode = [[currentVector objectForKey:@"mode"] intValue];
                CGContextSetTextDrawingMode(context, textMode);
            }
            
            // "font" is used to set the current font and size
            if ([currentVector objectForKey:@"font"]) {
                NSDictionary *fontStuff = [currentVector objectForKey:@"font"];
                if ([fontStuff objectForKey:@"size"]) {
                    self.fontSize = [[fontStuff objectForKey:@"size"] floatValue];
                    CGContextSetFontSize(context, self.fontSize);
                }
                if ([fontStuff objectForKey:@"name"]) {
                    NSString *fontName = [fontStuff objectForKey:@"name"];
                    CGFontRelease(fontRef);
                    fontRef = CGFontCreateWithFontName((CFStringRef)fontName);
                    CGContextSetFont(context, fontRef);
                }
            }
            
            // "newline" is used to move the drawing position to the next line
            if ([currentVector objectForKey:@"newline"]) {
                CGFloat nLines = [[currentVector objectForKey:@"newline"] floatValue];
                currentPosition.x = 0.0f;
                currentPosition.y = currentPosition.y - (nLines * self.fontSize);
            }
            
            // "blink" is used to blink the text
            if ([currentVector objectForKey:@"blink"]) {
                doBlink = [[currentVector objectForKey:@"blink"] boolValue];
                if (doBlink && !self.blinkTimer) {
                    self.blinkTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(blinkIntervalPassed:) userInfo:nil repeats:YES];
                }
            }
            
            // "moveto" is used to a move to a point in the current rect
            if ([currentVector objectForKey:@"moveto"]) {
                NSDictionary *moveTo = [currentVector objectForKey:@"moveto"];
                if ([moveTo objectForKey:@"center"]) {
                    // Centering uses the view bounds and is not scaled
                    CGPoint midPoint = CGPointMake(self.bounds.origin.x + self.bounds.size.width / 2, self.bounds.origin.y + self.bounds.size.height / 2);
                    CGContextMoveToPoint(context, midPoint.x, midPoint.y);
                    prevPoint = midPoint;
                }
                else if ([moveTo objectForKey:@"x"]) {
                    // Moving to a point in the view requires scaling
                    CGFloat x = [[moveTo objectForKey:@"x"] floatValue];
                    CGFloat y = [[moveTo objectForKey:@"y"] floatValue];
                    CGPoint newPoint = CGPointMake(x, y);
                    
                    // ### Scaling here
                    CGContextMoveToPoint(context, newPoint.x, newPoint.y);
                    
                    //NSLog(@"Move To (%3.0f,%3.0f)", newPoint.x, newPoint.y);
                    //prevPoint = newPoint;
                    prevPoint = CGContextGetPathCurrentPoint(context);
                    self.actualBounds = CGRectMake(MIN(newPoint.x, self.actualBounds.origin.x), MIN(newPoint.y, self.actualBounds.origin.y), MAX(newPoint.x, self.actualBounds.size.width), MAX(newPoint.y, self.actualBounds.size.height));
                }
            }
            
            // "moverel" is used to move to a point relative to the current position
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
                    //prevPoint = newPoint;
                    prevPoint = CGContextGetPathCurrentPoint(context);
                    self.actualBounds = CGRectMake(MIN(newPoint.x, self.actualBounds.origin.x), MIN(newPoint.y, self.actualBounds.origin.y), MAX(newPoint.x, self.actualBounds.size.width), MAX(newPoint.y, self.actualBounds.size.height));
                }
            }
            
            // "line" is used to set the line information
            if ([currentVector objectForKey:@"line"]) {
                NSDictionary *lineStuff = [currentVector objectForKey:@"line"];
                if ([lineStuff objectForKey:@"width"]) {
                    CGFloat width = [[lineStuff objectForKey:@"width"] floatValue];
                    CGContextStrokePath(context);
                    CGContextSetLineWidth(context, width);
                    CGContextMoveToPoint(context, prevPoint.x, prevPoint.y);
                }
                if ([lineStuff objectForKey:@"type"]) {
                    int type = [[lineStuff objectForKey:@"type"] intValue];
                    CGFloat phase = 0;
                    size_t count = 0;
                    const CGFloat *lengths;
                    const CGFloat LongDash[] = {6.0f, 2.0f};
                    const CGFloat ShortDash[] = {3.0f, 1.0f};
                    const CGFloat DotDash[] = {3.0f, 1.0f, 6.0f, 1.0f};
                    CGContextStrokePath(context);
                    switch (type) {
                        case 1:
                            lengths = LongDash;
                            count = sizeof(LongDash)/sizeof(LongDash[0]);
                            break;
                        case 2:
                            lengths = ShortDash;
                            count = sizeof(ShortDash)/sizeof(ShortDash[0]);
                            break;
                        case 3:
                            lengths = DotDash;
                            count = sizeof(DotDash)/sizeof(DotDash[0]);
                            break;
                    }
                    CGContextSetLineDash(context, phase, lengths, count);
                    CGContextMoveToPoint(context, prevPoint.x, prevPoint.y);
                }
            }
            
            // Process a text command
            if ([currentVector objectForKey:@"text"]) {
                CGContextTranslateCTM(context, 0, self.bounds.size.height);
                CGContextScaleCTM(context, 1.0, -1.0 );
                
                NSString *msg = [currentVector objectForKey:@"text"];
                
                // Prepare characters for printing
                NSString *theText = [NSString stringWithString:msg];
                int length = [theText length];
                unichar chars[length];
                CGGlyph glyphs[length];
                [theText getCharacters:chars range:NSMakeRange(0, length)];
                
                // Loop through the entire length of the text.
                int glyphOffset = -29;
                for (int i = 0; i < length; ++i) {
                    // Store each letter in a Glyph and subtract the MagicNumber to get appropriate value.
                    glyphs[i] = [theText characterAtIndex:i] + glyphOffset;
                }
                
                // We do this only if blinking is requested
                if (doBlink) {
                    if (self.blinkOn) {
                        // Draw normally this cycle
                        CGContextShowGlyphsAtPoint(context, currentPosition.x, currentPosition.y, glyphs, length);
                    }
                    else {
                        // Change alpha to zero for this draw cycle and then restore
                        CGContextSaveGState(context);
                        CGContextSetAlpha(context, 0.0f);
                        CGContextShowGlyphsAtPoint(context, currentPosition.x, currentPosition.y, glyphs, length);
                        CGContextRestoreGState(context);
                    }
                }
                else {
                    CGContextShowGlyphsAtPoint(context, currentPosition.x, currentPosition.y, glyphs, length);
                }
                //NSLog(@"Drawing text at %@", NSStringFromCGPoint(currentPosition));
                
                // Set our new position for the next text block
                currentPosition = CGContextGetTextPosition(context);

                // Restore our normal drawing translation
                CGContextTranslateCTM(context, 0, self.bounds.size.height);
                CGContextScaleCTM(context, 1.0, -1.0 );
            }
            
            // "x" and "y" specify a new point on the path
            if ([currentVector objectForKey:@"x"]) {
                CGFloat x = [[currentVector objectForKey:@"x"] floatValue];
                CGFloat y = [[currentVector objectForKey:@"y"] floatValue];
                CGPoint newPoint = CGPointMake(prevPoint.x + x, prevPoint.y + y);
                
                // ### Scaling here
                CGContextAddLineToPoint(context, newPoint.x, newPoint.y);
                
                //prevPoint = newPoint;
                prevPoint = CGContextGetPathCurrentPoint(context);
                self.actualBounds = CGRectMake(MIN(newPoint.x, self.actualBounds.origin.x), MIN(newPoint.y, self.actualBounds.origin.y), MAX(newPoint.x, self.actualBounds.size.width), MAX(newPoint.y, self.actualBounds.size.height));
            }
        }
    }
    CGContextStrokePath(context);
    CGFontRelease(fontRef);
//    NSLog(@"Max coordinates for %@: %@", self.vectorName, NSStringFromCGRect(self.actualBounds));
}

@end
