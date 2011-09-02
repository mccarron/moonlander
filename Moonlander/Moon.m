//
//  Moon.m
//  Moonlander
//
//  Created by Rick on 5/26/11.
//  Copyright 2011 Silly Goose Software. All rights reserved.
//

#import "Moon.h"


@implementation Moon

@synthesize moonArray=_moonArray;
@synthesize dirtySurface=_dirtySurface;

@synthesize currentView=_currentView;
@synthesize LEFTEDGE=_LEFTEDGE;

@synthesize dataSource=_dataSource;


- (id)initWithFrame:(CGRect)moonRect
{
    self = [super initWithFrame:moonRect];
    if (self) {
        self.LEFTEDGE = -1.0;
        
        // No events for the moon surface
        self.userInteractionEnabled = NO;
        
        NSString *moonPath = [[NSBundle mainBundle] pathForResource:@"Moon" ofType:@"plist"];
        NSMutableDictionary *moonDict = [NSMutableDictionary dictionaryWithContentsOfFile:moonPath];
        self.vectorName = @"[Moon init]";

        // We need to change the coordinate space to (0,0) in the lower left
        self.transform = CGAffineTransformMake(1, 0, 0, -1, 0, 0);
        
        // Cache the lunar terrain data
        self.moonArray = [[[NSMutableArray arrayWithObject:[moonDict objectForKey:@"paths"]] objectAtIndex:0] objectAtIndex:0];
    }
    return self;
}

- (short)terrainHeight:(short)index
{
    short terrainHeight = 0;
    short ti = index + 10;
    if (ti >= 0 && ti < self.moonArray.count) {
        terrainHeight = [[[self.moonArray objectAtIndex:ti] objectForKey:@"y"] intValue];
    }
    return terrainHeight;
}

- (short)averageTerrainHeight:(short)index
{
    short leftHeight = [self terrainHeight:index];
    short rightHeight = [self terrainHeight:index+1];
    short averageHeight = (leftHeight + rightHeight) / 2;
    return averageHeight;
}

- (void)setTerrainHeight:(short)height atIndex:(short)index
{
    short ti = index + 10;
    if (ti >= 0 && ti < self.moonArray.count) {
        NSMutableDictionary *item = [self.moonArray objectAtIndex:ti];
        if (item) {
            NSNumber *newHeight = [NSNumber numberWithInt:height];
            [item setObject:newHeight forKey:@"y"];
            [self.moonArray replaceObjectAtIndex:ti withObject:item];
        }
    }
}

- (void)modifyTerrainHeight:(short)deltaHeight atIndex:(short)index
{
    short oldHeight = [self terrainHeight:index];
    oldHeight -= deltaHeight;
    [self setTerrainHeight:oldHeight atIndex:index];
    self.dirtySurface = YES;
}

- (TerrainFeature)featureAtIndex:(short)index
{
    TerrainFeature tf = TF_Nothing;
    index += 10;
    NSNumber *feature = [[self.moonArray objectAtIndex:index] objectForKey:@"feature"
     ];
    if (feature) {
        tf = [feature intValue];
    }
    return tf;
}

- (BOOL)hasFeature:(TerrainFeature)feature atIndex:(short)index
{
    BOOL hasFeature = NO;
    index += 10;
    if (index >= 0 && index < self.moonArray.count) {
        hasFeature = ([[self.moonArray objectAtIndex:index] objectForKey:@"feature"
                       ] != nil);
    }
    return hasFeature;
}

- (void)addFeature:(TerrainFeature)feature atIndex:(short)index
{
    index = index + 10;
    if (index >= 0 && index < self.moonArray.count) {
        NSMutableDictionary *item = [self.moonArray objectAtIndex:index];
        if (item) {
            TerrainFeature tf = [[item objectForKey:@"feature"] intValue];
            if (tf != TF_Rock) {
                NSNumber *newFeature = [NSNumber numberWithInt:feature];
                [item setObject:newFeature forKey:@"feature"];
                //### need this?
                [self.moonArray replaceObjectAtIndex:index withObject:item];
                self.dirtySurface = YES;
            }
        }
    }
}

- (void)removeFeature:(TerrainFeature)feature atIndex:(short)index
{
    index += 10;
    if (index >= 0 && index < self.moonArray.count) {
        NSMutableDictionary *terrainFeature = [self.moonArray objectAtIndex:index];
        TerrainFeature tf = [[terrainFeature objectForKey:@"feature"] intValue];
        if (tf != TF_Rock) {
            [terrainFeature removeObjectForKey:@"feature"];
        }
    }
}

