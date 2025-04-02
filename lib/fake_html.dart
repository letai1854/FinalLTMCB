// This file provides stub implementations of dart:html classes
// to allow compilation on non-web platforms

class Blob {
  Blob(List<dynamic> _) {}
}

class Url {
  static String createObjectUrlFromBlob(dynamic _) => '';
  static void revokeObjectUrl(String _) {}
}

class AnchorElement {
  AnchorElement({String? href});
  void click() {}
  void setAttribute(String name, String value) {}
}
