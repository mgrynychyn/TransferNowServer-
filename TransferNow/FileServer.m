//
//  FileServer.m
//  LittleServer
//
//  Created by Maria Grynychyn on 1/27/15.
//  Copyright (c) 2015 Maria Grynychyn. All rights reserved.
//

#import "FileServer.h"
/*
#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>
*/
static NSString * kBonjourType = @"_bft._tcp.";
static NSString * kDomain = @"local";
static NSString * kConnected = @"Client connected to server";
static NSUInteger preferredPort=50217;
//static NSUInteger preferredPort=49978;

@interface FileServer () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property (nonatomic, assign, readwrite) NSUInteger             registeredPort;
@property (nonatomic, copy,   readwrite) NSString *             registeredName;

// private properties

@property (nonatomic, strong, readwrite) NSNetService *         netService;


// forward declarations



@end

@implementation FileServer{
    // For debugging only
     NSMutableArray *messages;
    
}

- (id)init{
    
    self = [super init];
    if (self != nil) {
        
        
    }
    return self;

}

- (void)start
// See comment in header.
{
    
    self.netService = [[NSNetService alloc] initWithDomain:kDomain
                                                      type:kBonjourType
                                                      name:@""
                                                      port:(int)preferredPort];
    self.netService.includesPeerToPeer=YES;
    assert(self.netService != nil);
    
    
    [self.netService setDelegate:self];

    
    [self.netService publishWithOptions:NSNetServiceListenForConnections];
    
    
    
}


#pragma mark * "NetService" delegate

- (void)netService:(NSNetService *)sender didAcceptConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    if((self.inputStream!=nil && self.inputStream.streamStatus==NSStreamStatusOpen)||(self.outputStream!=nil &&self.outputStream.streamStatus==NSStreamStatusOpen)){
        [self closeStreams];
        [self.delegate didRemoveService];
    }
    
    self.inputStream=inputStream;
    self.outputStream=outputStream;
         [self openStreams];}];
    
}





- (void)stop
// See comment in header.
{
    
       
        [self deregister];
        // Close down the listening sockets.
        
        
        //Added
        [self closeStreams];
        
    
}

- (void)deregister
// See comments in header.
{
    if (self.netService != nil) {
        [self.netService setDelegate:nil];
        [self.netService stop];
        // Don't need to call -removeFromRunLoop:forMode: because -stop takes care of that.
        self.netService = nil;
    }
    if (self.registeredName != nil) {
        self.registeredName = nil;
    }
}


- (void)openStreams
{
    assert(self.inputStream != nil);            // streams must exist but aren't open
    assert(self.outputStream != nil);
    
    [self.inputStream  setDelegate:self.delegate];
    [self.inputStream  scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream  open];
    
    [self.outputStream setDelegate:self.delegate];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream open];
}

- (void)closeStreams
{
    assert( (self.inputStream != nil) == (self.outputStream != nil) );      // should either have both or neither
    if (self.inputStream != nil) {
        
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.inputStream close];
        self.inputStream = nil;
        
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream close];
        self.outputStream = nil;
    }
    
}


@end
