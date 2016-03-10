//
//  SKFill.m
//  Sketch
//
//  Created by Nate Parrott on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKFill.h"

@implementation SKFill

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder {
    
}
-(void)drawInRect:(CGRect)rect {
    // subclasses should implement this method
}
- (BOOL)canBeAppliedToGradientLayer {
    return NO;
}
- (void)applyToLayer:(CAGradientLayer *)layer {
    
}
- (UIColor *)solidColorOrNil {
    return nil;
}

@end
