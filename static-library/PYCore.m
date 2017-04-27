//
//  PYCore.m
//  PYCore
//
//  Created by Push Chen on 6/10/13.
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

#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#import "PYCoreMacro.h"
#import "PYCore.h"
#import <sys/mount.h>
#import <mach/mach.h>
#import <sys/utsname.h>
#import <sys/xattr.h>
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <sys/param.h>
#import <mach/processor_info.h>
#import <mach/mach_host.h>

#define PYCORE_TIME_FORMAT_BASIC	@"%04d-%02d-%02d %02d:%02d:%02d,%03d"

// Get current time in simple format
NSString * __getCurrentFormatDate()
{
    struct timeb _timeBasic;
    struct tm *  _timeStruct;
    ftime( &_timeBasic );
    _timeStruct = localtime( &_timeBasic.time );
    return [NSString stringWithFormat:PYCORE_TIME_FORMAT_BASIC,
            (uint32_t)(_timeStruct->tm_year + 1900), (uint8_t)(_timeStruct->tm_mon + 1),
            (uint8_t)(_timeStruct->tm_mday), (uint8_t)(_timeStruct->tm_hour),
            (uint8_t)(_timeStruct->tm_min), (uint32_t)(_timeStruct->tm_sec),
            (uint16_t)(_timeBasic.millitm)];
}

void __formatLogLine(const char * __file,
                     const char * __func,
                     uint32_t __line,
                     NSString *__log)
{
//    fprintf(stdout, "[%s]<%s:%u> %s\n", [__getCurrentFormatDate() UTF8String],
//            __func, __line, [__log UTF8String]);
    printf("[%s]<%s:%u> %s\n", [__getCurrentFormatDate() UTF8String],
           __func, __line, [__log UTF8String]);
}

BOOL __print_logHead(const char * __func, uint32_t __line )
{
    printf("[%s]<%s:%u>", [__getCurrentFormatDate() UTF8String],
           __func, __line);
    return YES;
}
BOOL __print_bool( const char * _exp, BOOL _bexp )
{
    printf("{%s}: %s\n", _exp, (_bexp ? "YES" : "NO"));
    return _bexp;
}
BOOL __print_while( const char * _exp, BOOL _bexp )
{
    printf("{WHILE:%s}: %s\n", _exp, (_bexp ? "YES" : "NO"));
    return _bexp;
}
BOOL __print_else_bool( const char * _exp, BOOL _bexp )
{
    printf("{else: %s}: %s\n", _exp, (_bexp ? "YES" : "NO"));
    return _bexp;
}

NSString *__doucmentPath( ) {
    static NSString *_docPath = @"";
    @synchronized ( _docPath ) {
        if ( [_docPath length] == 0 ) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains
            (NSDocumentDirectory, NSUserDomainMask, YES);
            _docPath = [[paths safeObjectAtIndex:0] copy];
        }
    }
    return _docPath;
}

NSString *__libraryPath( ) {
    static NSString *_libPath = @"";
    @synchronized( _libPath ) {
        if ( [_libPath length] == 0 ) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains
            (NSLibraryDirectory, NSUserDomainMask, YES);
            _libPath = [[paths safeObjectAtIndex:0] copy];
        }
    }
    return _libPath;
}

NSString *__cachePath( ) {
    static NSString *_cachePath = @"";
    @synchronized( _cachePath ) {
        if ( [_cachePath length] == 0 ) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains
            (NSCachesDirectory, NSUserDomainMask, YES);
            _cachePath = [[paths safeObjectAtIndex:0] copy];
            // Create the path if needed.
            BOOL isDir = NO;
            NSError *error;
            if ( ![[NSFileManager defaultManager] fileExistsAtPath:_cachePath
                                                       isDirectory:&isDir] &&
                isDir == NO ) {
                [[NSFileManager defaultManager] createDirectoryAtPath:_cachePath
                                          withIntermediateDirectories:NO
                                                           attributes:nil
                                                                error:&error];
            }
        }
    }
    return _cachePath;
}

NSString *__guid( ) {
    // create a new UUID which you own
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    
    // create a new CFStringRef (toll-free bridged to NSString)
    // that you own
    NSString *uuidString = (NSString *)CFBridgingRelease
    (CFUUIDCreateString(kCFAllocatorDefault, uuid));
    uuidString = [uuidString
                  stringByReplacingOccurrencesOfString:@"-"
                  withString:@""];
    // transfer ownership of the string
    // to the autorelease pool
    
    // release the UUID
    CFRelease(uuid);
    
    return uuidString;
}

