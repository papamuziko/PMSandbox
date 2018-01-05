//
//  NSString+PMCrypt.h
//  FranceTV
//
//  Created by Guillaume Salva on 12/9/15.
//  Copyright © 2015 Guillaume Salva. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (PMCrypt)

- (NSString *)md5;

- (NSString *)decrypt_DES:(NSString *)key andIV:(NSString *)iv;

@end
