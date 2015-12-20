//
//  PMClock.h
//  FranceTV
//
//  Created by Guillaume Salva on 12/16/15.
//  Copyright © 2015 Guillaume Salva. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PMClockStyle) {
    PMClockStyleDefault
};


@interface PMClock : UIView

@property (nonatomic, assign) PMClockStyle style;

@property (nonatomic, nonnull, strong) NSDate *date;

@end