- (void)alterMoon:(short)alterChange atIndex:(short)terrainIndex
{
    //ALTER
    TerrainFeature oldShip = TF_OldLanderTippedLeft;
    short leftIndex = terrainIndex;
    short rightIndex = terrainIndex + 1;
    short leftElevation = [self terrainHeight:leftIndex];
    short rightElevation = [self terrainHeight:rightIndex];
    if ((rightElevation - leftElevation) >= 0) {
        oldShip = TF_OldLanderTippedRight;
    }
    
    //ALTERP
    [self addFeature:oldShip atIndex:leftIndex];
    
    //ALTERL
    while (alterChange) {
        [self modifyTerrainHeight:alterChange atIndex:leftIndex];
        [self modifyTerrainHeight:alterChange atIndex:rightIndex];
        leftIndex--;
        rightIndex++;
        
        // Alter out till done
        alterChange /= 2;
        alterChange = -alterChange;
    }
}

- (short)DFAKE:(short)yValue
{
    short y = yValue;
    y = (y * 3) / 8 + 23;
    return y;
}

- (void)DRAWIC
{
}

- (void)addFeatureToView:(TerrainFeature)tf atOrigin:(CGPoint)point
{
    const char *featureFiles[] = { NULL, "Lander2", "Flag", "Lander2", "Lander2", "Rock", NULL, "McDonalds" };
    const CGSize featureSizes[] = { CGSizeMake(0, 0), CGSizeMake(72, 64), CGSizeMake(22, 22), CGSizeMake(72, 64), CGSizeMake(72, 64), CGSizeMake(48, 42), CGSizeMake(0, 0), CGSizeMake(140, 64) };
    CGFloat featureRotation[] = { 0.0f, 0.0f, 0.0f, M_PI_2, -M_PI_2, 0.0f, 0.0f, 0.0f };
    CGFloat featureTranslation[] = { 0.0f, 0.0f, 0.0f, -1.0f, 0.0f, 0.0f, 0.0f, 0.0f };
    CGFloat verticalAdjust[] = { 0.0f, 48.0f, 0.0f, 32.0f, 32.0f, 32.0f, 0.0f, 50.0f };
    CGFloat verticalClip[] = { 0.0f, 0.0f, 0.0f, 30.0f, 30.0f, 0.0f, 0.0f, 0.0f };

    if (!(tf == TF_Nothing || tf == TF_McDonaldsEdge)) {
        float angleAdjust = 0;
        if (tf == TF_OldLanderTippedLeft || tf == TF_OldLanderTippedRight) {
            short leftHeight = [self DFAKE:[self terrainHeight:self.LEFTEDGE]];
            short rightHeight = [self DFAKE:[self terrainHeight:(self.LEFTEDGE+1)]];
            short averageHeight = (leftHeight + rightHeight) / 2;
            point.y = averageHeight;
            if (leftHeight - rightHeight) {
                angleAdjust = (leftHeight - rightHeight) ? (M_PI_4 / 2) : (-M_PI_4 / 2);
            }
        }
        
        CGRect frameRect;
        frameRect.origin = point;
        frameRect.size = featureSizes[tf];
        frameRect.origin.y += verticalAdjust[tf];
        frameRect.origin.y = frameRect.origin.y - frameRect.size.height;
        
        //NSLog(@"Feature %d at %@", tf, NSStringFromCGPoint(point));
        NSString *featureFile = [[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:featureFiles[tf]] ofType:@"plist"];
        VGView *featureView = [[VGView alloc] initWithFrame:frameRect withPaths:featureFile];
        
        featureView.clipsToBounds = YES;
        //featureView.backgroundColor = [UIColor grayColor];
        CGRect clipped = CGRectMake(featureView.bounds.origin.x, featureView.bounds.origin.y, featureView.bounds.size.width - verticalClip[tf], featureView.bounds.size.height);
        featureView.bounds = clipped;

        if (featureRotation[tf]) {
            // Add the rotation to the subview
            CGAffineTransform t = featureView.transform;
            t = CGAffineTransformRotate(t, featureRotation[tf] + angleAdjust);
            featureView.transform = t;
        }

        if (featureTranslation[tf]) {
            // Add the rotation to the subview
            CGAffineTransform t = featureView.transform;
            t = CGAffineTransformScale(t, featureTranslation[tf], 1.0f);
            featureView.transform = t;
        }

        [self addSubview:featureView];
        [featureView release];
    }
}

