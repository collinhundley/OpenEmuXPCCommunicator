GoRewindProcessCommunicator
======================

GoRewindProcessCommunicator makes it easier to use the underlying OpenEmuXPCCommunicator library. 

Installation
-----------------

Using [Carthage](https://github.com/carthage/carthage/): 
1. Add to the Cartfile: `github "move37-com/OpenEmuXPCCommunicator" "feature/carthage"`
2. Run `carthage update --platform osx`
3. Drag the built `GoRewindProcessCommunicator.framework` binary from `Carthage/Build/Mac` into the Xcode project's `Embedded Binaries` section (works for application bundles only. For CLI see below.)
4. Add framework path (usually `../Carthage/Build/Mac` or `$(PROJECT_DIR)/Carthage/Build/Mac`) to the `Framework Search Paths` build setting

For CLI applications:
1. Add `GoRewindProcessCommunicator.framework` binary to `Linked Frameworks and Libraries` section
2. Add `New Copy Files` build phase and add the framework to `Products Directory`
3. Make sure runpath is pointing to the Products Directory as well (`@executable_path`)

Additionally, you'll want to copy debug symbols for debugging and crash reporting: add `New Copy Files` build phase and add the `GoRewindProcessCommunicator.dSYM` file to `Products Directory`.

For github builds, make sure the `M37GitBranch` key is present in the `Info.plist` file. This is how we currently select the environment [tbd].

Usage
-----------------

Setup and start the agent:
```
OEXPCCAgentConfiguration.defaultConfiguration(withName: GoRewindProcessConstants.serviceName)
OEXPCCAgent.defaultAgent(withServiceName: GoRewindProcessConstants.fullServiceName)
```

###Peer
```
var peer: GoRewindPeer<RemoteProtocol>!
...
let handler = LocalHandler()
peer = GoRewindPeer<RemoteProtocol>(handler: handler, 
                                    localProtocol: LocalProtocol.self, 
                                    remoteProtocol: RemoteProtocol.self, 
                                    currentContextIdentifier: ContextIdentifiers.mainApplication)
peer.onHandshake = { service in
    print("handshake")
}
peer.listen()
```

Both `RemoteProtocol` and `LocalProtocol` inherit from `GoRewindProcessProtocol`. `handler` object must adopt the `LocalProtocol`.

After handshake is successfull, `service` callback (or `peer.service`) can be used.

###GoRewindRunningProcess

`GoRewindRunningProcess` presumes the peer is already alive & running. Usage is very similar to `peer`:
```
let process: GoRewindRunningProcess<RemoteProtocol>?
...
let handler = LocalHandler()
process = GoRewindRunningProcess<RemoteProtocol>(localProtocol: LocalProtocol.self, 
                                                 remoteProtocol: RemoteProtocol.self, 
                                                 handler: handler, 
                                                 remoteContextIdentifier: ContextIdentifiers.mainApplication)
process?.onHandshake = {
    os_log("process:handshake")
}
os_log("process:connect...")
process?.connect()
...
process?.service?.doSomething()
```

###GoRewindProcess

`GoRewindProcess` is the same as `GoRewindRunningProcess`, except it also runs the executable.
```
var process: GoRewindProcess<RemoteProtocol>?
...
let handler = LocalHandler()
process = GoRewindProcess<RemoteProtocol>(launchUrl: URL(fileURLWithPath: "/path/to/executable"), 
                                        localProtocol: LocalProtocol.self, 
                                        remoteProtocol: RemoteProtocol.self, 
                                        handler: handler, 
                                        remoteContextIdentifier: ContextIdentifiers.mainApplication)
process?.onHandshake = { [weak self] in
    os_log("process:handshake")
}
process?.run()
```

Todo list
---------

+ Setup and `launchd` the agent on app installation 
+ Use the `M37GitBranch` key from the main application or introduce a new method to differentiate between environments
+ Combine `GoRewindRunningProcess` and `GoRewindProcess` classes: start the executable only if it isn't running yet

---

OpenEmuXPCCommunicator
======================

OpenEmuXPCCommunicator allows you to create an XPC connection between two arbitrary processes that use the framework. The way it differs from a normal XPC service is that you can connect to multiple instances of the target process rather than being limited to one instance of the XPC service.

Unlike an XPC service, you are launching the companion process and shutting it down yourself. The framework allows you to transmit an NSXPCListenerEndpoint from one process to the other allowing you to create the direct XPC connection. Once the endpoint is sent the XPC Communicator service is no longer involved in the connection and can die at any moment. It can be woke up to open a new connection with a new process.

How does it work?
-----------------

The framework defines two classes allowing the processes to communicate. OEXPCCAgentConfiguration takes care of the middle-man agent that will send the connection from one process to the other. OEXPCCAgent allows you to send and receive the NSXPCListenerEndpoint to build the connection.

### OEXPCCAgentConfiguration

When a process wishes to create connections with other processes, it will first need to configure the middle-man using OEXPCCAgentConfiguration. This class registers a Launchd agent with a unique service name to which OEXPCCAgent will connect. It also declares two methods to generate launch arguments to send to the processes you want to communicate with.

Get the defaultConfiguration, create a unique identifier for your background process, and launch the background process with the result of -agentServiceNameProcessArgument and -processIdentifierArgumentForIdentifier:.

OEXPCCAgentConfiguration *configuration = [OEXPCCAgentConfiguration defaultConfiguration];

// NSUUID is a good way to get a unique identifier, but you can put anything here.
NSString *processIdentifier = [[NSUUID UUID] UUIDString];
NSArray *companionProcessArguments = @[
[configuration agentServiceNameProcessArgument],
[configuration processIdentifierArgumentForIdentifier:processIdentifier]
];

// Create and launch the companion process with the service arguments.
NSTask *companionProcessTask = [[NSTask alloc] init];
[companionProcessTask setLaunchPath:@"path/to/companion/process"];
[companionProcessTask setArguments:companionProcessArguments];

[companionProcessTask launch];

### OEXPCCAgent

OEXPCCAgent is needed on both sides of the connection, this is the class that will allow you to send and receive the NSXPCListenerEndpoint necessary to establish the connection. Create the NSXPCListenerEndpoint on one end and send it through the OEXPCCAgent with the identifier of the process to connect to.

Get the defaultAgent, register the endpoint on one side, retrieve the endpoint on the other, configure the connection, send your first message and the connection is established. The defaultAgent will automatically search for the launch arguments of the process or read the OEXPCCAgentConfiguration defaultConfiguration to establish the connection.

#### Process creating the connection

// Create an anonymousListener to allow the other process to connect to us.
NSXPCListener *listener = [NSXPCListener anonymousListener];
[listener setDelegate:listenerDelegate];
[listener resume];

// Create the endpoint and send it to the other process
NSXPCListenerEndpoint *endpoint = [listener endpoint];
[[OEXPCCAgent defaultAgent] registerListenerEndpoint:endpoint forIdentifier:[OEXPCCAgent defaultProcessIdentifier] completionHandler:
^(BOOL success)
{
NSLog(@"The other process did receive the endpoint: %d", success);
}];

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
[newConnection setExportedInterface:[NSXPCInterface interfaceWithProtocol:@protocol(MyCommunicationProtocol)]]; 
[newConnection setExportedObject:self];
[newConnection resume];

return YES;
}

