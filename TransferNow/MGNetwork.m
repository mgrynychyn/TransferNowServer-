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
    NSMutableArray *messages;
    BOOL resolved;
   
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
        //    [self closeStreams];
            [self.delegate didRemoveService];
            [self startOver];
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
    
    NSLog(@"Did find a service");
    
    
    if ( ! moreComing )
    {
        resolved=NO;

 //      [self.netService setDelegate:self];
 //       [self.netService resolveWithTimeout:5.0];
        [self connectToService:self.netService];
 //       [self.delegate didFindService:self.netService];
    }
}


- (void) timeOver:(NSTimer *)timer{
    
    [self writeToLogFile:[NSString stringWithFormat:@"Time over"]];
    NSLog (@"Time over");
    
    if(self.inputStream.streamStatus!=NSStreamStatusOpen && self.outputStream.streamStatus!=NSStreamStatusOpen)
    {
        
        [self startOver];
    }
    
    return;
    
   
}
//NSNeteServiceDelegate
- (void)netServiceDidResolveAddress:(NSNetService *)netService
{
    if(!resolved){
        [self connectToService:self.netService];
        resolved=YES;
        
    }
    [self writeToLogFile:[NSString stringWithFormat:@"Did resolve the address %@",((NSData *)netService.addresses[0]).description]];
        NSLog (@"Did resolve the address %@",((NSData *)netService.addresses[0]).description);
    if(netService.addresses!=nil)
        NSLog(@"Addresses count %lu",(unsigned long)netService.addresses.count);
    
}



- (void) startOver{
    
    if(self.netService!=nil){
        self.netService=nil;
        [self stopBrowser];
        //       [self.delegate didRemoveService];
        
        [self startBrowser];
        
    }

    
}

- (void)netService:(NSNetService *)netService didNotResolve:(NSDictionary *)errorDict{
    
       [ self writeToLogFile:[NSString stringWithFormat:@"Did not resolve the address %@",errorDict.allKeys]];
    NSLog (@"Did not resolve the address %@",errorDict.allKeys);
    NSLog (@"Did not resolve the address %@",errorDict.allValues);
    
    [self startOver];
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
 //       [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(timeOver:) userInfo:nil repeats:NO];
        
        self.inputStream  = inStream;
        self.outputStream = outStream;
       
        [self openStreams];
         NSLog(@"Connected with stream status input: %lu output: %lu",(unsigned long)self.inputStream.streamStatus,(unsigned long)self.outputStream.streamStatus);
        [self writeToLogFile:[NSString stringWithFormat:@"Connected with stream status input: %lu output: %lu",(unsigned long)self.inputStream.streamStatus,(unsigned long)self.outputStream.streamStatus]];
        
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

- (void) writeToLogFile:(NSString *)message{
    
    NSFileCoordinator *  coordinator=[[NSFileCoordinator alloc] init];
   
    NSError *error=nil;
    NSURL *logFile=[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject]  URLByAppendingPathComponent:@"LogFile.property"];
    
    [coordinator coordinateReadingItemAtURL:logFile options:0  error:&error byAccessor:^(NSURL *newUrl){
       NSMutableArray * array=[[NSMutableArray alloc] initWithArray:[NSArray arrayWithContentsOfURL:newUrl]];
        messages=array;
    }];
    
     NSString * newMessage=[[self formatter] stringFromDate:[NSDate date]];
    [messages addObject:newMessage];
    [messages addObject:message];
    [coordinator coordinateWritingItemAtURL:logFile options:NSFileCoordinatorWritingForMerging error:&error byAccessor:^(NSURL *newURL) {
        [messages  writeToURL:logFile atomically:NO];
    }];

}

- (NSDateFormatter *) formatter{
    
    NSDateFormatter *formatter=[[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss "];
    return formatter;
}

@end
