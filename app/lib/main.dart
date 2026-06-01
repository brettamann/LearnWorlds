// CritMath app entry point. See specs/shared/system-architecture.md for the
// runtime architecture.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  runApp(const ProviderScope(child: CritMathApp()));
}
