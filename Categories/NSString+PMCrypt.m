//
//  NSString+PMCrypt.m
//  FranceTV
//
//  Created by Guillaume Salva on 12/9/15.
//  Copyright © 2015 Guillaume Salva. All rights reserved.
//

#import "NSString+PMCrypt.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (PMCrypt)

+ (NSString *)randomKey
{
    return [[NSUUID UUID] UUIDString];
}

- (NSString *)md5
{
    const char* str = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

@end
