//
//  EnableSPDY.m
//  fast-news-ios
//
//  Created by Nate Parrott on 2/10/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

#import "EnableSPDY.h"
#import <CocoaSPDY/SPDYProtocol.h>

@implementation EnableSPDY

+ (void)enableSPDY {
    [NSURLSessionConfiguration defaultSessionConfiguration].protocolClasses = @[[SPDYURLSessionProtocol class]];
}

@end
