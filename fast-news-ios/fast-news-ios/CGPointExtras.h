//
//  CGPointExtras.h
//  Sketch
//
//  Created by Nate Parrott on 6/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef Sketch_CGPointExtras_h
#define Sketch_CGPointExtras_h

#ifdef __cplusplus
extern "C" {
#endif
    
#import <UIKit/UIKit.h>

extern const CGPoint CGPointNull;
BOOL CGPointIsNull(CGPoint p);

    CGPoint CGPointAdd(CGPoint p1, CGPoint p2);
    CGPoint CGPointScale(CGPoint p, CGFloat scale);
    
CGFloat CGPointDistance(CGPoint p1, CGPoint p2);

extern const CGFloat CGPointStandardSnappingThreshold;
//CGPoint CGPointSnapToPossiblePoints(CGPoint point, CGPoint* possiblePoints, int numPossiblePoints, CGFloat threshold);
CGFloat CGSnapWithThreshold(CGFloat x, CGFloat range, CGFloat threshold);
CGFloat CGSnap(CGFloat x, CGFloat range);

CGFloat CGPointAngleBetween(CGPoint p1, CGPoint p2);
CGPoint CGPointShift(CGPoint p, CGFloat direction, CGFloat distance);
CGPoint CGPointMidpoint(CGPoint p1, CGPoint p2);

    CGPoint CGPointRotate(CGPoint p, CGFloat r);
    
CGFloat CGTransformByAddingPadding(CGFloat p, CGFloat padding, CGFloat range);
CGFloat CGTransformByRemovingPadding(CGFloat p, CGFloat padding, CGFloat range);

    CGPoint CGPointLinearlyInterpolate(CGPoint p1, CGPoint p2, CGFloat progress);
    
CGPoint NPEvaluateSmoothCurve(CGPoint prevPoint, CGPoint fromPoint, CGPoint toPoint, CGPoint nextPoint, CGFloat progress, BOOL ignorePreviousPointDistance);
    

CGFloat NPRandomFloat(); // (-1..1)
CGFloat NPRandomContinuousFloat(CGFloat x); // (-1..1)
    
CGRect NPBoundingBoxOfRotatedRect(CGSize size, CGPoint center, CGFloat rotation, CGFloat scale);
    
    CGFloat CGRectDiagonal(CGRect r);
    
    CGSize CMSizeWithDiagonalAndAspectRatio(CGFloat boundsDiagonal, CGFloat aspectRatio);
    
    CGFloat CMInterpolateAngles(CGFloat prev, CGFloat next, CGFloat progress);
    
#ifdef __cplusplus
}
#endif
    
#endif

