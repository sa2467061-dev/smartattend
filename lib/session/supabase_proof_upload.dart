import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

/// Uploads a proof-of-absence file (image or PDF) to Supabase Storage
/// and returns the public URL to store in the Firestore attendance doc.
///
/// Throws an exception on failure — caller should catch and show a SnackBar.
Future<String> uploadAbsenceProof({
  required File file,
  required String studId,
  required String sesId,
}) async {
  final supabase = Supabase.instance.client;
  const bucketName = 'proof'; // matches your Supabase bucket name

  // Build a unique, collision-safe path: studId/sesId_timestamp.ext
  final extension = p.extension(file.path); // e.g. ".jpg", ".pdf"
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final storagePath = '$studId/${sesId}_$timestamp$extension';

  // Upload the file
  await supabase.storage.from(bucketName).upload(
        storagePath,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false, // don't overwrite — each submission is unique
        ),
      );

  // Since the bucket is public, this returns a permanent public URL
  final publicUrl =
      supabase.storage.from(bucketName).getPublicUrl(storagePath);

  return publicUrl;
}