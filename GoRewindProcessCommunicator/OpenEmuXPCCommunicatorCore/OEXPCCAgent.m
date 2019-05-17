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

#import "OEXPCCAgent.h"
#import "OEXPCCMatchMaking.h"
#import "OEXPCCAgentConfiguration_Internal.h"
#import <os/log.h>

@implementation OEXPCCAgent
{
    NSXPCConnection *_agentConnection;
    id<OEXPCCMatchMaking> _remoteObjectProxy;
}

+ (NSString *)OEXPCC_serviceNameFromArguments
{
    for(NSString *argument in [[NSProcessInfo processInfo] arguments])
        if([argument hasPrefix:_OEXPCCAgentServiceNameArgumentPrefix])
            return [argument substringFromIndex:[_OEXPCCAgentServiceNameArgumentPrefix length]];

    return nil;
}

+ (NSString *)OEXPCC_serviceNameFromDefaultConfiguration
{
    return [[OEXPCCAgentConfiguration OEXPCC_defaultConfigurationCreateIfNeeded:NO withName:nil applicationSupportDirectory:nil] serviceName];
}

+ (BOOL)canParseProcessArgumentsForDefaultAgent
{
    return [self OEXPCC_serviceNameFromArguments] != nil && [self defaultProcessIdentifier] != nil;
}

+ (OEXPCCAgent *)defaultAgentWithServiceName:(nullable NSString *)name errorHandler:(void (^_Nullable)(NSError *error))errorHandler
{
    static OEXPCCAgent *defaultAgent = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *serviceName = name;
        if(serviceName == nil) {
            serviceName = [self OEXPCC_serviceNameFromArguments] ? : [self OEXPCC_serviceNameFromDefaultConfiguration];
        }
        defaultAgent = [[OEXPCCAgent alloc] initWithServiceName:serviceName errorHandler:errorHandler];
    });

    return defaultAgent;
}

+ (NSString *)defaultProcessIdentifier
{
    for(NSString *argument in [[NSProcessInfo processInfo] arguments])
        if([argument hasPrefix:_OEXPCCAgentProcessIdentifierArgumentPrefix])
            return [argument substringFromIndex:[_OEXPCCAgentProcessIdentifierArgumentPrefix length]];

    return nil;
}

- (id)initWithServiceName:(NSString *)serviceName errorHandler:(void (^_Nullable)(NSError *error))errorHandler
{
    if((self = [super init]))
    {
        _serviceName = serviceName;

        os_log(OS_LOG_DEFAULT, "initWithMachServiceName: %{public}@", _serviceName);
        
        _agentConnection = [[NSXPCConnection alloc] initWithMachServiceName:_serviceName options:0];
        [_agentConnection setRemoteObjectInterface:[NSXPCInterface interfaceWithProtocol:@protocol(OEXPCCMatchMaking)]];
        [_agentConnection resume];

        _remoteObjectProxy = [_agentConnection remoteObjectProxyWithErrorHandler:errorHandler];
    }
    return self;
}

- (void)registerListenerEndpoint:(NSXPCListenerEndpoint *)endpoint forIdentifier:(NSString *)identifier completionHandler:(void (^)(BOOL))handler
{
    [_remoteObjectProxy registerListenerEndpoint:endpoint forIdentifier:identifier completionHandler:handler];
}

- (void)retrieveListenerEndpointForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSXPCListenerEndpoint *))handler
{
    [_remoteObjectProxy retrieveListenerEndpointForIdentifier:identifier completionHandler:handler];
}

@end
