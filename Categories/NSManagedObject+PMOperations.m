//
//  NSManagedObject+PMOperations.m
//  FranceTV
//
//  Created by Guillaume Salva on 1/4/16.
//  Copyright © 2016 Guillaume Salva. All rights reserved.
//

#import "NSManagedObject+PMOperations.h"

@implementation NSManagedObject (PMOperations)

+ (NSUInteger)count:(NSPredicate *)predicate
   inContext:(NSManagedObjectContext *)context
{
    NSUInteger result = 0;
    if(nil != context) {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([self class])
                                                  inManagedObjectContext:context];
        
        [request setEntity:entity];
        if(predicate != nil){
            [request setPredicate:predicate];
        }
        
        @try {
            result = (int)[context countForFetchRequest:request error:nil];
        }
        @catch (NSException * e) {
            result = 0;
        }
        
        request = nil;
    }
    return result;
}

+ (NSArray *)objects:(NSPredicate *)predicate
            sortedBy:(NSArray *)sort_array
           withLimit:(NSUInteger)limit
           inContext:(NSManagedObjectContext *)context
{
    NSArray *result = nil;
    if(nil != context) {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([self class])
                                                  inManagedObjectContext:context];
        
        [request setEntity:entity];
        if(predicate != nil){
            [request setPredicate:predicate];
        }
        
        if(sort_array != nil){
            [request setSortDescriptors:sort_array];
        }
        
        if(limit > 0){
            [request setFetchLimit:limit];
        }
        
        @try {
            result = (NSArray *)[context executeFetchRequest:request error:nil];
        }
        @catch (NSException * e) {
            result = nil;
        }
        
        request = nil;
    }
    return result;
}

+ (instancetype)object:(NSPredicate *)predicate
             inContext:(NSManagedObjectContext *)context
{
    NSArray *results = [self objects:predicate
                            sortedBy:nil
                           withLimit:1
                           inContext:context];
    if((nil != results) && ([results count] > 0)) {
        return [results objectAtIndex:0];
    }
    return nil;
}

@end
