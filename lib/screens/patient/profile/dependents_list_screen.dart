import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/dependent_model.dart';
import '../../../providers/dependent_provider.dart';
import 'add_dependents_screen.dart';
import 'edit_dependent_screen.dart';

class DependentsListScreen extends StatefulWidget {
  const DependentsListScreen({super.key});

  @override
  State<DependentsListScreen> createState() => _DependentsListScreenState();
}

class _DependentsListScreenState extends State<DependentsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<DependentProvider>().fetchDependents());
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Family Members', style: TextStyle(color: colors.heading)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: colors.primary),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddDependentScreen()),
              );
              if (mounted) {
                context.read<DependentProvider>().fetchDependents();
              }
            },
          ),
        ],
      ),
      body: Consumer<DependentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.dependents.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No family members added',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchDependents(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.dependents.length,
              itemBuilder: (context, index) {
                final dep = provider.dependents[index];
                return _buildDependentCard(dep, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDependentCard(DependentModel dep, DependentProvider provider) {
    final colors = AppTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          child: Text(
            dep.fullName.isNotEmpty ? dep.fullName[0].toUpperCase() : '?',
            style:
                TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(dep.displayName,
            style:
                TextStyle(fontWeight: FontWeight.bold, color: colors.heading)),
        subtitle: Text('${dep.relationship ?? 'Family'} â€¢ Age ${dep.age}',
            style: const TextStyle(color: Colors.grey)),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EditDependentScreen(dependent: dep)),
              );
              if (mounted) provider.fetchDependents();
            } else if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Remove Member'),
                  content:
                      Text('Remove ${dep.fullName} from your family list?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Remove',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) {
                await provider.deleteDependent(dep.id);
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
