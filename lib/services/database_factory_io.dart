import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

DatabaseFactory get appDatabaseFactory {
  if (!Platform.isAndroid && !Platform.isIOS) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return databaseFactory;
}