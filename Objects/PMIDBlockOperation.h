//
//  PMIDBlockOperation.h
//  FranceTV
//
//  Created by Guillaume Salva on 1/9/16.
//  Copyright © 2016 Guillaume Salva. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PMIDBlockOperation : NSBlockOperation

@property (nonatomic, strong, readonly) NSString *uuid;

@end
