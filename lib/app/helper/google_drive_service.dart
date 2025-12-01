import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:js' as js;

class GoogleDriveService {
  static String? _accessToken;

    String _getMimeTypeFromFileName(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream'; // Default binary
    }
  }

  Future<Map<String, dynamic>?> uploadFile({
    required String fileName,
    required Uint8List fileBytes,
    String? description,
  }) async {
    if (!isLoggedIn || _accessToken == null) {
      throw Exception('Not logged in to Google Drive');
    }
    
    try {
      final mimeType = _getMimeTypeFromFileName(fileName);
      
      final metadata = {
        'name': fileName,
        'mimeType': mimeType,
        if (description != null) 'description': description,
      };
      
      final boundary = 'flutter_boundary';
      final body = <int>[]
        ..addAll(utf8.encode('--$boundary\r\n'))
        ..addAll(utf8.encode('Content-Type: application/json\r\n\r\n'))
        ..addAll(utf8.encode(json.encode(metadata)))
        ..addAll(utf8.encode('\r\n--$boundary\r\n'))
        ..addAll(utf8.encode('Content-Type: $mimeType\r\n\r\n'))
        ..addAll(fileBytes)
        ..addAll(utf8.encode('\r\n--$boundary--'));
      
      final response = await http.post(
        Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'multipart/related; boundary=$boundary',
        },
        body: body,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        logout();
        throw Exception('Token expired, please login again');
      } else {
        throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Google Drive upload error: $e');
      rethrow;
    }
  }
  
  // Tambahkan method uploadPDF untuk backward compatibility
  Future<Map<String, dynamic>?> uploadPDF({
    required String fileName,
    required Uint8List fileBytes,
    String? description,
  }) async {
    return uploadFile(
      fileName: fileName,
      fileBytes: fileBytes,
      description: description,
    );
  }
  // Get access token from Google Identity Services
  static Future<String?> getAccessToken() async {
    final completer = Completer<String?>();
    js.context['setDriveAccessToken'] = (token) {
      completer.complete(token);
    };
    js.context.callMethod('googleDriveLogin', ['setDriveAccessToken']);
    return completer.future;
  }

  // Login to Google Drive
  static Future<bool> login() async {
    try {
      final token = await getAccessToken();
      if (token != null) {
        _accessToken = token;
        return true;
      }
      return false;
    } catch (e) {
      print('Google Drive login error: $e');
      return false;
    }
  }

  // Upload PDF to Google Drive
  // static Future<Map<String, dynamic>?> uploadPDF({
  //   required String fileName,
  //   required Uint8List fileBytes,
  //   String? folderId,
  //   String? description,
  // }) async {
  //   if (_accessToken == null) {
  //     throw Exception('Not logged in to Google Drive');
  //   }

  //   try {
  //     // Create file metadata
  //     final metadata = {
  //       'name': fileName,
  //       'mimeType': 'application/pdf',
  //       if (description != null) 'description': description,
  //       if (folderId != null) 'parents': [folderId],
  //     };

  //     final boundary = 'flutter_boundary';
  //     final body = <int>[]
  //       ..addAll(utf8.encode('--$boundary\r\n'))
  //       ..addAll(utf8.encode('Content-Type: application/json\r\n\r\n'))
  //       ..addAll(utf8.encode(json.encode(metadata)))
  //       ..addAll(utf8.encode('\r\n--$boundary\r\n'))
  //       ..addAll(utf8.encode('Content-Type: application/pdf\r\n\r\n'))
  //       ..addAll(fileBytes)
  //       ..addAll(utf8.encode('\r\n--$boundary--'));

  //     final response = await http.post(
  //       Uri.parse(
  //         'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
  //       ),
  //       headers: {
  //         'Authorization': 'Bearer $_accessToken',
  //         'Content-Type': 'multipart/related; boundary=$boundary',
  //       },
  //       body: body,
  //     );

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       return {
  //         'id': data['id'],
  //         'name': data['name'],
  //         'webViewLink': data['webViewLink'],
  //         'webContentLink': data['webContentLink'],
  //         'driveUrl': 'https://drive.google.com/file/d/${data['id']}/view',
  //       };
  //     } else {
  //       throw Exception('Upload failed: ${response.body}');
  //     }
  //   } catch (e) {
  //     print('Google Drive upload error: $e');
  //     rethrow;
  //   }
  // }

  // Download file from Google Drive
  static Future<void> downloadFile(String fileId, String fileName) async {
    if (_accessToken == null) {
      throw Exception('Not logged in to Google Drive');
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
        ),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..download = fileName
          ..target = '_blank';

        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        throw Exception('Download failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Google Drive download error: $e');
      rethrow;
    }
  }

  // Update file in Google Drive
  static Future<Map<String, dynamic>?> updateFile({
    required String fileId,
    String? newName,
    Uint8List? newFileBytes,
    String? newDescription,
  }) async {
    if (_accessToken == null) {
      throw Exception('Not logged in to Google Drive');
    }

    try {
      // If updating file content
      if (newFileBytes != null) {
        final metadata = {
          if (newName != null) 'name': newName,
          if (newDescription != null) 'description': newDescription,
        };

        final boundary = 'flutter_boundary';
        final body = <int>[]
          ..addAll(utf8.encode('--$boundary\r\n'))
          ..addAll(utf8.encode('Content-Type: application/json\r\n\r\n'))
          ..addAll(utf8.encode(json.encode(metadata)))
          ..addAll(utf8.encode('\r\n--$boundary\r\n'))
          ..addAll(utf8.encode('Content-Type: application/pdf\r\n\r\n'))
          ..addAll(newFileBytes)
          ..addAll(utf8.encode('\r\n--$boundary--'));

        final response = await http.patch(
          Uri.parse(
            'https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=multipart',
          ),
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'multipart/related; boundary=$boundary',
          },
          body: body,
        );

        if (response.statusCode == 200) {
          return json.decode(response.body);
        }
      } else {
        // Only update metadata
        final metadata = {
          if (newName != null) 'name': newName,
          if (newDescription != null) 'description': newDescription,
        };

        final response = await http.patch(
          Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId'),
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'application/json',
          },
          body: json.encode(metadata),
        );

        if (response.statusCode == 200) {
          return json.decode(response.body);
        }
      }

      return null;
    } catch (e) {
      print('Google Drive update error: $e');
      rethrow;
    }
  }

  // Delete file from Google Drive
  static Future<bool> deleteFile(String fileId) async {
    if (_accessToken == null) {
      throw Exception('Not logged in to Google Drive');
    }

    try {
      final response = await http.delete(
        Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      return response.statusCode == 204;
    } catch (e) {
      print('Google Drive delete error: $e');
      rethrow;
    }
  }

  // Check if logged in
  static bool get isLoggedIn => _accessToken != null;

  // Logout
  static void logout() {
    _accessToken = null;
  }
}
