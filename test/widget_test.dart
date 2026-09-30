import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:todo_list/theme/app_theme.dart';

void main() {
  test('AppTheme color token test', () {
    expect(AppTheme.primaryBlue, isNotNull);
    expect(AppTheme.background, isNotNull);
  });
}

