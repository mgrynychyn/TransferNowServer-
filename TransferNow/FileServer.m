//
//  FileServer.m
//  LittleServer
//
//  Created by Maria Grynychyn on 1/27/15.
//  Copyright (c) 2015 Maria Grynychyn. All rights reserved.
//

#import "FileServer.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>

static NSString * kBonjourType = @"_bft._tcp.";
static NSString * kDomain = @"local.";
static NSString * kConnected = @"Client connected to server";
static NSUInteger preferredPort=50217;
//static NSUInteger preferredPort=49978;
@interface FileServer () <NSNetServiceDelegate>

@property (nonatomic, assign, readwrite) NSUInteger             connectionSequenceNumber;

@property (nonatomic, assign, readwrite) NSUInteger             registeredPort;
@property (nonatomic, copy,   readwrite) NSString *             registeredName;

@property (nonatomic, strong, readonly ) NSMutableSet *         connectionsMutable;
@property (nonatomic, strong, readwrite) NSMutableSet *         runLoopModesMutable;

// private properties

@property (nonatomic, strong, readonly ) NSMutableSet *         listeningSockets;
@property (nonatomic, strong, readwrite) NSNetService *         netService;


// forward declarations

static void ListeningSocketCallback(CFSocketRef sock, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

- (void)connectionAcceptedWithSocket:(int)fd;

@end

@implementation FileServer{
    // For debugging only
     NSMutableArray *messages;
}

- (id)init{
    
    self = [super init];
    if (self != nil) {
        
        self->_connectionsMutable = [[NSMutableSet alloc] init];
        assert(self.connectionsMutable != nil);
        self.runLoopModesMutable = [[NSMutableSet alloc] initWithObjects:NSDefaultRunLoopMode, nil];
        assert(self->_runLoopModesMutable != nil);
        self->_listeningSockets = [[NSMutableSet alloc] init];
        assert(self->_listeningSockets != nil);
       
    }
    return self;

}

- (void)start

{
    NSUInteger  port;
    NSError *   error;
    
   if(self.isStarted )
       return;
  
//    [self logWithFormat :@"Starting"];
    port = [self listenOnPortError:&error];
    
    // Kick off the next stage of the startup, if required, namely the Bonjour registration.
    
    if (port != 0) {
        
//        [self logWithFormat :@"Server started on port %zu.", (size_t) port];
//        [self writeToLogFile:[NSString stringWithFormat:@"Server started on port %u.", (uint) port]];
        NSLog(@"Started server on port %zu.", (size_t) port);
       
        self.registeredPort = port;
        
    // Startup has succeeded so far.  Let's start the Bonjour registration.
            
        [self registerService];
        
    }
}

- (NSUInteger)listenOnPortError:(NSError **)errorPtr
// See comment in header.
{
    int         err;
    int         fd4;
    int         fd6;
    BOOL        retry;
    NSUInteger  retryCount;
   
    NSUInteger  boundPort;
    
    // errorPtr may be nil
    // initial value of *errorPtr undefined
    
    boundPort = 0;
    fd4 = -1;
    fd6 = -1;
    retryCount = 0;
    
    do {
        
        retry = NO;
        
        // Create our sockets.  We have to do this inside the loop because BSD Sockets
        // doesn't support unbind (bring back Open Transport!) and we may need to unbind
        // when retrying.
        
        err = 0;
        fd4 = socket(AF_INET, SOCK_STREAM, 0);
        if (fd4 < 0) {
            err = errno;
            assert(err != 0);
        }
        if ( err == 0) {
            fd6 = socket(AF_INET6, SOCK_STREAM, 0);
            if (fd6 < 0) {
                err = errno;
                assert(err != 0);
            }
            if (err == EAFNOSUPPORT) {
                // No IPv6 support.  Leave fd6 set to -1.
                assert(fd6 == -1);
                err = 0;
            }
        }
        
        // Bind the IPv4 socket to the specified port (may be 0).
        
        if (err == 0) {
         //   err = [self bindSocket:fd4 toPort:0 inAddressFamily:AF_INET];
            err = [self bindSocket:fd4 toPort:preferredPort inAddressFamily:AF_INET];
            
            if ( (err == EADDRINUSE) && (preferredPort != 0) && (retryCount < 15) ) {
                if(retryCount<3)
                    preferredPort++;
                else
                    preferredPort = 0;
                
                retryCount += 1;
                retry = YES;
            }
            
        }
        if (err == 0) {
            err = [self listenOnSocket:fd4];
        }
        
        // Figure out what port we actually bound too.
        
        if (err == 0) {
            err = [self boundPort:&boundPort forSocket:fd4];
        }
        
        // Try to bind the IPv6 socket, if any, to that port.
        
        if ( (err == 0) && (fd6 != -1) ) {
            
            // Have the IPv6 socket only bind to the IPv6 address.  Without this the IPv6 socket
            // binds to dual mode address (reported by netstat as "tcp46") and that prevents a
            // second instance of the code getting the EADDRINUSE error on the IPv4 bind, which is
            // the place we're expecting it, and where we recover from it.
            
            err = [self setOption:IPV6_V6ONLY atLevel:IPPROTO_IPV6 onSocket:fd6];
            
            if (err == 0) {
                assert(boundPort != 0);
                err = [self bindSocket:fd6 toPort:boundPort inAddressFamily:AF_INET6];
                
                if ( (err == EADDRINUSE) && (retryCount < 15) ) {
                    // If the IPv6 socket's bind failed and we are trying to bind
                    // to an anonymous port, try again.  This protects us from the
                    // race condition where we bind IPv4 to a port then, before we can
                    // bind IPv6 to the same port, someone else binds their own IPv6
                    // to that port (or vice versa).  We also limit the number of retries
                    // to guarantee we don't loop forever in some pathological case.
                    
                    retryCount += 1;
                    retry = YES;
                }
                
                if (err == 0) {
                    err = [self listenOnSocket:fd6];
                }
            }
        }
        
        // If something went wrong, close down our sockets.
        
        if (err != 0) {
            [self closeSocket:fd4];
            [self closeSocket:fd6];
            fd4 = -1;
            fd6 = -1;
            boundPort = 0;
        }
    } while ( (err != 0) && retry );
    
    assert( (err == 0) == (fd4 != -1) );
    assert( (err == 0) || (fd6 == -1) );
    // On success, fd6 might still be 0, implying that IPv6 is not available.
    assert( (err == 0) == (boundPort != 0) );
    
    // Add the sockets to the run loop.
    
    if (err == 0) {
        [self addListeningSocket:fd4];
        if (fd6 != -1) {
            [self addListeningSocket:fd6];
        }
    }
    
    // Clean up.
    
    // There's no need to clean up fd4 and fd6.  We are either successful,
    // in which case they are now owned by the CFSockets in the listeningSocket
    // set, or we failed, in which case they were cleaned up on the way out
    // of the do..while loop.
    if (err != 0) {
        if (errorPtr != NULL) {
            *errorPtr = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
        }
        assert(boundPort == 0);
    }
    assert( (err == 0) == (boundPort != 0) );
    assert( (err == 0) || ( (errorPtr == NULL) || (*errorPtr != nil) ) );
    
    return boundPort;
}

- (BOOL)isStarted
{
    return self.registeredPort != 0;
}

- (void)registerService

{
    
    assert(self.isStarted);             // must be running
    assert(self.netService == nil);     // but not registered
    
    assert(self.registeredPort < 65536);
    self.netService = [[NSNetService alloc] initWithDomain:kDomain
                                                      type:kBonjourType
                                                      name:@""
                                                      port:(int)self.registeredPort];
    assert(self.netService != nil);
    
    for (NSString * mode in self.runLoopModesMutable) {
        [self.netService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
    }
    [self.netService setDelegate:self];
    [self.netService publishWithOptions:0];
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
    assert(sender == self.netService);
}

- (int)bindSocket:(int)fd toPort:(NSUInteger)port inAddressFamily:(sa_family_t)addressFamily
// Wrapper for bind, including a SO_REUSEADDR setsockopt.
{
    int                     err;
    struct sockaddr_storage addr;
    struct sockaddr_in *    addr4Ptr;
    struct sockaddr_in6 *   addr6Ptr;
    
    assert(fd >= 0);
    assert(port < 65536);
    
    err = 0;
    if (port != 0) {
        err = [self setOption:SO_REUSEADDR atLevel:SOL_SOCKET onSocket:fd];
    }
    if (err == 0) {
        memset(&addr, 0, sizeof(addr));
        addr.ss_family = addressFamily;
        if (addressFamily == AF_INET) {
            addr4Ptr = (struct sockaddr_in *) &addr;
            addr4Ptr->sin_len  = sizeof(*addr4Ptr);
            addr4Ptr->sin_port = htons(port);
        } else {
            assert(addressFamily == AF_INET6);
            addr6Ptr = (struct sockaddr_in6 *) &addr;
            addr6Ptr->sin6_len  = sizeof(*addr6Ptr);
            addr6Ptr->sin6_port = htons(port);
        }
        err = bind(fd, (const struct sockaddr *) &addr, addr.ss_len);
        if (err < 0) {
            err = errno;
            assert(err != 0);
        }
    }
    return err;
}

- (int)listenOnSocket:(int)fd
// Wrapper for listen.
{
    int     err;
    
    assert(fd >= 0);
    
    err = listen(fd, 5);
    if (err < 0) {
        err = errno;
        assert(err != 0);
    }
    return err;
}

- (void)closeSocket:(int)fd
// Wrapper for close.
{
    int     junk;
    
    if (fd != -1) {
        assert(fd >= 0);
        junk = close(fd);
        assert(junk == 0);
    }
}

- (int)boundPort:(NSUInteger *)portPtr forSocket:(int)fd
// Wrapper for getsockname.
{
    int                     err;
    struct sockaddr_storage addr;
    socklen_t               addrLen;
    
    assert(fd >= 0);
    assert(portPtr != NULL);
    
    addrLen = sizeof(addr);
    err = getsockname(fd, (struct sockaddr *) &addr, &addrLen);
    if (err < 0) {
        err = errno;
        assert(err != 0);
    } else {
        if (addr.ss_family == AF_INET) {
            assert(addrLen == sizeof(struct sockaddr_in));
            *portPtr = ntohs(((const struct sockaddr_in *) &addr)->sin_port);
        } else {
            assert(addr.ss_family == AF_INET6);
            assert(addrLen == sizeof(struct sockaddr_in6));
            *portPtr = ntohs(((const struct sockaddr_in6 *) &addr)->sin6_port);
        }
    }
    return err;
}

- (int)setOption:(int)option atLevel:(int)level onSocket:(int)fd
// Wrapper for setsockopt.
{
    int     err;
    static const int kOne = 1;
    
    assert(fd >= 0);
    
    err = setsockopt(fd, level, option, &kOne, sizeof(kOne));
    if (err < 0) {
        err = errno;
        assert(err != 0);
    }
    return err;
}

- (void)addListeningSocket:(int)fd
// See comment in header.
{
    CFSocketContext     context = { 0, (__bridge void *)(self), NULL, NULL, NULL };
    CFSocketRef         sock;
    CFRunLoopSourceRef  rls;
    
    assert(fd >= 0);
    
    sock = CFSocketCreateWithNative(NULL, fd, kCFSocketAcceptCallBack, ListeningSocketCallback, &context);
    if (sock != NULL) {
        assert( CFSocketGetSocketFlags(sock) & kCFSocketCloseOnInvalidate );
        rls = CFSocketCreateRunLoopSource(NULL, sock, 0);
        assert(rls != NULL);
        
        for (NSString * mode in self.runLoopModesMutable) {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, (__bridge CFStringRef) mode);
        }
        
        CFRelease(rls);
        CFRelease(sock);
        
        [self.listeningSockets addObject:(__bridge id)sock];
    }
}

static void ListeningSocketCallback(CFSocketRef sock, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)

{
    FileServer *   obj;
    int         fd;
    
    obj = (__bridge FileServer *) info;
    assert([obj isKindOfClass:[FileServer class]]);
    
    assert([obj.listeningSockets containsObject:(__bridge id) sock]);
   NSLog (@"ListeningSocketCallback");
#pragma unused(sock)
    assert(type == kCFSocketAcceptCallBack);
#pragma unused(type)
    assert(address != NULL);
#pragma unused(address)
    assert(data != nil);
    
    fd = * (const int *) data;
    assert(fd >= 0);
    
   
    [obj connectionAcceptedWithSocket:fd];
}

- (id)connectionForSocket:(int)fd
{
    
    assert(fd >= 0);
    
   
        BOOL                success;
        CFReadStreamRef     readStream;
        CFWriteStreamRef    writeStream;
        NSInputStream *     inputStream;
        NSOutputStream *    outputStream;
        
        CFStreamCreatePairWithSocket(NULL, fd, &readStream, &writeStream);
        
        inputStream  = CFBridgingRelease( readStream  );
        outputStream = CFBridgingRelease( writeStream );
        
        assert( (__bridge CFBooleanRef) [ inputStream propertyForKey:(__bridge NSString *)kCFStreamPropertyShouldCloseNativeSocket] == kCFBooleanFalse );
        assert( (__bridge CFBooleanRef) [outputStream propertyForKey:(__bridge NSString *)kCFStreamPropertyShouldCloseNativeSocket] == kCFBooleanFalse );
        
 //       connection = [self.delegate server:self connectionForInputStream:inputStream outputStream:outputStream];
 //       connection=[[MGStreams alloc] initWithStreams:inputStream outputStream:outputStream];
 //       [connection setDelegate:self];
    
        // If the client accepted this connection, we have to flip kCFStreamPropertyShouldCloseNativeSocket
        // to true so the client streams close the socket when they're done.  OTOH, if the client denies
        // the connection, we leave kCFStreamPropertyShouldCloseNativeSocket as false because our caller
        // is going to close the socket in that case.
    
    //In case an error occurred on network and we are connected twice
    if((self.inputStream!=nil && self.inputStream.streamStatus==NSStreamStatusOpen)||(self.outputStream!=nil &&self.outputStream.streamStatus==NSStreamStatusOpen)){
            [self closeStreams];
            [self.delegate didRemoveService];
    }
    
        self.inputStream=inputStream;
        self.outputStream=outputStream;
        [self openStreams];
   //         if (connection != nil) {
            success = [inputStream setProperty:(id)kCFBooleanTrue forKey:(__bridge NSString *)kCFStreamPropertyShouldCloseNativeSocket];
            assert(success);
            assert( (__bridge CFBooleanRef) [outputStream propertyForKey:(__bridge NSString *)kCFStreamPropertyShouldCloseNativeSocket] == kCFBooleanTrue );
   //     }
    //Added
  //      [self deregister];
        NSLog(@"%@",kConnected);
    //    [self writeToLogFile:kConnected];
    
    return self;
}

- (void)connectionAcceptedWithSocket:(int)fd
// Called when we receive a connection on one of our listening sockets.  We
// call our delegate to create a connection object for this connection and,
// if that succeeds, add it to our connections set.
{
    int         junk;
    id          connection;
    
    assert(fd >= 0);
    
    connection = [self connectionForSocket:fd];
    self.connectionSequenceNumber += 1;
    if (connection != nil) {
        NSLog(@"start connection %p for socket %d", connection,fd);
        [self.connectionsMutable addObject:connection];
    } else {
        junk = close(fd);
        assert(junk == 0);
    }
}


- (void)stop
// See comment in header.
{
    if ( self.isStarted ) {
        
       
        [self deregister];
        // Close down the listening sockets.
        
        for (id s in self.listeningSockets) {
            CFSocketRef sock;
            
            sock = (__bridge CFSocketRef) s;
            assert( CFGetTypeID(sock) == CFSocketGetTypeID() );
            CFSocketInvalidate(sock);
        }
        [self.listeningSockets removeAllObjects];
        
        self.registeredPort = 0;
        
        //Added
        [self closeStreams];
        
    }
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

- (void) terminate{
    [self stop];
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
