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

#import <Cocoa/Cocoa.h>
#import <OpenEmuXPCCommunicator/OpenEmuXPCCommunicator.h>
#import "OEXPCCTestBackgroundService.h"

@interface ServiceProvider : NSObject <OEXPCCTestBackgroundService, NSXPCListenerDelegate, NSApplicationDelegate>
- (void)resumeConnection;
@end

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        NSApplication *app = [NSApplication sharedApplication];
        ServiceProvider *provider = [[ServiceProvider alloc] init];
        [app setDelegate:provider];
        [provider resumeConnection];
        [app run];
    }
    return 0;
}

@implementation ServiceProvider
{
    NSXPCListener *_listener;
    NSXPCConnection *_mainAppConnection;
}

- (void)resumeConnection
{
    _listener = [NSXPCListener anonymousListener];
    [_listener setDelegate:self];
    [_listener resume];

    NSXPCListenerEndpoint *endpoint = [_listener endpoint];
    [[OEXPCCAgent defaultAgentWithServiceName:@"ai.m37.GoRewind.OEXPCCAgent.ha"] registerListenerEndpoint:endpoint forIdentifier:[OEXPCCAgent defaultProcessIdentifier] completionHandler:^(BOOL success){ }];
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    _mainAppConnection = newConnection;
    [_mainAppConnection setExportedInterface:[NSXPCInterface interfaceWithProtocol:@protocol(OEXPCCTestBackgroundService)]];
    [_mainAppConnection setExportedObject:self];
    [_mainAppConnection resume];

    return YES;
}

- (void)transformString:(NSString *)string completionHandler:(void (^)(NSString *))handler
{
    handler([NSString stringWithFormat:@"<%@>: %@", [OEXPCCAgent defaultProcessIdentifier], string]);
}

@end
