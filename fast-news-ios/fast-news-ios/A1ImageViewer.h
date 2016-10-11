//
//  A1ImageViewer.h
//  A1ImageViewer
//
//  Created by Nate Parrott on 10/6/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface A1ImageViewer : UIView

@property (nonatomic) UIImageView *imageView;
@property (nonatomic) CGFloat imageAspectRatio;
@property (nonatomic, copy) void (^onDismiss)();
- (void)presentInContainerView:(UIView *)container originalImageView:(UIImageView *)original;

@end
