// Stub file for web platform - File and Directory operations are not supported on web
// Use URL loading instead

/// Stub File class for web platform
class File {
  final String path;
  File(this.path);
  
  Future<bool> exists() async => false;
  Future<String> readAsString() async => throw UnsupportedError('File operations not supported on web');
  Future<void> writeAsString(String content) async => throw UnsupportedError('File operations not supported on web');
}

/// Stub Directory class for web platform
class Directory {
  final String path;
  Directory(this.path);
  
  Future<bool> exists() async => false;
  Stream<dynamic> list({bool recursive = false}) async* {}
  Future<void> create({bool recursive = false}) async => throw UnsupportedError('Directory operations not supported on web');
  Future<void> delete({bool recursive = false}) async => throw UnsupportedError('Directory operations not supported on web');
}