NSString *__timestampId( ) {
    struct timeval _timenow;
    gettimeofday( &_timenow, NULL );
    uint64_t _usec = (uint64_t)_timenow.tv_sec * (uint64_t)1000000;
    _usec += _timenow.tv_usec;
    NSString *_timestamp = [NSString stringWithFormat:@"%llu", _usec];
    return _timestamp;
}

NSUInteger __getMemoryInUse()
{
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    if( kerr == KERN_SUCCESS ) {
        return info.resident_size;
    } else {
        PYLog(@"Error with task_info(): %s", mach_error_string(kerr));
        return -1;
    }
}

NSUInteger __getFreeMemory()
{
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;
    
    host_page_size(host_port, &pagesize);
    host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    return vm_stat.free_count * pagesize;
}

NSArray *__getCPUUsage()
{
    processor_info_array_t _cpuInfo, _prevCPUInfo = nil;
    mach_msg_type_number_t _numCPUInfo, _numPrevCPUInfo = 0;
    unsigned _numCPUs;
    NSLock *_cpuUsageLock;
    
    int _mib[2U] = { CTL_HW, HW_NCPU };
    size_t _sizeOfNumCPUs = sizeof(_numCPUs);
    int _status = sysctl(_mib, 2U, &_numCPUs, &_sizeOfNumCPUs, NULL, 0U);
    if( _status ) _numCPUs = 1;
    
    _cpuUsageLock = [[NSLock alloc] init];
    
    natural_t _numCPUsU = 0U;
    kern_return_t err = host_processor_info(mach_host_self(),
                                            PROCESSOR_CPU_LOAD_INFO,
                                            &_numCPUsU,
                                            &_cpuInfo,
                                            &_numCPUInfo);
    NSMutableArray *_cpuInfoArray = [NSMutableArray array];
    if( err == KERN_SUCCESS ) {
        [_cpuUsageLock lock];
        
        for ( unsigned i = 0U; i < _numCPUs; ++i ) {
            Float32 _inUse, _total;
            if( _prevCPUInfo ) {
                _inUse = (
                          (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] -
                           _prevCPUInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER])
                          + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] -
                             _prevCPUInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM])
                          + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE] -
                             _prevCPUInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE])
                          );
                _total = _inUse + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE] -
                                   _prevCPUInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE]);
            } else {
                _inUse = (
                          _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] +
                          _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] +
                          _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE]
                          );
                _total = _inUse + _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
            }
            
            [_cpuInfoArray addObject:PYDoubleToObject(_inUse / _total * 100.f)];
            PYLog(@"Core: %u, Usage: %.2f%%", i, _inUse / _total * 100.f);
        }
        
        [_cpuUsageLock unlock];
        
        if(_prevCPUInfo) {
            size_t prevCpuInfoSize = sizeof(integer_t) * _numPrevCPUInfo;
            vm_deallocate(mach_task_self(), (vm_address_t)_prevCPUInfo, prevCpuInfoSize);
        }
                
        _cpuInfo = nil;
        _numCPUInfo = 0U;
    } else {
        PYLog(@"Error!");
    }
    return _cpuInfoArray;
}

