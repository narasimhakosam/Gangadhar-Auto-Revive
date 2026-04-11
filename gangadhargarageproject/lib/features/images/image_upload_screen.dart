import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class ImageUploadScreen extends StatefulWidget {
  final String vehicleId;
  final String? visitId;
  const ImageUploadScreen({super.key, required this.vehicleId, this.visitId});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isCompressing = false;
  bool _isUploading = false;
  Uint8List? _compressedBytes;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          _selectedImage = picked;
          _isCompressing = true;
        });

        final compressed = await FlutterImageCompress.compressWithFile(
          picked.path,
          minWidth: 800,
          minHeight: 800,
          quality: 80,
        );

        if (compressed != null) {
          setState(() {
            _compressedBytes = Uint8List.fromList(compressed);
            _isCompressing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _upload() async {
    if (_compressedBytes == null || _selectedImage == null) return;

    setState(() => _isUploading = true);
    try {
      final ext = _selectedImage!.path.split('.').last.toLowerCase();
      final fileName = '${widget.vehicleId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final filePath = '${widget.vehicleId}/$fileName';

      // Upload binary directly to Supabase Storage — NO Base64 overhead
      await supabase.storage.from('vehicle_images').uploadBinary(
        filePath,
        _compressedBytes!,
        fileOptions: FileOptions(contentType: 'image/$ext'),
      );

      // Get public URL and save reference to database
      final imageUrl = supabase.storage.from('vehicle_images').getPublicUrl(filePath);

      if (widget.visitId != null) {
        await supabase.from('visit_images').insert({
          'visit_id': widget.visitId,
          'image_url': imageUrl,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Spare Part Image')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_isCompressing)
              const Column(children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Compressing Image...'),
              ]),
            if (_compressedBytes != null)
              Column(
                children: [
                  Image.memory(
                    _compressedBytes!,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
                      onPressed: _isUploading ? null : _upload,
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('UPLOAD IMAGE', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
