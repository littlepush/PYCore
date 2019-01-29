//
//  PYSemaphore.m
//  PYCore
//
//  Created by Push Chen on 6/12/13.
//  Copyright (c) 2013 PushLab. All rights reserved.
//

/*
 LGPL V3 Lisence
 This file is part of cleandns.
 
 PYCore is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 PYData is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with cleandns.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
 LISENCE FOR IPY
 COPYRIGHT (c) 2013, Push Chen.
 ALL RIGHTS RESERVED.
 
 REDISTRIBUTION AND USE IN SOURCE AND BINARY
 FORMS, WITH OR WITHOUT MODIFICATION, ARE
 PERMITTED PROVIDED THAT THE FOLLOWING CONDITIONS
 ARE MET:
 
 YOU USE IT, AND YOU JUST USE IT!.
 WHY NOT USE THIS LIBRARY IN YOUR CODE TO MAKE
 THE DEVELOPMENT HAPPIER!
 ENJOY YOUR LIFE AND BE FAR AWAY FROM BUGS.
 */

#import "PYSemaphore.h"
#import "NSObject+PYCore.h"

@interface PYSemaphore (Internal)

// Internal
- (void)_initSemaphoreWith:(int)initCount max:(int32_t)maxCount;
- (void)_trySetStatue:(BOOL)statue;

@end

@implementation PYSemaphore

@dynamic count;
- (NSUInteger)count
{
    if ( _mutex == nil ) return 0;
    [_mutex lock];
    NSNumber *_count = PYIntToObject(_current);
    [_mutex unlock];
    return [_count unsignedIntValue];
}

@dynamic isAvailable;
- (BOOL)isAvailable
{
    if ( _mutex == nil ) return NO;
    [_mutex lock];
    NSNumber *_av = PYBoolToObject(_available);
    [_mutex unlock];
    return [_av boolValue];
}

@synthesize maxCount = _max;

- (id)init
{
    self = [super init];
    if ( self ) {
        [self _initSemaphoreWith:0 max:SEM_MAXCOUNT];
    }
    return self;
}
- (id)initWithCount:(int)initCount
{
    self = [super init];
    if ( self ) {
        [self _initSemaphoreWith:initCount max:SEM_MAXCOUNT];
    }
    return self;
}
- (id)initWithCount:(int)initCount maxCount:(int)max
{
    self = [super init];
    if ( self ) {
        [self _initSemaphoreWith:initCount max:max];
    }
    return self;
}

// Get the semaphore with specified timeout
- (BOOL)get
{
    return [self getUntil:SEM_MAXTIMEOUT];
}
- (BOOL)getUntil:(NSUInteger)timedout
{
    if ( [self isAvailable] == NO ) return NO;
    [_mutex lock];
    BOOL _result = NO;
    do {
        if ( _current > 0 ) {
            _current -= 1;
            _result = YES;
            break;
        }
        int _err;
        BOOL _wait_success = YES;
        if ( timedout == SEM_MAXTIMEOUT ) {
            while ( _current == 0 ) {
                if ( pthread_cond_wait(&_sem, &_mutex->_mutex) == EINVAL ) {
                    _wait_success = NO;
                    break;
                }
            }
        } else {
            struct timespec ts;
            struct timeval  tv;
            
            gettimeofday(&tv, NULL);
            ts.tv_nsec = tv.tv_usec * 1000 + (timedout % 1000) * 1000000;
            long _OP = (ts.tv_nsec / 1000000000);
            if ( _OP ) ts.tv_nsec %= 1000000000;
            ts.tv_sec = tv.tv_sec + timedout / 1000 + _OP;
    
            while ( _current == 0 ) {
                _err = pthread_cond_timedwait(&_sem, &_mutex->_mutex, &ts);
                // On time out or invalidate object
                if ( _err == ETIMEDOUT || _err == EINVAL ) {
                    _wait_success = NO;
                    break;
                }
            }
        }
        if ( _wait_success == YES ) {
            _current -= 1;
            _result = YES;
        }
    } while ( false );
    [_mutex unlock];
    return _result;
}
- (BOOL)tryGet
{
    if ( [self isAvailable] == NO ) return NO;
    
    BOOL _result = NO;
    [_mutex lock];
    if ( _current > 0 ) {
        _current -= 1;
        _result = YES;
    }
    [_mutex unlock];
    return _result;
}

// Release a semaphore
- (BOOL)give
{
    if ( [self isAvailable] == NO ) return NO;
    BOOL _result = NO;
    [_mutex lock];
    do {
        if ( _current == _max ) break;
        ++_current;
        pthread_cond_signal(&_sem);
        _result = YES;
    } while ( false );
    [_mutex unlock];
    return _result;
}

// Destroy the semaphore
- (void)destroy
{
    if ( self.isAvailable == NO ) return;
    pthread_condattr_destroy(&_condAttr);
    pthread_cond_destroy(&_sem);
    [self _trySetStatue:NO];
    _current = 0;
}

// Init the semaphore.
- (void)_initSemaphoreWith:(int)initCount max:(int32_t)maxCount
{
    [self destroy];
    if ( _mutex != nil ) {
        __RELEASE(_mutex);
        _mutex = nil;
    }
    _mutex = __RETAIN([[PYMutex alloc] init]);
    pthread_condattr_init(&_condAttr);
    pthread_cond_init(&_sem, &_condAttr);
    _current = initCount;
    _max = maxCount;
    [self _trySetStatue:YES];
}

- (void)_trySetStatue:(BOOL)statue
{
    [_mutex lock];
    if ( _available != statue ) _available = statue;
    [_mutex unlock];
}

- (void)clear
{
    [_mutex lock];
    _current = 0;
    [_mutex unlock];
}

@end

// @littlepush
// littlepush@gmail.com
// PYLab
