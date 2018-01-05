//
//  NSString+PMCrypt.m
//  FranceTV
//
//  Created by Guillaume Salva on 12/9/15.
//  Copyright © 2015 Guillaume Salva. All rights reserved.
//

#import "NSString+PMCrypt.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>


@implementation NSString (PMCrypt)

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

- (NSString *)decrypt_DES:(NSString *)key andIV:(NSString *)iv
{
    if(nil == key) {
        return nil;
    }
    if(nil == iv) {
        iv = key;
    }
    
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:self options:0];
    if(nil == decodedData) {
        return nil;
    }
    
    char keyPtr[kCCKeySizeDES+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF16StringEncoding];
    
    char ivPtr[kCCKeySizeDES+1];
    bzero(ivPtr, sizeof(ivPtr));
    [iv getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF16StringEncoding];
    
    size_t numBytesEncrypted = 0;
    
    NSUInteger dataLength = [self length];
    
    size_t bufferSize = dataLength + kCCBlockSizeDES;
    void *buffer_decrypt = malloc(bufferSize);
    
    CCCryptorStatus result = CCCrypt(kCCDecrypt,
                                     kCCAlgorithmDES,
                                     kCCOptionPKCS7Padding,
                                     keyPtr,
                                     kCCKeySizeDES,
                                     ivPtr,
                                     [decodedData bytes],
                                     [decodedData length],
                                     buffer_decrypt, bufferSize,
                                     &numBytesEncrypted );
    
    if(result != kCCSuccess) {
        return nil;
    }
    
    return [[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:buffer_decrypt length:numBytesEncrypted] encoding:NSUTF8StringEncoding];
}

@end
