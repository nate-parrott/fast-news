//
//  A1ImageViewer.m
//  A1ImageViewer
//
//  Created by Nate Parrott on 10/6/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

#import "A1ImageViewer.h"

@interface A1ImageViewer () {
    UIImageView *_imageView;
}

@property (nonatomic) UIView *topSnapshot, *bottomSnapshot;
// for presentation animation:
@property (nonatomic,weak) UIView *containerView;
@property (nonatomic,weak) UIImageView *originalImageView;
@property (nonatomic) CGFloat animationProgress;
@property (nonatomic) UIPanGestureRecognizer *dismissPanRec;
@property (nonatomic) UIPinchGestureRecognizer *dismissPinchRec;

@property (nonatomic) BOOL setupYet;

@end

@implementation A1ImageViewer

#pragma mark Lifecycle

- (void)setup {
    if (self.setupYet) return;
    self.setupYet = YES;
    
    [self imageView];
    
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)]];
    self.dismissPanRec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPan:)];
    [self addGestureRecognizer:self.dismissPanRec];
    self.dismissPinchRec = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPinch:)];
    [self addGestureRecognizer:self.dismissPinchRec];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    [self setup];
}

#pragma mark Actions

- (void)dismiss:(id)sender {
    [UIView animateWithDuration:0.3 animations:^{
        self.animationProgress = 0;
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        if (self.onDismiss) self.onDismiss();
    }];
}

- (void)dismissPan:(UIPanGestureRecognizer *)sender {
    CGFloat progress = fabs([sender translationInView:self].y) / (self.bounds.size.height/2);
    CGFloat velocity = fabs([sender velocityInView:self].y) / (self.bounds.size.height/2);
    [self dismissalGesture:sender withProgress:progress velocity:velocity];
}

- (void)dismissPinch:(UIPinchGestureRecognizer *)sender {
    CGFloat progress = MIN(1, 1-[sender scale]);
    CGFloat velocity = 0;
    [self dismissalGesture:sender withProgress:progress velocity:velocity];
}

- (void)dismissalGesture:(UIGestureRecognizer *)sender withProgress:(CGFloat)progress velocity:(CGFloat)velocity {
    if (sender.state == UIGestureRecognizerStateChanged) {
        [self continueInteractiveDismissAnimationWithProgress:progress];
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        if ((progress > 0.1 && velocity > 1) || (progress > 0.5 && velocity == 0)) {
            [self commitInteractiveDismissalWithVelocity:velocity];
        } else {
            [self cancelInteractiveDismissalWithVelocity:velocity];
        }
    } else if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateFailed || sender.state == UIGestureRecognizerStateCancelled) {
        [self cancelInteractiveDismissalWithVelocity:velocity];
    }
}

- (void)continueInteractiveDismissAnimationWithProgress:(CGFloat)progress {
    self.animationProgress = 1 - progress;
}

- (void)cancelInteractiveDismissalWithVelocity:(CGFloat)velocity {
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:velocity options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.animationProgress = 1;
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)commitInteractiveDismissalWithVelocity:(CGFloat)velocity {
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:velocity options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.animationProgress = 0;
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        if (self.onDismiss) self.onDismiss();
    }];
}

#pragma mark Snapshots

- (void)takeSnapshots {
    if (self.containerView && self.originalImageView) {
        BOOL wasHidden = self.hidden;
        self.hidden = NO;
        
        CGRect frame = [self.containerView convertRect:self.originalImageView.bounds fromView:self.originalImageView];
        CGRect topFrame = CGRectMake(0, 0, self.containerView.bounds.size.width, frame.origin.y);
        CGRect bottomFrame = CGRectMake(0, CGRectGetMaxY(frame), self.containerView.bounds.size.width, self.containerView.bounds.size.height - CGRectGetMaxY(frame));
        self.topSnapshot = [self.containerView resizableSnapshotViewFromRect:topFrame afterScreenUpdates:YES withCapInsets:UIEdgeInsetsZero];
        self.bottomSnapshot = [self.containerView resizableSnapshotViewFromRect:bottomFrame afterScreenUpdates:YES withCapInsets:UIEdgeInsetsZero];
        
        self.hidden = wasHidden;
    }
}

