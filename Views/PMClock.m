//
//  PMClock.m
//  FranceTV
//
//  Created by Guillaume Salva on 12/16/15.
//  Copyright © 2015 Guillaume Salva. All rights reserved.
//

#import "PMClock.h"

@implementation PMClock

#pragma mark - Init

- (id)init
{
    self = [super init];
    
    [self _init];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    [self _init];
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    [self _init];
    
    return self;
}


#pragma mark - Setter

- (void)setStyle:(PMClockStyle)style
{
    if(_style == style) {
        return;
    }
    
    [self _cleanupLayout];
    
    _style = style;

    [self _setupLayout];
    [self _updateLayout];
}

- (void)setDate:(NSDate *)date
{
    _date = date;
    
    [self _updateLayout];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    [self _setupLayout];
    [self _updateLayout];
}


#pragma mark - Private

- (void)_init
{
    _style = PMClockStyleDefault;
    _date = [NSDate date];
    
    [self _updateLayout];
}

- (void)_cleanupLayout
{
    NSArray *aViews = [self subviews];
    [aViews enumerateObjectsUsingBlock:^(UIView *v_obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [v_obj removeFromSuperview];
    }];
}

- (void)_setupLayout
{
    switch (_style) {
        case PMClockStyleDefault:
        {
            [self _setupLayoutDefault];
        }
            break;
        default:
            break;
    }
}

- (void)_updateLayout
{
    if (nil == self.date) {
        return;
    }
    
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dc = [cal components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:self.date];
    
    NSInteger hour = [dc hour];
    NSInteger minute = [dc minute];
    
    switch (_style) {
        case PMClockStyleDefault:
        {
            [self _updateLayoutDefaultWithHour:hour andMinute:minute];
        }
            break;
        default:
            break;
    }
}


#pragma mark - Default Layout

- (void)_setupLayoutDefault
{
    // circle
    UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    circle.backgroundColor = [UIColor whiteColor];
    circle.layer.cornerRadius = self.frame.size.width / 2.0;
    circle.layer.borderWidth = 5.0;
    circle.layer.borderColor = [UIColor blackColor].CGColor;
    circle.layer.masksToBounds = YES;
    [self addSubview:circle];
    
    // numbers
    UILabel *l = nil;
    for (int i = 1; i <= 12; i ++) {
        l = [[UILabel alloc] initWithFrame:CGRectMake((self.frame.size.width / 2.0) + ((self.frame.size.width / 3.0) * (cos((i-3) * (M_PI / 6.0)))) - 10.0,
                                                      (self.frame.size.width / 2.0) + ((self.frame.size.width / 3.0) * (sin((i-3) * (M_PI / 6.0)))) - 10.0,
                                                      20,
                                                      20)];
        l.backgroundColor = [UIColor clearColor];
        l.text = [NSString stringWithFormat:@"%d", i];
        l.textAlignment = NSTextAlignmentCenter;
        l.textColor = [UIColor blackColor];
        l.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
        [self addSubview:l];
    }
    
    // lines
    UIView *line_hour = [[UIView alloc] initWithFrame:CGRectMake((self.frame.size.width / 3.0), (self.frame.size.height / 2.0) - 1.0, self.frame.size.width / 3.0, 3.0)];
    line_hour.backgroundColor = [UIColor grayColor];
    line_hour.tag = 1212;
    [self addSubview:line_hour];
    
    UIView *line_minute = [[UIView alloc] initWithFrame:CGRectMake((self.frame.size.width / 3.0), (self.frame.size.height / 2.0) - 1.0, self.frame.size.width / 3.0, 2.0)];
    line_minute.backgroundColor = [UIColor lightGrayColor];
    line_minute.tag = 1213;
    [self addSubview:line_minute];
    
}

- (void)_updateLayoutDefaultWithHour:(NSInteger)hour andMinute:(NSInteger)minute
{
    UIView *line_hour = [self viewWithTag:1212];
    UIView *line_minute = [self viewWithTag:1213];
    
    if((nil == line_hour) || (nil == line_minute)) {
        return;
    }
    
    float f_hour = (float)((((hour) % 12) * 5.0) + (minute / 12.0));
    
    line_hour.transform = CGAffineTransformMakeRotation((f_hour * (M_PI / 30.0)) - (M_PI / 2.0));
    line_hour.layer.anchorPoint = CGPointMake(0, 0.5);
    
    line_minute.transform = CGAffineTransformMakeRotation((minute * (M_PI / 30.0)) - (M_PI / 2.0));
    line_minute.layer.anchorPoint = CGPointMake(0, 0.5);
}

@end