- (NSArray *)buildDetailedLunarSurface
{
    // This is the display index
    short x = 0;
    
    // Start building the draw path now
    NSMutableArray *path = [[[NSMutableArray alloc] init] autorelease];
    NSArray *paths = [NSArray arrayWithObject:path];
    
    // Intensity and line type variables
    int DRAWTY = 0;
    int DRAWTZ = 0;
    unsigned DTYPE = 0;
    unsigned DINT = 0;
    const int nextIndex = 1;
    const int terrainIndex = self.LEFTEDGE;
    //NSLog(@"Initial X is %d", terrainIndex);
    
    short TEMP = [self terrainHeight:terrainIndex];
    TEMP = [self DFAKE:TEMP];
    if (TEMP < 0)
        TEMP = 0;
    else if (TEMP > 768)
        TEMP = 768;
    short LASTY = TEMP;

    //NSLog(@"x: %d  TEMP: %d", x, TEMP);
    NSNumber *xCoordinate = [NSNumber numberWithInt:x];
    NSNumber *yCoordinate = [NSNumber numberWithInt:TEMP];
    NSDictionary *startItem = [NSDictionary dictionaryWithObjectsAndKeys:xCoordinate, @"x", yCoordinate, @"y", nil];
    NSDictionary *moveToStartItem = [NSDictionary dictionaryWithObjectsAndKeys:startItem, @"moveto", nil];
    [path addObject:moveToStartItem];
    
    int DFUDGE = 0;
    int DFUDGE_INC = 1;
    unsigned lineSegments = 0;
    for (short i = terrainIndex; lineSegments < 225; i += nextIndex) {
        short IN2 = [self terrainHeight:i];
        IN2 = [self DFAKE:IN2];
        IN2 = IN2 - TEMP;
        if (IN2 < 0) {
            IN2 -= 6;
            IN2 = -IN2;
            IN2 /= 12;
            IN2 = -IN2;
        }
        else {
            IN2 += 6;
            IN2 /= 12;
        }
        
        int k = 12;
        while (k-- > 0) {
            DFUDGE += DFUDGE_INC;
            if (DFUDGE == 3) {
                DFUDGE_INC = -1;
            }
            else if (DFUDGE == -3) {
                DFUDGE_INC = 1;
            }
            
            // Intensity/line type update
            if (--DRAWTY < 0) {
                DRAWTZ++;
                DRAWTZ &= 3;
                DRAWTZ++;
                DRAWTY = DRAWTZ;
                DINT = (DINT + 5) % 8;
                DTYPE = (DTYPE + 1) % 4;
                
                // Add line type and intensity
                NSDictionary *lineType = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:DTYPE], @"type", [NSNumber numberWithFloat:2.0f], @"width", nil];
                NSDictionary *line = [NSDictionary dictionaryWithObjectsAndKeys:lineType, @"line", nil];
                NSDictionary *intensity = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:DINT], @"intensity", nil];
                [path addObject:line];
                [path addObject:intensity];
            }
            
            TEMP = TEMP + DFUDGE;
            TEMP = TEMP + IN2;
            
            float S_TEMP = TEMP;
            TEMP = TEMP - LASTY;
            LASTY += TEMP;
            
            x += 4;
            
            //NSLog(@"TEMP: %d", TEMP);
            xCoordinate = [NSNumber numberWithInt:4];
            yCoordinate = [NSNumber numberWithInt:TEMP];
            NSMutableDictionary *drawItem = [NSDictionary dictionaryWithObjectsAndKeys:xCoordinate, @"x", yCoordinate, @"y", nil];
            [path addObject:drawItem];
            
            TEMP = S_TEMP;
            lineSegments++;
            
            //NSLog(@"i: %d  lineSeg: %d  TEMP: %3.0f  IN2: %3.0f  LASTY: %3.0f  drawTo: %@", i, lineSegments, TEMP, IN2, LASTY, NSStringFromCGPoint(drawToPoint));
          
            // See if there are features to add (added to center of terrain index)
            if (k == 11) {
                TerrainFeature tf = [self featureAtIndex:i];
                if (tf > TF_Nothing && tf != TF_McDonaldsEdge) {
                    [self addFeatureToView:tf atOrigin:CGPointMake(x, TEMP)];
                }
            }
        }
    }
    return paths;
}

