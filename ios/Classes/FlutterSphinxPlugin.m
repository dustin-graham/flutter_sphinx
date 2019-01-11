#import "FlutterSphinxPlugin.h"
#import <flutter_sphinx/flutter_sphinx-Swift.h>

@implementation FlutterSphinxPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterSphinxPlugin registerWithRegistrar:registrar];
}
@end
