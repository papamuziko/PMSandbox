//
//  NSManagedObject+PMOperations.h
//  FranceTV
//
//  Created by Guillaume Salva on 1/4/16.
//  Copyright © 2016 Guillaume Salva. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (PMOperations)

+ (NSUInteger)count:(NSPredicate *)predicate
   inContext:(NSManagedObjectContext *)context;
+ (NSArray *)objects:(NSPredicate *)predicate
            sortedBy:(NSArray *)sort_array
           withLimit:(NSUInteger)limit
           inContext:(NSManagedObjectContext *)context;
+ (instancetype)object:(NSPredicate *)predicate
             inContext:(NSManagedObjectContext *)context;

@end
