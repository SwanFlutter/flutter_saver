import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_saver/flutter_saver.dart';
import 'package:flutter_saver/flutter_saver_platform_interface.dart';
import 'package:flutter_saver/flutter_saver_method_channel.dart';

void main() {
  test('$MethodChannelFlutterSaver is the default platform instance', () {
    expect(
      FlutterSaverPlatform.instance,
      isInstanceOf<MethodChannelFlutterSaver>(),
    );
  });

  test('SaveResult.ok sets success=true and filePath', () {
    const r = SaveResult.ok('/tmp/test.jpg');
    expect(r.success, isTrue);
    expect(r.filePath, '/tmp/test.jpg');
    expect(r.error, isNull);
  });

  test('SaveResult.fail sets success=false and error', () {
    const r = SaveResult.fail('something went wrong');
    expect(r.success, isFalse);
    expect(r.filePath, isNull);
    expect(r.error, 'something went wrong');
  });

  test('SaveDirectory enum has all required values', () {
    final values = SaveDirectory.values;
    expect(
      values,
      containsAll([
        SaveDirectory.downloads,
        SaveDirectory.pictures,
        SaveDirectory.movies,
        SaveDirectory.dim,
        SaveDirectory.documents,
        SaveDirectory.music,
        SaveDirectory.podcasts,
        SaveDirectory.ringtones,
        SaveDirectory.alarms,
        SaveDirectory.notifications,
        SaveDirectory.screenshots,
        SaveDirectory.audiobooks,
      ]),
    );
  });
}
