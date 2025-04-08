class GlobalVariables {
  // Singleton instance
  static final GlobalVariables _instance = GlobalVariables._internal();
  static GlobalVariables get instance => _instance;

  // Private constructor
  GlobalVariables._internal();

  // Factory constructor
  factory GlobalVariables() {
    return _instance;
  }

  // Port variable
  int? _port; // Private port variable

  // Getter
  int? get port => _port;

  // Setter
  void setPort(int? value) {
    _port = value;
  }
}
