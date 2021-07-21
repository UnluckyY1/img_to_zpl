import 'dart:async' show Completer, Future;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;

import 'src/hex_img_string.dart';

class ImgToZpl {
  static const MethodChannel _channel = const MethodChannel('img_to_zpl');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
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
