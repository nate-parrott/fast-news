//
//  CGPointExtras.c
//  Sketch
//
//  Created by Nate Parrott on 6/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include <Foundation/Foundation.h>
#import "CGPointExtras.h"

const CGPoint CGPointNull = {-999999999, -999999999};
BOOL CGPointIsNull(CGPoint p) {
    return CGPointEqualToPoint(p, CGPointNull);
}
CGFloat CGPointDistance(CGPoint p1, CGPoint p2) {
    return sqrtf(powf(p1.x-p2.x, 2) + powf(p1.y-p2.y, 2));
}

const CGFloat CGPointStandardSnappingThreshold = 15;
CGFloat CGSnap(CGFloat x, CGFloat range) {
    return CGSnapWithThreshold(x, range, CGPointStandardSnappingThreshold);
}
CGFloat CGSnapWithThreshold(CGFloat x, CGFloat range, CGFloat threshold) {
    if (x <= threshold) {
        return 0;
    } else if (x >= range-threshold) {
        return range;
    } else if (fabs(x-range/2) <= threshold) {
        return range/2;
    } else {
        return x;
    }
}
CGFloat CGPointAngleBetween(CGPoint p1, CGPoint p2) {
    return atan2(p2.y-p1.y, p2.x-p1.x);
}
CGPoint CGPointShift(CGPoint p, CGFloat direction, CGFloat distance) {
    return CGPointMake(p.x + cos(direction)*distance, p.y + sin(direction)*distance);
}
CGPoint CGPointMidpoint(CGPoint p1, CGPoint p2) {
    return CGPointShift(p1, CGPointAngleBetween(p1, p2), CGPointDistance(p1, p2)/2);
}

CGFloat CGTransformByAddingPadding(CGFloat p, CGFloat padding, CGFloat range) {
    return padding + (p/range) * (range-padding*2);
}
CGFloat CGTransformByRemovingPadding(CGFloat p, CGFloat padding, CGFloat range) {
    return MAX(0, MIN(range, (p-padding)/(range-padding*2)*range));
}
CGPoint CGPointLinearlyInterpolate(CGPoint p1, CGPoint p2, CGFloat progress) {
    return CGPointMake(p1.x * (1 - progress) + p2.x * progress, p1.y * (1 - progress) + p2.y * progress);
}

CGPoint CGPointAdd(CGPoint p1, CGPoint p2) {
    return CGPointMake(p1.x+p2.x, p1.y+p2.y);
}
CGPoint CGPointScale(CGPoint p, CGFloat scale) {
    return CGPointMake(p.x*scale, p.y*scale);
}

CGPoint NPEvaluateSmoothCurve(CGPoint prevPoint, CGPoint fromPoint, CGPoint toPoint, CGPoint nextPoint, CGFloat progress, BOOL ignorePreviousPointDistance) {
    
    CGFloat distanceBetween = 0;
    if (ignorePreviousPointDistance) distanceBetween = CGPointDistance(fromPoint, toPoint);
    
    CGPoint controlPoint1 = toPoint;
    if (!CGPointEqualToPoint(fromPoint, prevPoint)) {
        CGFloat controlPointDist = ignorePreviousPointDistance ? distanceBetween : CGPointDistance(fromPoint, prevPoint);
        CGFloat controlPointAngle = M_PI + CGPointDistance(fromPoint, prevPoint);
        controlPoint1 = CGPointShift(fromPoint, controlPointAngle, controlPointDist);
    }
    
    CGPoint controlPoint2 = fromPoint;
    if (!CGPointEqualToPoint(toPoint, nextPoint)) {
        CGFloat controlPointDist = ignorePreviousPointDistance ? distanceBetween : CGPointDistance(toPoint, nextPoint);
        CGFloat controlPointAngle = M_PI + CGPointAngleBetween(toPoint, nextPoint);
        controlPoint2 = CGPointShift(fromPoint, controlPointAngle, controlPointDist);
    }
    
    CGPoint incomingTangent = CGPointLinearlyInterpolate(fromPoint, controlPoint1, progress);
    CGPoint outgoingTangent = CGPointLinearlyInterpolate(toPoint, controlPoint2, progress);
    return CGPointLinearlyInterpolate(incomingTangent, outgoingTangent, progress);
}

CGFloat NPRandomFloat() {
    return (rand() % 20000) / 10000.0 - 1;
}

CGFloat NPRandomContinuousFloat(CGFloat x) {
    return 0; // NAH
}

CGPoint CGPointRotate(CGPoint p, CGFloat r) {
    // TODO: optimize
    return CGPointShift(CGPointZero, atan2(p.y, p.x) + r, CGPointDistance(CGPointZero, p));
}

CGRect NPBoundingBoxOfRotatedRect(CGSize size, CGPoint center, CGFloat rotation, CGFloat scale) {
    CGFloat minX = center.x;
    CGFloat minY = center.y;
    CGFloat maxX = center.x;
    CGFloat maxY = center.y;
    
    CGPoint aCorner = CGPointRotate(CGPointMake(size.width/2*scale, size.height/2*scale), rotation);
    
    for (NSInteger i=0; i<4; i++) {
        CGPoint corner = CGPointRotate(aCorner, i * M_PI/2);
        minX = MIN(minX, center.x + corner.x);
        minY = MIN(minY, center.y + corner.y);
        maxX = MAX(maxX, center.x + corner.x);
        maxY = MAX(maxY, center.y + corner.y);
    }
    
    return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

CGFloat CGRectDiagonal(CGRect r) {
    return sqrt(pow(CGRectGetWidth(r), 2) + pow(CGRectGetHeight(r), 2));
}

CGSize CMSizeWithDiagonalAndAspectRatio(CGFloat d, CGFloat a) {
    /*
     d = (w^2 + (w/a)^2) ^ 0.5
     w=> d/sqrt(a^-2 + 1)
     */
    CGFloat width = d / sqrt(pow(a, -2) + 1);
    CGFloat height = width / a;
    return CGSizeMake(width, height);
}

CGFloat CMNormalizeAngle(CGFloat angle) {
    return fmodf(angle, M_PI * 2);
}

CGFloat CMInterpolateAngles(CGFloat prev, CGFloat next, CGFloat progress) {
    CGPoint p1 = CGPointMake(cos(prev), sin(prev));
    CGPoint p2 = CGPointMake(cos(next), sin(next));
    if (CGPointEqualToPoint(CGPointZero, CGPointAdd(p1, p2))) {
        // angles are 180-degrees opposite, so it doesn't matter which way we interpolate them
        return CMNormalizeAngle(prev) * (1-progress) + CMNormalizeAngle(next) * progress;
    } else {
        CGPoint sum = CGPointMake(p1.x * (1-progress) + p2.x * progress, p1.y * (1-progress) + p2.y * progress);
        return atan2(sum.y, sum.x);
    }
}

