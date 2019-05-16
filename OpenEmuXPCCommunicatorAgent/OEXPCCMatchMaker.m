/*
 Copyright (c) 2013, OpenEmu Team

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
     * Neither the name of the OpenEmu Team nor the
       names of its contributors may be used to endorse or promote products
       derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "OEXPCCMatchMaker.h"
#import <os/log.h>

@interface OEXPCCMatchMakerClient: NSObject
+ (instancetype)matchMakerClientWithPid:(int)pid handler:(void (^)(NSXPCListenerEndpoint *))handler;
@property(readonly) int pid;
@property(readonly, copy) void(^handler)(NSXPCListenerEndpoint *endpoint);
@end


@interface OEXPCCMatchMakerListener : NSObject
+ (instancetype)matchMakerListenerWithEndpoint:(NSXPCListenerEndpoint *)endpoint pid:(int)pid handler:(void(^)(BOOL success))handler;
@property(readonly) NSXPCListenerEndpoint *endpoint;
@property(readonly) int pid;
@property(readonly, copy) void(^handler)(BOOL success);
@end

@interface OEXPCCMatchMaker () <OEXPCCMatchMaking, NSXPCListenerDelegate>
{
    NSString            *_serviceName;
    NSXPCListener       *_serviceListener;

    dispatch_queue_t     _listenerQueue;
    NSMutableDictionary *_pendingListeners;
    NSMutableDictionary *_pendingClients;
}

@end

@implementation OEXPCCMatchMaker

- (id)initWithServiceName:(NSString *)serviceName
{
    if((self = [super init]))
    {
        _serviceName      = [serviceName copy];
        os_log(OS_LOG_DEFAULT, "OEXPCCMatchMaker serviceName: %{public}@", _serviceName);
        
        _serviceListener  = [[NSXPCListener alloc] initWithMachServiceName:_serviceName];
        [_serviceListener setDelegate:self];

        _listenerQueue    = dispatch_queue_create("com.psychoinc.MatchMaker.ListenerQueue", DISPATCH_QUEUE_SERIAL);
        _pendingClients   = [NSMutableDictionary dictionary];
        _pendingListeners = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)resumeConnection
{
    [_serviceListener resume];
    [[NSRunLoop currentRunLoop] run];
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    [newConnection setExportedInterface:[NSXPCInterface interfaceWithProtocol:@protocol(OEXPCCMatchMaking)]];
    [newConnection setExportedObject:self];
    [newConnection resume];

    return YES;
}

- (void)retrieveClientPidForIdentifier:(nonnull NSString *)identifier completionHandler:(void(^)(int pid))handler
{
    dispatch_async(_listenerQueue, ^{
        os_log(OS_LOG_DEFAULT, "retrieveClientPid foridentifier: %{public}@...", identifier);
        os_log(OS_LOG_DEFAULT, "_pendingClients: %{public}@", [_pendingClients allKeys]);
        
        OEXPCCMatchMakerClient *client = _pendingClients[identifier];
        
        if(client == nil)
        {
            handler(-1);
            return;
        }
        
        os_log(OS_LOG_DEFAULT, "returning pid: %{public}d...", [client pid]);
        handler([client pid]);
    });
}

- (void)retrieveListenerPidForIdentifier:(nonnull NSString *)identifier completionHandler:(void(^)(int pid))handler
{
    dispatch_async(_listenerQueue, ^{
        os_log(OS_LOG_DEFAULT, "retrieveListenerPid for identifier: %{public}@...", identifier);
        os_log(OS_LOG_DEFAULT, "_pendingListeners: %{public}@", [_pendingListeners allKeys]);
        
        OEXPCCMatchMakerListener *listener = _pendingListeners[identifier];
        
        if(listener == nil)
        {
            handler(-1);
            return;
        }
        
        os_log(OS_LOG_DEFAULT, "returning pid: %{public}d...", [listener pid]);
        handler([listener pid]);
    });
}

- (void)registerListenerEndpoint:(NSXPCListenerEndpoint *)endpoint ownPid:(int)pid forIdentifier:(NSString *)identifier completionHandler:(void (^)(BOOL))handler
{
    dispatch_async(_listenerQueue, ^{
        os_log(OS_LOG_DEFAULT, "Registering endpoint with identifier: %{public}@...", identifier);
        os_log(OS_LOG_DEFAULT, "_pendingClients: %{public}@", [_pendingClients allKeys]);
        
        OEXPCCMatchMakerClient *client = _pendingClients[identifier];

        _pendingListeners[identifier] = [OEXPCCMatchMakerListener matchMakerListenerWithEndpoint:endpoint pid:pid handler:handler];

        if(client == nil)
        {
            return;
        }

        client.handler(endpoint);
        handler(YES);
//        [_pendingClients removeObjectForKey:identifier];
    });
}

- (void)retrieveListenerEndpointForIdentifier:(NSString *)identifier ownPid:(int)pid completionHandler:(void (^)(NSXPCListenerEndpoint *))handler
{
    dispatch_async(_listenerQueue, ^{
        os_log(OS_LOG_DEFAULT, "Retrieving endpoint for identifier: %{public}@... ownPid: %{public}d", identifier, pid);
        os_log(OS_LOG_DEFAULT, "_pendingListeners: %{public}@", [_pendingListeners allKeys]);
        
        OEXPCCMatchMakerListener *listener = _pendingListeners[identifier];
        _pendingClients[identifier] = [OEXPCCMatchMakerClient matchMakerClientWithPid:pid handler:handler];

        if(listener == nil)
        {
            return;
        }

        handler([listener endpoint]);

        [listener handler](YES);
//        [_pendingListeners removeObjectForKey:identifier];
    });
}

@end

@implementation OEXPCCMatchMakerListener

+ (instancetype)matchMakerListenerWithEndpoint:(NSXPCListenerEndpoint *)endpoint pid:(int)pid handler:(void(^)(BOOL success))handler
{
    OEXPCCMatchMakerListener *listener = [[OEXPCCMatchMakerListener alloc] init];
    listener->_endpoint = endpoint;
    listener->_pid = pid;
    listener->_handler = [handler copy];
    return listener;
}

@end

@implementation OEXPCCMatchMakerClient
+ (instancetype)matchMakerClientWithPid:(int)pid handler:(void (^)(NSXPCListenerEndpoint *))handler
{
    OEXPCCMatchMakerClient *client = [[OEXPCCMatchMakerClient alloc] init];
    client->_pid = pid;
    client->_handler = [handler copy];
    return client;
}
@end
