import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<File> _compress(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = path.join(
        dir.path, '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg');
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 75,
      minWidth: 1280,
      minHeight: 720,
    );
    return File(result?.path ?? file.path);
  }

  Future<String> uploadExpenseBill(
      File file, String userId, String expenseId) async {
    final compressed = await _compress(file);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storagePath = '$userId/$expenseId/$fileName';

    await _client.storage.from('expense-bills').upload(storagePath, compressed,
        fileOptions: const FileOptions(contentType: 'image/jpeg'));

    return _client.storage.from('expense-bills').getPublicUrl(storagePath);
  }

  Future<String> uploadDocument(File file, String userId, String type) async {
    final compressed = await _compress(file);
    final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storagePath = '$userId/$fileName';

    await _client.storage.from('employee-documents').upload(
        storagePath, compressed,
        fileOptions: const FileOptions(contentType: 'image/jpeg'));

    return _client.storage.from('employee-documents').getPublicUrl(storagePath);
  }

  Future<String> uploadProfilePhoto(File file, String userId) async {
    final compressed = await _compress(file);
    final storagePath = '$userId/profile.jpg';

    await _client.storage.from('profile-photos').upload(storagePath, compressed,
        fileOptions:
            const FileOptions(contentType: 'image/jpeg', upsert: true));

    return _client.storage.from('profile-photos').getPublicUrl(storagePath);
  }
}
