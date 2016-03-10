//
//  SKFill.h
//  Sketch
//
//  Created by Nate Parrott on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SKFill : NSObject <NSCoding>

-(void)drawInRect:(CGRect)rect; // will not clip to the rect automatically; the rect is only used to transform the start and end points

- (BOOL)canBeAppliedToGradientLayer;
- (void)applyToLayer:(CAGradientLayer *)layer;
- (UIColor *)solidColorOrNil;

@end
