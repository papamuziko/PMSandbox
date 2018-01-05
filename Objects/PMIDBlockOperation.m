//
//  PMIDBlockOperation.m
//  FranceTV
//
//  Created by Guillaume Salva on 1/9/16.
//  Copyright © 2016 Guillaume Salva. All rights reserved.
//

#import "PMIDBlockOperation.h"

#import "NSString+PMRandom.h"

@implementation PMIDBlockOperation

@synthesize uuid = _uuid;

- (NSString *)uuid
{
    if(nil == _uuid) {
        _uuid = [NSString randomKey];
    }
    
    return _uuid;
}

@end