- (void)setTopSnapshot:(UIView *)topSnapshot {
    [_topSnapshot removeFromSuperview];
    _topSnapshot = topSnapshot;
    [self addSubview:topSnapshot];
}

- (void)setBottomSnapshot:(UIView *)bottomSnapshot {
    [_bottomSnapshot removeFromSuperview];
    _bottomSnapshot = bottomSnapshot;
    [self addSubview:bottomSnapshot];
}

#pragma mark API

- (void)presentInContainerView:(UIView *)container originalImageView:(UIImageView *)original {
    self.containerView = container;
    self.originalImageView = original;
    
    [container addSubview:self];
    self.frame = container.bounds;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self takeSnapshots];
    self.animationProgress = 0;
    [self layoutIfNeeded];
    [UIView animateWithDuration:0.3 animations:^{
        self.animationProgress = 1;
        [self layoutIfNeeded];
    }];
}

- (UIImageView *)imageView {
    if (!_imageView) {
        UIImageView *imageView = [UIImageView new];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        self.imageView = imageView;
    }
    return _imageView;
}

- (void)setImageView:(UIImageView *)imageView {
    [_imageView removeFromSuperview];
    _imageView = imageView;
    [self setup];
    [self addSubview:imageView];
    [self setNeedsLayout];
}

- (void)setImageAspectRatio:(CGFloat)imageAspectRatio {
    _imageAspectRatio = imageAspectRatio;
    [self setNeedsLayout];
}

- (void)setAnimationProgress:(CGFloat)animationProgress {
    _animationProgress = animationProgress;
    [self setNeedsLayout];
}

#pragma mark Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = [self interpolateRect:[self imageViewFrameAtStartOfPresentation] withRect:[self imageViewFrameWhenFullyPresented] progress:self.animationProgress];
    if (self.containerView && self.originalImageView) {
        self.topSnapshot.hidden = NO;
        self.bottomSnapshot.hidden = NO;
        CGRect frame = [self.containerView convertRect:self.originalImageView.bounds fromView:self.originalImageView];
        CGRect topFrame = CGRectMake(0, 0, self.containerView.bounds.size.width, frame.origin.y);
        CGRect bottomFrame = CGRectMake(0, CGRectGetMaxY(frame), self.containerView.bounds.size.width, self.containerView.bounds.size.height - CGRectGetMaxY(frame));
        CGRect topFrameWhenPresented = CGRectMake(0, -topFrame.size.height, topFrame.size.width, topFrame.size.height);
        CGRect bottomFrameWhenPresented = CGRectMake(0, self.bounds.size.height, bottomFrame.size.width, bottomFrame.size.height);
        self.topSnapshot.frame = [self interpolateRect:topFrame withRect:topFrameWhenPresented progress:self.animationProgress];
        self.bottomSnapshot.frame = [self interpolateRect:bottomFrame withRect:bottomFrameWhenPresented progress:self.animationProgress];
    } else {
        self.topSnapshot.hidden = YES;
        self.bottomSnapshot.hidden = YES;
    }
}

- (CGRect)imageViewFrameWhenFullyPresented {
    CGSize someSize = CGSizeMake(self.imageAspectRatio, 1);
    CGFloat scale = MAX(self.bounds.size.width / someSize.width, self.bounds.size.height / someSize.height);
    CGSize size = CGSizeMake(someSize.width * scale, someSize.height * scale);
    return CGRectMake((self.bounds.size.width - size.width)/2, (self.bounds.size.height - size.height)/2, size.width, size.height);
}

- (CGRect)imageViewFrameAtStartOfPresentation {
    if (self.originalImageView) {
        return [self convertRect:self.originalImageView.bounds fromView:self.originalImageView];
    } else {
        return [self imageViewFrameWhenFullyPresented];
    }
}

- (CGRect)interpolateRect:(CGRect)r1 withRect:(CGRect)r2 progress:(CGFloat)t {
    return CGRectMake(r1.origin.x * (1-t) + r2.origin.x * t, r1.origin.y * (1-t) + r2.origin.y * t, r1.size.width * (1-t) + r2.size.width * t, r1.size.height * (1-t) + r2.size.height * t);
}

@end
