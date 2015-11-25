//
//  SBGetCurrentTariffInfoRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 23.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetCurrentTariffInfoRequest.h"
#import "SBRequestOperation_Private.h"

@implementation SBGetCurrentTariffInfoRequest

- (NSString *)method
{
    return @"getCurrentTariffInfo";
}

- (SBResultProcessor *)resultProcessor
{
    return [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSDictionary class]];
}

@end
