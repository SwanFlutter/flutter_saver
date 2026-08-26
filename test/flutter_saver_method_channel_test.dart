import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_saver/flutter_saver_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MethodChannelFlutterSaver instantiates without error', () {
    expect(MethodChannelFlutterSaver(), isNotNull);
  });
}
