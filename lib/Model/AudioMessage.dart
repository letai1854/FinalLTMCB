class AudioData {
  final String base64Data;
  final int duration;
  final String mimeType;
  final int size;

  AudioData({
    required this.base64Data,
    required this.duration,
    required this.mimeType,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
        'base64Data': base64Data,
        'duration': duration,
        'mimeType': mimeType,
        'size': size,
      };

  factory AudioData.fromJson(Map<String, dynamic> json) {
    return AudioData(
      base64Data: json['base64Data'],
      duration: json['duration'],
      mimeType: json['mimeType'],
      size: json['size'],
    );
  }
}
