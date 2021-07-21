import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:img_to_zpl/img_to_zpl.dart';

void main() {
  const MethodChannel channel = MethodChannel('img_to_zpl');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await ImgToZpl.platformVersion, '42');
  });
}
