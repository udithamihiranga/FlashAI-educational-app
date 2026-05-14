

/// NoteFile represents an attached file (PDF) for note generation
class NoteFile {
  final String id;
  final String name;
  final String path;
  final int size;
  final String? extractedText;
  final bool isProcessing;

  NoteFile({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    this.extractedText,
    this.isProcessing = false,
  });

  /// Create a copy with updated fields
  NoteFile copyWith({
    String? id,
    String? name,
    String? path,
    int? size,
    String? extractedText,
    bool? isProcessing,
  }) {
    return NoteFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      extractedText: extractedText ?? this.extractedText,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  /// Get file extension
  String get extension => name.split('.').last.toLowerCase();

  /// Check if file is a PDF
  bool get isPdf => extension == 'pdf';

  /// Get readable file size
  String get sizeInKB => '${(size / 1024).toStringAsFixed(1)} KB';
  String get sizeInMB => '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'size': size,
      'extractedText': extractedText,
      'isProcessing': isProcessing,
    };
  }

  /// Create from JSON
  factory NoteFile.fromJson(Map<String, dynamic> json) {
    return NoteFile(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      size: json['size'],
      extractedText: json['extractedText'],
      isProcessing: json['isProcessing'] ?? false,
    );
  }
}
