//
//  MGNetwork.m
//  TransferNow
//
//  Created by Maria Grynychyn on 2/27/15.
//  Copyright (c) 2015 Maria Grynychyn. All rights reserved.
//

#import "MGNetwork.h"
#import <sys/types.h>
#import <dispatch/dispatch.h>
#import <stdint.h>


static NSString * bonjourType = @"_bft._tcp.";
typedef int32_t DNSServiceErrorType;

@interface MGNetwork() <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@end

@implementation MGNetwork{
    NSNetService *unconfirmed;
}


+ (id)network{
    
    return [[MGNetwork alloc] init];;
    
}
- (void)startBrowser
// See comment in header.
{
    
    self.browser = [[NSNetServiceBrowser alloc] init];
    NSLog(@"Browser started");
    [self.browser setDelegate:self];
    [self.browser searchForServicesOfType:bonjourType inDomain:@"local"];
  
    
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    assert(browser == self.browser);
    NSLog(@"Removed service");
    assert(service != nil);
//    if ((self.netService!=nil) && [service isEqual:self.netService]){
//        self.netService=nil;
        if ( ! moreComing ){
            [self closeStreams];
            [self.delegate didRemoveService];
        }
//    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
//   if(self.netService!=nil)
//        return;
    assert(service!=nil);
    // Add the service to our array (unless its our own service).
    self.netService=service;
    
//    [self.netService setDelegate:self];
//    [self.netService resolveWithTimeout:5.0];
    NSLog(@"Did find a service");
    if ( ! moreComing )
    {
        [self connectToService:self.netService];
 //       [self.delegate didFindService:self.netService];
    }
}


//NSNeteServiceDelegate
- (void)netServiceDidResolveAddress:(NSNetService *)netService
{
    static NSUInteger count=0;
//    if(unconfirmed ==nil && self.netService==nil)
//        return;
//    if(self.netService==nil){
//        self.netService=unconfirmed;
//        unconfirmed=nil;
    if(count !=0){
        count=0;
        return;
    }
    count++;
    [self connectToService:self.netService];
//    [self.delegate didFindService:self.netService];
//        self.netService=nil;
//    }
//    [self connectWithName:netService.hostName port:netService.port];
     NSLog (@"Did resolve the address %@",netService.hostName);
    NSLog (@"Did resolve the address %@",((NSData *)netService.addresses[0]).description);
}

- (void) connectWithName:(NSString *)name port:(NSUInteger) port{
    NSString *urlString=[NSString stringWithFormat:@"bft://%@:%lu/'A'",name,(unsigned long)port];
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:6.0];
    NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (!theConnection) {
        NSLog(@"Connection failed");
    }
}
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    
    
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"Connection received response!");
}


- (void)netService:(NSNetService *)netService didNotResolve:(NSDictionary *)errorDict{
    
    if(self.netService!=nil){
        self.netService=nil;
        [self stopBrowser];
        [self.delegate didRemoveService];
        
        [self startBrowser];

    }
    
    NSLog (@"Did not resolve the address %@",errorDict.allKeys);
    NSLog (@"Did not resolve the address %@",errorDict.allValues);
}
- (void)stopBrowser
// See comment in header.
{
    [self.browser stop];
    
    self.browser = nil;
//    self.netService=nil;
    [self closeStreams];
    
}

- (void)connectToService:(NSNetService *)service
{
    BOOL                success;
    NSInputStream *     inStream;
    NSOutputStream *    outStream;
    
    assert(service != nil);
    
    assert(self.inputStream == nil);
    assert(self.outputStream == nil);
    
    success = [service getInputStream:&inStream outputStream:&outStream];
    if (  success ) {
        
        self.inputStream  = inStream;
        self.outputStream = outStream;
       
        [self openStreams];
//         NSLog(@"Connected with stream status input: %lu output: %lu",self.inputStream.streamStatus,self.outputStream.streamStatus);
        
    }
}

- (void)openStreams
{
    assert(self.inputStream != nil);            // streams must exist but aren't open
    assert(self.outputStream != nil);
    
    [self.inputStream  setDelegate:self.streamDelegate];
    [self.inputStream  scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream  open];
    
    [self.outputStream setDelegate:self.streamDelegate];
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
