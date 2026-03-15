import 'dart:io';

void main() {
  final dir = Directory('lib');
  int count = 0;
  for (final file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      bool modified = false;
      
      if (content.contains('.withOpacity(')) {
        content = content.replaceAllMapped(
          RegExp(r'\.withOpacity\((.*?)\)'),
          (match) => '.withValues(alpha: ${match.group(1)})',
        );
        modified = true;
      }
      
      if (modified) {
        file.writeAsStringSync(content);
        count++;
        print('Updated: \${file.path}');
      }
    }
  }
  print('Updated \$count files replacing withOpacity -> withValues(alpha:).');
}
