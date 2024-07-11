import 'package:drift/drift.dart';
import 'package:flexify/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

mockTests() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  timerChannel = const MethodChannel("com.presley.flexify/timer");
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
}
