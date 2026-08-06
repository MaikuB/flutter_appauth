#import <TargetConditionals.h>

#if TARGET_OS_OSX
#import <FlutterMacOS/FlutterMacOS.h>
#else
#import <Flutter/Flutter.h>
#endif

#if TARGET_OS_OSX
@interface FlutterAppauthPlugin
    : NSObject <FlutterPlugin, FlutterAppLifecycleDelegate>

@end
#else
@interface FlutterAppauthPlugin : NSObject <FlutterPlugin>

@end
#endif
