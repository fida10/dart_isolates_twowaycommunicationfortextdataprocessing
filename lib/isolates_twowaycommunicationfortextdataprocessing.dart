library;

import 'dart:async';
import 'dart:isolate';

export 'src/isolates_twowaycommunicationfortextdataprocessing_base.dart';

class SendingTextCommandsAndReceivedProcessedIsolate {
  final _receivedFromProcessed = ReceivePort();
  late final Stream _broadcastStream;
  SendPort? sendingToTextProcessor;
  bool sendPortInitialized = false;
  Isolate? isolateForTextProcessor;

  SendingTextCommandsAndReceivedProcessedIsolate() {
    _broadcastStream = _receivedFromProcessed.asBroadcastStream();
    //allows for _receivedFromProcessed to be listened to multiple times
    //don't worry, there is a below line "subscription?.cancel();" which closes a listener once it is done with the stream
    //so listeners don't needlessly accumulate
  }

  Future<dynamic> sendAndReceive(Map<String, String> commandsAndInput) async {
    final completer = Completer();

    // if (isolateForTextProcessor != null) {
    //   isolateForTextProcessor?.kill();
    //   isolateForTextProcessor = null;
    // }
    // isolateForTextProcessor =
    //     await Isolate.spawn(_textProcessPort, _receivedFromProcessed.sendPort);
    //the above will work but is not advised, better to reuse isolates rather than kill/remake them

    isolateForTextProcessor ??=
        await Isolate.spawn(_textProcessPort, _receivedFromProcessed.sendPort);

    StreamSubscription? subscription;
    (sendPortInitialized)
        ? sendingToTextProcessor?.send(commandsAndInput) //triggers the text processor isolate by sending it a map. without this, it will not send anything back!
        : print('Send Port to text processor has not been initialized yet!');

    subscription = _broadcastStream.listen((message) async {
      print("Message from text processing isolate: $message");

      if (message is SendPort) {
        sendingToTextProcessor = message;
        sendPortInitialized = true;
        sendingToTextProcessor?.send(commandsAndInput);
      }
      if (message is List) {
        completer.complete(message[1]);
        subscription?.cancel();
      }
    });
    return completer.future;
  }

  void shutdown() {
    _receivedFromProcessed.close();
    isolateForTextProcessor?.kill();
    isolateForTextProcessor = null;
  }
}

Future<void> _textProcessPort(SendPort sendBackToMainPort) async {
  final receiveFromMainPort = ReceivePort();
  sendBackToMainPort.send(receiveFromMainPort
      .sendPort); //sending the recieve port to the main isolate so it can communicate back with us

  receiveFromMainPort.listen((message) async {
    print("Message from main isolate: $message");

    if (message is Map<String, String>) {
      final processed = processingFunction(message['command'], message['text']);
      sendBackToMainPort.send(['Processed', processed]);
    }
  });
}

processingFunction(String? command, String? input) {
  if (command == 'reverse') {
    return input?.split(' ').map((e) => e.split('').reversed.join()).join(' ');
  } else if (command == 'wordCount') {
    return input?.split(' ').length;
  }
}

setupTextProcessingIsolate() async {
  return SendingTextCommandsAndReceivedProcessedIsolate();
}