- (NSArray *)buildLunarSurface
{
    // Start building the draw path now
    NSMutableArray *path = [[[NSMutableArray alloc] init] autorelease];
    NSArray *paths = [NSArray arrayWithObject:path];
    
    // Intensity and line type variables
    int DRAWTY = 0;
    int DRAWTZ = 0;
    unsigned DTYPE = 0;
    unsigned DINT = 0;
    const int nextIndex = 4;
    const int firstIndex = 10;
    const int secondIndex = firstIndex + nextIndex;
    
    // Should be X = 0 in the array
    CGPoint previousPoint = CGPointMake(0, 0);
    NSDictionary *item = [self.moonArray objectAtIndex:firstIndex];
    
    short x = [[item objectForKey:@"x"] intValue];
    short y = [[item objectForKey:@"y"] intValue];
    y = y / 32 + 23;

    previousPoint.x = x;
    previousPoint.y = y;
    
    NSNumber *xCoordinate = [NSNumber numberWithFloat:x];
    NSNumber *yCoordinate = [NSNumber numberWithFloat:y];
    NSDictionary *startItem = [NSDictionary dictionaryWithObjectsAndKeys:xCoordinate, @"x", yCoordinate, @"y", nil];
    NSDictionary *moveToStartItem = [NSDictionary dictionaryWithObjectsAndKeys:startItem, @"moveto", nil];
    [path addObject:moveToStartItem];
    
    for (int i = secondIndex; i < self.moonArray.count; i += nextIndex) {
        x = [[[self.moonArray objectAtIndex:i] objectForKey:@"x"] intValue];
        y = [[[self.moonArray objectAtIndex:i] objectForKey:@"y"] intValue];
        short scaledY = y / 32 + 23;
        
        // Intensity/line type update
        DRAWTY--;
        if (DRAWTY < 0) {
            DRAWTZ++;
            DRAWTZ &= 3;
            DRAWTZ++;
            DRAWTY = DRAWTZ;
            DINT = (DINT + 5) % 8;
            DTYPE = (DTYPE + 1) % 4;
            
            // Add line type and intensity
            NSDictionary *lineType = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:DTYPE], @"type", [NSNumber numberWithFloat:2.0f], @"width", nil];
            NSDictionary *line = [NSDictionary dictionaryWithObjectsAndKeys:lineType, @"line", nil];
            NSDictionary *intensity = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:DINT], @"intensity", nil];
            [path addObject:line];
            [path addObject:intensity];
            //NSLog(@"X: %f   Intensity: %d    Line type: %d", x, DINT, DTYPE);
        }
        
        CGPoint drawToPoint = CGPointMake(x - previousPoint.x, scaledY - previousPoint.y);
        xCoordinate = [NSNumber numberWithInt:drawToPoint.x];
        yCoordinate = [NSNumber numberWithInt:drawToPoint.y];
        NSMutableDictionary *drawItem = [NSDictionary dictionaryWithObjectsAndKeys:xCoordinate, @"x", yCoordinate, @"y", nil];
        [path addObject:drawItem];
        
        //NSLog(@"%d  %3.0f  %3.0f  %3.0f %@", i, x, y, scaledY, NSStringFromCGPoint(drawToPoint));
        previousPoint.x = x;
        previousPoint.y = scaledY;
    }
    return paths;
}

- (void)useCloseUpView:(short)xCoordinate
{
    if ((self.currentView == TV_Normal) || (self.currentView == TV_Detailed && self.LEFTEDGE != xCoordinate) || self.dirtySurface) {
        // Remove the subviews whenever we change
        for (UIView *subView in [self subviews]) {
            [subView removeFromSuperview];
        }
        
        self.currentView = TV_Detailed;
        self.LEFTEDGE = xCoordinate;
        self.drawPaths = [self buildDetailedLunarSurface];
        self.dirtySurface = NO;
        [self setNeedsDisplay];
    }
}

- (void)useNormalView
{
    if (self.currentView != TV_Normal) {
        // Remove the subviews whenever we change
        for (UIView *subView in [self subviews]) {
            [subView removeFromSuperview];
        }

        self.currentView = TV_Normal;
        self.drawPaths = [self buildLunarSurface];
        [self setNeedsDisplay];
    }
}

- (BOOL)viewIsDetailed
{
    return (self.currentView == TV_Detailed);
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
}

- (void)dealloc
{
    [_moonArray release];
    
    [super dealloc];
}

@end
