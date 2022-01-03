import 'package:path/path.dart' as p;

String getAbsolutePath(String? relpath, String? fname) {
  String path = "";
  if (relpath != null && fname != null) {
    path = p.join(relpath, fname);
    if (!p.isAbsolute(path)) {
      path = p.join("/storage/emulated/0/", path);
    }
  }
  return path;
}
