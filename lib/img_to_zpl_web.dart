import 'dart:async';
// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/widgets.dart'
    show Image, ImageConfiguration, ImageInfo, ImageStreamListener;

import 'src/hex_img_string.dart';

/// A web implementation of the ImgToZpl plugin.
class ImgToZplWeb {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'img_to_zpl',
      const StandardMethodCodec(),
      registrar,
    );

    final pluginInstance = ImgToZplWeb();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
  }

  /// Handles method calls over the MethodChannel of this plugin.
  /// Note: Check the "federated" architecture for a new way of doing this:
  /// https://flutter.dev/go/federated-plugins
  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'getPlatformVersion':
        return getPlatformVersion();
      case 'convertImgtoZpl':
        return convertImgtoZpl(call.arguments[0], call.arguments[1]);
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'img_to_zpl for web doesn\'t implement \'${call.method}\'',
        );
    }
  }

  /// Returns a [String] containing the version of the platform.
  Future<String> getPlatformVersion() {
    final version = html.window.navigator.userAgent;
    return Future.value(version);
  }

  /// converts the image to zpl string in the following format
  /// '~DF[name], [totalImageBytes], [bytesperRow], [data in hex format]\n'
  /// you can use this image in zpl using the following command
  /// '^FO25,0^XGR:[name],1,1^FS'
  static Future<String> convertImgtoZpl(
      String name, Uint8List imageAsU8) async {
    HexImageString tuple = await _getHexBody(imageAsU8);
    var body = tuple.hexImage;
    //if (compressHex) cuerpo = encodeHexAscii(cuerpo);
    return '~DG${name},' +
        tuple.totalBytes.toInt().toString() +
        "," +
        tuple.widthBytes.toInt().toString() +
        ", " +
        body +
        "\n";
  }

  static Future<HexImageString> _getHexBody(Uint8List imageAsU8) async {
    var image = Image.memory(imageAsU8);
    Completer<ui.Image> completer = new Completer<ui.Image>();
    image.image
        .resolve(new ImageConfiguration())
        .addListener(new ImageStreamListener((ImageInfo image, bool _) {
      completer.complete(image.image);
    }));
    ui.Image info = await completer.future;
    int width = info.width;
    int height = info.height;
    var photo = img.decodeImage(imageAsU8);
    var widthBytes = width / 8;
    if (width % 8 > 0) {
      widthBytes = (((width / 8).floor()) + 1);
    } else {
      widthBytes = width / 8;
    }
    var total = widthBytes * height;
    int index = 0;
    var colorByte = ['0', '0', '0', '0', '0', '0', '0', '0'];
    var hexString = '';
    for (int h = 0; h < height; h++) {
      for (int w = 0; w < width; w++) {
        var rgb = photo?.getPixelSafe(w, h);
        var red = (rgb! >> 16) & 0x000000FF;
        var green = (rgb >> 8) & 0x000000FF;
        var blue = (rgb) & 0x000000FF;
        var currentChar = '1';
        int totalColor = red + green + blue;
        if (totalColor > 384) {
          currentChar = '0';
        }
        colorByte[index] = currentChar;
        index++;
        if (index == 8 || w == (width - 1)) {
          hexString += _fourByteBinary(colorByte.join());
          colorByte = ['0', '0', '0', '0', '0', '0', '0', '0'];
          index = 0;
        }
      }
      hexString += "\n";
    }
    return HexImageString(
        hexImage: hexString, totalBytes: total, widthBytes: widthBytes);
  }

  static String _fourByteBinary(String binaryStr) {
    int decimal = int.parse(binaryStr, radix: 2);
    if (decimal > 15) {
      return decimal.toRadixString(16).toUpperCase();
    } else {
      return '0' + decimal.toRadixString(16).toUpperCase();
    }
  }
}
