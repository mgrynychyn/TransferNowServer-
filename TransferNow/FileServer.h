//
//  FileServer.h
//  LittleServer
//
//  Created by Maria Grynychyn on 1/27/15.
//  Copyright (c) 2015 Maria Grynychyn. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FileServerDelegate;

@interface FileServer : NSObject

- (id)init;


// properties you can configure at any time

@property (nonatomic, weak,   readwrite) id<FileServerDelegate>    delegate;
@property NSString *clientName;
// properties that change as the result of other actions

#pragma mark * Start and Stop

// It is reasonable to start and stop the same server object multiple times.

- (void)start;
// Starts the server.  It's not legal to call this if the server is started.
// If startup attempted, will eventually call -serverDidStart: or
// -server:didStopWithError:.

- (void)stop;
// Does nothing if the server is already stopped.
// This does not call -server:didStopWithError:.
// This /does/ call -server:didStopConnection: for each running connection.

@property (nonatomic, assign, readonly, getter=isStarted) BOOL  started;        // observable
@property (nonatomic, assign, readonly ) NSUInteger             registeredPort;

@property (nonatomic, strong, readwrite) NSInputStream *        inputStream;
@property (nonatomic, strong, readwrite) NSOutputStream *       outputStream;
// may change due to Bonjour auto renaming,
// will be nil if Bonjour registration not requested,
// may be nil if Bonjour registration in progress

// These two methods let you temporarily deregister the server with Bonjour and then
// reregister it again.  This is needed for WiTap, which wants to leave the server
// listening at the TCP level (to avoid the port number creeping up) but wants it
// to disappear from Bonjour.



@property (nonatomic, assign,   readonly ) BOOL                 isDeregistered;
// Returns YES if the server has been deregistered (that is, if the server
// was configured to user Bonjour but there's no registration in place or
// in progress).

// Called to log server activity.
//- (void) writeToLogFile:(NSString *)message;

//Called when the "server" shut down
- (void) closeStreams;

#pragma mark * Connections


@property (nonatomic, copy,   readonly ) NSSet *                connections;

@end


@protocol FileServerDelegate <NSObject, NSStreamDelegate>

- (void) didRemoveService;
@optional



- (void)serverDidStart:(FileServer *)server;
// Called after the server has fully started, that is, once the Bonjour name
// registration (if requested) is complete.  You can use registeredName to get
// the actual service name that was registered.

- (void)server:(FileServer *)server didStopWithError:(NSError *)error;
// Called when the server stops of its own accord, typically in response to some
// horrible network problem.

// You should implement one and only one of the following callbacks.  If you implement
// both, -server:connectionForSocket: is called.

- (id)server:(FileServer *)server connectionForSocket:(int)fd;
// Called to get a connection object for a new, incoming connection.  If you don't implement
// this, or you return nil, the socket for the connection is just closed.  If you do return
// a connection object, you are responsible for holding on to socket and ensuring that it's
// closed on the -server:closeConnection: delegate callback.

- (id)server:(FileServer *)server connectionForInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;
// Called to get a connection object for a new, incoming connection.  If you don't implement
// this, or you return nil, the incoming connection is just closed.  If you do return a
// connection object, you are responsible for opening the two streams (or just one of the
// streams, if you only need one), holding on to them, and ensuring that they are closed
// and released on the -server:closeConnection delegate callback.

- (void)server:(FileServer *)server closeConnection:(id)connection;
// Called when the server shuts down or if someone calls -closeAllConnections.
// Typically the delegate would just forward this call to the connection object itself.



@end
