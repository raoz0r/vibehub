// ignore_for_file: avoid_print

import 'package:vibehub/api/skills_sync.dart';

void main() async {
  print('Checking and synchronizing skills catalog...');
  
  // Running with force: true so you can manually trigger and see the download occur
  final result = await SkillsSyncApi.sync(force: true);
  
  print('\n----------------------------------------');
  print('Success:     ${result.success}');
  print('Downloaded:  ${result.downloaded}');
  print('Reason:      ${result.reason}');
  print('Saved Path:  ${result.path}');
  if (result.errorMessage != null) {
    print('Error:       ${result.errorMessage}');
  }
  print('----------------------------------------');
}
