//
//  NSDate+PMTimezone.h
//  FranceTV
//
//  Created by Guillaume Salva on 12/14/15.
//  Copyright © 2015 Guillaume Salva. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PMNSDateSamePrecision) {
    PMNSDateSamePrecisionSecond,
    PMNSDateSamePrecisionMinute,
    PMNSDateSamePrecisionHour
};


@interface NSDate (PMTimezone)

+ (NSDate *)nowInFrance;

- (BOOL)isSameDate:(NSDate *)date withPrecision:(PMNSDateSamePrecision)precision;

@end
