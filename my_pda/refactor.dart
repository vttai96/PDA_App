import 'dart:io';

void main() async {
  final baseDir = Directory('lib');
  if (!baseDir.existsSync()) {
    print('Run this from the project root.');
    return;
  }

  // Create new directories
  final dirs = [
    'lib/core/constants',
    'lib/core/theme',
    'lib/core/config',
    'lib/data/models',
    'lib/data/services',
    'lib/logic/providers',
    'lib/presentation/screens/auth',
    'lib/presentation/screens/dashboard',
    'lib/presentation/screens/history',
    'lib/presentation/screens/scanner',
    'lib/presentation/screens/settings',
    'lib/presentation/widgets',
  ];

  for (final d in dirs) {
    Directory(d).createSync(recursive: true);
  }

  // File moves mapping
  final fileMap = {
    'lib/config/api_config.dart': 'lib/core/config/api_config.dart',
    'lib/models/ingredient.dart': 'lib/data/models/ingredient.dart',
    'lib/services/datawedge_service.dart': 'lib/data/services/datawedge_service.dart',
    'lib/services/update_service.dart': 'lib/data/services/update_service.dart',
    'lib/widgets/custom_bottom_nav.dart': 'lib/presentation/widgets/custom_bottom_nav.dart',
    'lib/login_screen.dart': 'lib/presentation/screens/auth/login_screen.dart',
    'lib/forgot_pin_screen.dart': 'lib/presentation/screens/auth/forgot_pin_screen.dart',
    'lib/dashboard_screen.dart': 'lib/presentation/screens/dashboard/dashboard_screen.dart',
    'lib/history_screen.dart': 'lib/presentation/screens/history/history_screen.dart',
    'lib/history_detail_screen.dart': 'lib/presentation/screens/history/history_detail_screen.dart',
    'lib/barcode_fail_screen.dart': 'lib/presentation/screens/scanner/barcode_fail_screen.dart',
    'lib/barcode_scanner_screen.dart': 'lib/presentation/screens/scanner/barcode_scanner_screen.dart',
    'lib/barcode_success_screen.dart': 'lib/presentation/screens/scanner/barcode_success_screen.dart',
    'lib/manual_confirm_screen.dart': 'lib/presentation/screens/scanner/manual_confirm_screen.dart',
    'lib/scan_complete_screen.dart': 'lib/presentation/screens/scanner/scan_complete_screen.dart',
    'lib/scan_detail_screen.dart': 'lib/presentation/screens/scanner/scan_detail_screen.dart',
    'lib/settings_screen.dart': 'lib/presentation/screens/settings/settings_screen.dart',
  };

  // Move files
  for (final entry in fileMap.entries) {
    final oldFile = File(entry.key);
    final newFile = File(entry.value);
    if (oldFile.existsSync()) {
      oldFile.copySync(newFile.path);
      oldFile.deleteSync();
      print('Moved ${entry.key} to ${entry.value}');
    }
  }

  // Update imports
  // We will change all local file imports to use `package:my_pda/` paths.
  // This is the easiest and most robust way without dealing with complex relative paths right now.
  
  final importMap = {
    // Exact file name matcher to new package path
    'api_config.dart': 'package:my_pda/core/config/api_config.dart',
    'ingredient.dart': 'package:my_pda/data/models/ingredient.dart',
    'datawedge_service.dart': 'package:my_pda/data/services/datawedge_service.dart',
    'update_service.dart': 'package:my_pda/data/services/update_service.dart',
    'custom_bottom_nav.dart': 'package:my_pda/presentation/widgets/custom_bottom_nav.dart',
    'login_screen.dart': 'package:my_pda/presentation/screens/auth/login_screen.dart',
    'forgot_pin_screen.dart': 'package:my_pda/presentation/screens/auth/forgot_pin_screen.dart',
    'dashboard_screen.dart': 'package:my_pda/presentation/screens/dashboard/dashboard_screen.dart',
    'history_screen.dart': 'package:my_pda/presentation/screens/history/history_screen.dart',
    'history_detail_screen.dart': 'package:my_pda/presentation/screens/history/history_detail_screen.dart',
    'barcode_fail_screen.dart': 'package:my_pda/presentation/screens/scanner/barcode_fail_screen.dart',
    'barcode_scanner_screen.dart': 'package:my_pda/presentation/screens/scanner/barcode_scanner_screen.dart',
    'barcode_success_screen.dart': 'package:my_pda/presentation/screens/scanner/barcode_success_screen.dart',
    'manual_confirm_screen.dart': 'package:my_pda/presentation/screens/scanner/manual_confirm_screen.dart',
    'scan_complete_screen.dart': 'package:my_pda/presentation/screens/scanner/scan_complete_screen.dart',
    'scan_detail_screen.dart': 'package:my_pda/presentation/screens/scanner/scan_detail_screen.dart',
    'settings_screen.dart': 'package:my_pda/presentation/screens/settings/settings_screen.dart',
  };

  // Process all dart files
  final allDartFiles = baseDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
  
  for (final file in allDartFiles) {
    String content = file.readAsStringSync();
    bool changed = false;

    // A simple regex to find an import: import '...';
    // This regex looks for `import '` followed by anything, then `';`
    final importRegex = RegExp(r"import\s+['" + '"' + r"](.*?)['" + '"' + r"];");
    
    content = content.replaceAllMapped(importRegex, (match) {
      final originalImport = match.group(1)!;
      
      // Ignore package: and dart: imports
      if (originalImport.startsWith('package:') || originalImport.startsWith('dart:')) {
        return match.group(0)!;
      }
      
      // Check if the original import points to one of our mapped files
      // by looking at the filename part of the import.
      final fileName = originalImport.split('/').last;
      
      if (importMap.containsKey(fileName)) {
        changed = true;
        return "import '${importMap[fileName]}';";
      }
      return match.group(0)!;
    });

    if (changed) {
      file.writeAsStringSync(content);
      print('Updated imports in \${file.path}');
    }
  }

  // Cleanup old empty directories
  final oldDirs = ['lib/config', 'lib/models', 'lib/services', 'lib/widgets'];
  for (final d in oldDirs) {
    final dir = Directory(d);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
      print('Deleted old dir $d');
    }
  }
}
