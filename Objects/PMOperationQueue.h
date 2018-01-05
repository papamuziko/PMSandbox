//
//  PMOperationQueue.h
//  FranceTV
//
//  Created by Guillaume Salva on 1/11/16.
//  Copyright © 2016 Guillaume Salva. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PMOperationQueue : NSOperationQueue

- (NSString *)queueOperation:(NSOperation *)operation;
- (void)cancelOperation:(NSString *)operation_uuid;

@end
