# Useful commands

## Supporting 10.13
swift package generate-xcodeproj --xcconfig-overrides Config.xcconfig
swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.13" -Xswiftc -static-stdlib