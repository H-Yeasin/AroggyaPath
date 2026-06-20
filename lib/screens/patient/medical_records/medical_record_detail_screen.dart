import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/medical_record_model.dart';

class MedicalRecordDetailScreen extends StatelessWidget {
  final MedicalRecordModel record;

  const MedicalRecordDetailScreen({super.key, required this.record});

  Future<void> _share() async {
    await Share.share(record.shareText);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          record.typeLabel,
          style: TextStyle(color: colors.heading, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _share,
            icon: Icon(Icons.share, color: colors.primary),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: TextStyle(
                    color: colors.heading,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Doctor',
                  value:
                      'Dr. ${record.doctorName.isEmpty ? 'Doctor' : record.doctorName}',
                ),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: record.formattedDate,
                ),
                _InfoRow(
                  icon: Icons.category_outlined,
                  label: 'Type',
                  value: record.typeLabel,
                ),
                _InfoRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Source',
                  value: record.source == 'manual_upload'
                      ? 'Patient upload'
                      : 'Appointment',
                ),
                if (record.description.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    record.description,
                    style: TextStyle(color: colors.bodyText, height: 1.45),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Attachments',
            style: TextStyle(
              color: colors.heading,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...record.files.map(
            (file) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  if (_isImage(file))
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _FullScreenImage(url: file.url),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        child: Image.network(
                          file.url,
                          height: 260,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    )
                  else
                    InkWell(
                      onTap: () => _openUrl(file.url),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.surfaceAlt,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
                        ),
                        child: Icon(
                          _iconForFile(file),
                          size: 56,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ListTile(
                    title: Text(
                      file.fileName.isEmpty ? 'Medical record file' : file.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _openUrl(file.url),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _share,
          icon: const Icon(Icons.share, color: Colors.white),
          label: const Text('Share Record'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  bool _isImage(MedicalRecordFile file) {
    final mime = file.mimeType.toLowerCase();
    final name = file.fileName.toLowerCase();
    return mime.startsWith('image/') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png');
  }

  IconData _iconForFile(MedicalRecordFile file) {
    final mime = file.mimeType.toLowerCase();
    final name = file.fileName.toLowerCase();
    if (mime.contains('pdf') || name.endsWith('.pdf')) {
      return Icons.picture_as_pdf_outlined;
    }
    return Icons.description_outlined;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 19),
          const SizedBox(width: 10),
          Text('$label: ', style: TextStyle(color: colors.bodyText)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: colors.heading,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String url;

  const _FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: PhotoView(
        imageProvider: NetworkImage(url),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}
