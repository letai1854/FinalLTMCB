class ImageMessage {
  final String base64Data;
  final String mimeType;
  final int size;

  ImageMessage({
    required this.base64Data,
    required this.mimeType,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
        'base64Data': base64Data,
        'mimeType': mimeType,
        'size': size,
      };

  factory ImageMessage.fromJson(Map<String, dynamic> json) {
    return ImageMessage(
      base64Data: json['base64Data'],
      mimeType: json['mimeType'],
      size: json['size'],
    );
  }
}
