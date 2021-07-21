#import "ImgToZplPlugin.h"
#if __has_include(<img_to_zpl/img_to_zpl-Swift.h>)
#import <img_to_zpl/img_to_zpl-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "img_to_zpl-Swift.h"
#endif

@implementation ImgToZplPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftImgToZplPlugin registerWithRegistrar:registrar];
}
@end
