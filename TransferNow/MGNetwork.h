//
//  MGNetwork.h
//  TransferNow
//
//  Created by Maria Grynychyn on 2/27/15.
//  Copyright (c) 2015 Maria Grynychyn. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol MGNetworkDelegate;

@interface MGNetwork : NSObject

@property (nonatomic, strong, readwrite) NSInputStream *        inputStream;
@property (nonatomic, strong, readwrite) NSOutputStream *       outputStream;
@property (nonatomic, weak, readwrite) id<MGNetworkDelegate>    delegate;
@property (nonatomic, weak, readwrite) id<NSStreamDelegate>    streamDelegate;
@property (nonatomic, strong, readwrite) NSNetService *netService;

@property (nonatomic, strong, readwrite) NSNetServiceBrowser *  browser;

//- (id)initWithStreams:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;
- (void)openStreams;
- (void)closeStreams;
- (void) startBrowser;
- (void)stopBrowser;
+ (id)network;

- (void) writeToLogFile:(NSString *)message;
- (void) startOver;
@end

@protocol MGNetworkDelegate

//-(void) didFindService:(NSNetService *)service;
-(void) didRemoveService;
@end