#### Process receiving the connection

id<MyCommunicationProtocol> remoteObjectProxy;

[[OEXPCCAgent defaultAgent] retrieveListenerEndpointForIdentifier:processIdentifier completionHandler:
^(NSXPCListenerEndpoint *endpoint)
{
processConnection = [[NSXPCConnection alloc] initWithListenerEndpoint:endpoint];
[processConnection setRemoteObjectInterface:[NSXPCInterface interfaceWithProtocol:@protocol(OEXPCCTestBackgroundService)]];
[processConnection resume];

remoteObjectProxy = [processConnection remoteObjectProxy];

// From now on you can communicate with the other process like you would with any XPC service.
[remoteObjectProxy handshake];
}];

Important
---------

### Tear Down

When your papplication is closing, you should send the message -tearDownAgent to your OEXPCCAgentConfiguration, or else the Application Support folder of the framework will keep growing every time you run the application.

OEXPCCAgentConfiguration works by copying the agent binary to an Application Support folder and then registering a generated property list with launchctl, since the serviceName of the agent is unique, every time a new configuration is allocate, a new agent is copied to the Application Support folder.

### App Store

I have no idea if this framework is compatible with the App Store policies and I cannot test it. If anyone can test and tell me that would be great.

Todo list
---------

+ Add a per-connection timeout. When a process registers an endpoint or another attempts to retrieve an endpoint, we should be able to give a timeout so that the connection does not wait forever.
+ Allow to specify the name of the Mach service. Rather than using +defaultConfiguration which creates a unique Mach service, it should be possible to provide your own service name to have a unique agent that can be reused in later sessions.
