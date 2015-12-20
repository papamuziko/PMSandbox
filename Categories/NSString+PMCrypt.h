//
//  NSString+PMCrypt.h
//  FranceTV
//
//  Created by Guillaume Salva on 12/9/15.
//  Copyright © 2015 Guillaume Salva. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (PMCrypt)

+ (NSString *)randomKey;

- (NSString *)md5;

@end