BOOL __isJailBroken()
{
    BOOL _isJailBroken = NO;
    if ( [[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Cydia.app"] ) {
        _isJailBroken = YES;
    }
    if ( [[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/lib/apt"] ) {
        _isJailBroken = YES;
    }
    return _isJailBroken;
}

NSString *__getMACAddress()
{
    int                 mib[] = {CTL_NET, AF_ROUTE, 0, AF_LINK, NET_RT_IFLIST, if_nametoindex("en0")};
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;
    
    if ( mib[5] == 0 ) {
        ALog(@"Error: if_nametoindex error");
        return __guid();
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        ALog(@"Error: sysctl, take 1");
        return __guid();
    }
    
    if ( (buf = malloc(len)) == NULL ) {
        ALog(@"Error: Failed to allocate memory.");
        return __guid();
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        ALog(@"Error: sysctl, take 2");
        free(buf);
        return __guid();
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *_mac = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                      *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    return _mac;
}

NSString *__getDeviceModal()
{
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

NSData *__reloadDeviceList()
{
    NSData *_deviceData = [NSData dataWithContentsOfURL:
                           [NSURL URLWithString:
                            @"https://raw.githubusercontent.com/littlepush/PYCore/master/static-library/devicelist.json"]];
    [_deviceData writeToFile:[PYDOCUMENTPATH stringByAppendingPathComponent:@"devicelist.json"]
                  atomically:YES];
    return _deviceData;
    
}

NSDictionary *__initDeviceCache() {
    static NSDictionary *_dcache = nil;
    if ( _dcache == nil ) {
        NSFileManager* _fm = [NSFileManager defaultManager];
        NSString *_localFile = [PYDOCUMENTPATH stringByAppendingPathComponent:@"devicelist.json"];
        NSData *_localData = nil;
        
        if ( ![_fm fileExistsAtPath:_localFile] ) {
            // Read from bundle
            _localFile = [[NSBundle mainBundle] pathForResource:@"devicelist" ofType:@"json"];
        }
        
        _localData = [NSData dataWithContentsOfFile:_localFile];
        NSError *_error = nil;
        id _dlist = [NSJSONSerialization
                     JSONObjectWithData:_localData
                     options:NSJSONReadingAllowFragments
                     error:&_error];
        if ( _error == nil ) {
            _dcache = [NSDictionary object];
            for ( NSDictionary *_dinfo in _dlist ) {
                [_dcache setValue:_dinfo forKey:[_dinfo stringObjectForKey:@"identifier"]];
            }
        }
        // Async to update the device list
        BEGIN_ASYNC_INVOKE
        __reloadDeviceList();
        END_ASYNC_INVOKE
    }
    return _dcache;
}
/*
 Get current device's model name.
 */
NSString *__currentDeviceModelName() {
    NSDictionary *_dcache = __initDeviceCache();
    id _dinfo = [_dcache objectForKey:__getDeviceModal()];
    if ( _dinfo == nil ) return @"UnKnow Device";
    return [_dinfo stringObjectForKey:@"device"];
}
/*
 Get current device's display name.
 */
NSString *__currentDeviceName() {
    NSDictionary *_dcache = __initDeviceCache();
    id _dinfo = [_dcache objectForKey:__getDeviceModal()];
    if ( _dinfo == nil ) return @"UnKnow Device";
    return [_dinfo stringObjectForKey:@"name"];
}

unsigned long long __getFreeSpace()
{
    NSFileManager *_fm = [NSFileManager defaultManager];
    NSError *_error = nil;
    NSDictionary *_fsAttr = [_fm attributesOfFileSystemForPath:NSHomeDirectory()
                                                         error:&_error];
    if ( _error != nil ) {
        PYLog(@"Get Free Space Error: %@", _error.localizedDescription);
        return 0;
    }
    unsigned long long _freeSpace = [[_fsAttr objectForKey:NSFileSystemFreeSize]
                                     unsignedLongLongValue];
    return _freeSpace;
}

NSString *__bytesToHumanReadableString(unsigned long long bytes)
{
    if ( bytes < PYKiloByte ) return [NSString stringWithFormat:@"%lluB", bytes];
    if ( bytes < PYMegaByte ) return [NSString stringWithFormat:@"%.2fKB", bytes / (float)PYKiloByte];
    if ( bytes < PYGigaByte ) return [NSString stringWithFormat:@"%.2fMB", bytes / (float)PYMegaByte];
    return [NSString stringWithFormat:@"%.2fGB", bytes / (float)PYGigaByte];
}

BOOL __skipFileFromiCloudBackup(NSURL *url)
{
    if ( SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"5.0") ) {
        return NO;
    }
    
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:[url path]] ) return NO;
    if ( SYSTEM_VERSION_LESS_THAN(@"5.1") ) {
        const char *filePath = [[url path] fileSystemRepresentation];
        const char *attrName = "com.apple.MobileBackup";
        u_int8_t attrValue = 1;
        
        int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
        return result == 0;
    } else {
        NSError *error = nil;
        BOOL success = [url setResourceValue:PYBoolToObject(YES)
                                      forKey:NSURLIsExcludedFromBackupKey
                                       error:&error];
        if ( !success ) {
            PYLog(@"Error excluding %@ from backup %@", [url lastPathComponent], error);
        }
        return success;
    }
}

// clean the console output.
typedef int (*PYStdWriter)(void *, const char *, int);
static PYStdWriter _oldStdWrite;

int __pyStderrWrite(void *inFD, const char *buffer, int size)
{
    if ( strncmp(buffer, "AssertMacros:", 13) == 0 ) {
        return 0;
    }
    return _oldStdWrite(inFD, buffer, size);
}

void __iOS7B5CleanConsoleOutput(void)
{
    _oldStdWrite = stderr->_write;
    stderr->_write = __pyStderrWrite;
}

// @littlepush
// littlepush@gmail.com
// PYLab
