import 'package:isolates_twowaycommunicationfortextdataprocessing/isolates_twowaycommunicationfortextdataprocessing.dart';
import 'package:test/test.dart';

void main() {
  test('processTextDataInIsolate processes text with two-way communication',
      () async {
    var textProcessingIsolate = await setupTextProcessingIsolate();

    var reverseText = await textProcessingIsolate
        .sendAndReceive({'command': 'reverse', 'text': 'Hello Dart Isolates'});
    expect(reverseText, equals('olleH traD setalosI'));

    var wordCount = await textProcessingIsolate.sendAndReceive(
        {'command': 'wordCount', 'text': 'Hello Dart Isolates'});
    expect(wordCount, equals(3));

    await textProcessingIsolate.shutdown();
  });
}
