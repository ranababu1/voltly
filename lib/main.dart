import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:voltly/app/app.dart';
import 'package:voltly/app/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle);
  runApp(const VoltlyApp());
}
