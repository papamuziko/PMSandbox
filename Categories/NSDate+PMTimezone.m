//
//  NSDate+PMTimezone.m
//  FranceTV
//
//  Created by Guillaume Salva on 12/14/15.
//  Copyright © 2015 Guillaume Salva. All rights reserved.
//

#import "NSDate+PMTimezone.h"

@implementation NSDate (PMTimezone)

+ (NSDate *)nowInFrance
{
    NSTimeZone *tz_france = [NSTimeZone timeZoneWithName:@"Europe/Paris"];
    NSTimeZone *tz_local = [NSTimeZone localTimeZone];
    
     return [NSDate dateWithTimeInterval:([tz_france secondsFromGMT] - [tz_local secondsFromGMT]) sinceDate:[NSDate date]];
}

- (BOOL)isSameDate:(NSDate *)date withPrecision:(PMNSDateSamePrecision)precision
{
    if(nil == date) {
        return NO;
    }
    
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dc_date = [cal components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:date];
    
    NSDateComponents *dc_self = [cal components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:self];
    
    if(dc_self.hour != dc_date.hour) {
        return NO;
    }
    if(precision == PMNSDateSamePrecisionHour) {
        return YES;
    }
    
    if(dc_self.minute != dc_date.minute) {
        return NO;
    }
    if(precision == PMNSDateSamePrecisionMinute) {
        return YES;
    }
    
    if(dc_self.second != dc_date.second) {
        return NO;
    }
    
    return YES;
}

@end
