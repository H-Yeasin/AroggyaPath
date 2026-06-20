import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/medical_record_model.dart';
import '../../../providers/medical_record_provider.dart';
import 'add_medical_record_screen.dart';
import 'medical_record_detail_screen.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final _searchCtrl = TextEditingController();

  static const _filters = {
    'all': 'All',
    'prescription': 'Prescriptions',
    'summary': 'Summaries',
    'lab_report': 'Lab Reports',
    'follow_up': 'Follow-ups',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<MedicalRecordProvider>().fetchRecords(),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _applySearch() {
    return context.read<MedicalRecordProvider>().fetchRecords(
          search: _searchCtrl.text,
        );
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
          'Medical Records',
          style: TextStyle(color: colors.heading, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicalRecordScreen()),
          );
          if (added == true && context.mounted) {
            await context.read<MedicalRecordProvider>().fetchRecords();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Record'),
      ),
      body: Consumer<MedicalRecordProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchRecords(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _applySearch(),
                  decoration: InputDecoration(
                    hintText: 'Search doctor, title, or tag',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: _applySearch,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final entry = _filters.entries.elementAt(index);
                      final selected = provider.selectedType == entry.key;
                      return ChoiceChip(
                        label: Text(entry.value),
                        selected: selected,
                        selectedColor: colors.primaryContainer,
                        onSelected: (_) => provider.fetchRecords(
                          recordType: entry.key,
                          search: _searchCtrl.text,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                if (provider.isLoading && provider.records.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.records.isEmpty)
                  _buildEmptyState(colors)
                else
                  ..._buildTimeline(context, provider.records),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AroggyaColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 90),
      child: Column(
        children: [
          Icon(Icons.folder_open, size: 72, color: colors.disabled),
          const SizedBox(height: 12),
          Text(
            'No medical records yet',
            style: TextStyle(
              color: colors.heading,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Completed appointments and uploaded old reports will appear here.',
            style: TextStyle(color: colors.bodyText),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimeline(
    BuildContext context,
    List<MedicalRecordModel> records,
  ) {
    final widgets = <Widget>[];
    String? currentMonth;

    for (final record in records) {
      final month = _monthLabel(record.recordDate);
      if (month != currentMonth) {
        currentMonth = month;
        widgets.add(_TimelineHeader(label: month));
      }

      widgets.add(
        _RecordCard(
          record: record,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedicalRecordDetailScreen(record: record),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  String _monthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _TimelineHeader extends StatelessWidget {
  final String label;

  const _TimelineHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: colors.heading,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: colors.disabled.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final MedicalRecordModel record;
  final VoidCallback onTap;

  const _RecordCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_iconForType(record.recordType),
                      color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.heading,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.source == 'manual_upload'
                            ? 'Uploaded by patient'
                            : 'Dr. ${record.doctorName.isEmpty ? 'Doctor' : record.doctorName}',
                        style: TextStyle(color: colors.bodyText, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _Badge(label: record.typeLabel),
                          _Badge(label: record.formattedDate),
                          _Badge(
                              label: record.source == 'manual_upload'
                                  ? 'Manual'
                                  : 'Appointment'),
                          _Badge(label: '${record.files.length} file(s)'),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.disabled),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'prescription':
        return Icons.medication_outlined;
      case 'summary':
        return Icons.summarize_outlined;
      case 'lab_report':
        return Icons.biotech_outlined;
      case 'follow_up':
        return Icons.event_repeat_outlined;
      default:
        return Icons.description_outlined;
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: colors.bodyText, fontSize: 11)),
    );
  }
}
