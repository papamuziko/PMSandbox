//
//  PMOperationQueue.m
//  FranceTV
//
//  Created by Guillaume Salva on 1/11/16.
//  Copyright © 2016 Guillaume Salva. All rights reserved.
//

#import "PMOperationQueue.h"

@interface PMOperationQueue ()

@property (nonatomic, strong) NSMutableDictionary *dico_operation;

@end


@implementation PMOperationQueue


#pragma mark - Variables

- (NSMutableDictionary *)dico_operation
{
    if(nil == _dico_operation) {
        _dico_operation = [[NSMutableDictionary alloc] init];
    }
    return _dico_operation;
}


#pragma mark - Public methods

- (NSString *)queueOperation:(NSOperation *)operation
{
    if(nil == operation) {
        return nil;
    }
    
    NSString *operation_uuid = [[NSUUID UUID] UUIDString];
    
    [self.dico_operation setObject:operation forKey:operation_uuid];
    [operation setName:operation_uuid];
    
    [operation addObserver:self
                forKeyPath:@"isFinished"
                   options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                   context:"isFinished"];
    [operation addObserver:self
                forKeyPath:@"isCancelled"
                   options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                   context:"isCancelled"];
    
    [self addOperation:operation];
    
    return operation_uuid;
}

- (void)cancelOperation:(NSString *)operation_uuid
{
    if(nil == operation_uuid) {
        return;
    }
    
    NSOperation *operation_to_cancel = [_dico_operation objectForKey:operation_uuid];
    if(nil != operation_to_cancel) {
        [_dico_operation removeObjectForKey:operation_uuid];
        [operation_to_cancel cancel];
    }
}


#pragma mark - Overwrited functions

- (void)cancelAllOperations
{
    [_dico_operation removeAllObjects];
    
    [super cancelAllOperations];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(__unused id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if(((context == "isFinished") || (context == "isCancelled")) &&
       (nil != object) && [object isKindOfClass:[NSOperation class]]) {
        NSOperation *op = (NSOperation *)object;
        if(op.isCancelled || op.isFinished) {
            NSString *op_uuid = op.name;
            [_dico_operation removeObjectForKey:op_uuid];
        }
    }
}


@end
