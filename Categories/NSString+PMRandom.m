//
//  NSString+PMRandom.m
//  FranceTV
//
//  Created by Guillaume Salva on 1/9/16.
//  Copyright © 2016 Guillaume Salva. All rights reserved.
//

#import "NSString+PMRandom.h"

@implementation NSString (PMRandom)

+ (NSString *)randomKey
{
    return [[NSUUID UUID] UUIDString];
}

@end
