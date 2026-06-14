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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Family Members',
            style: TextStyle(color: Color(0xFF1B2C49))),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1664CD)),
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
          backgroundColor: const Color(0xFFE3F2FD),
          child: Text(
            dep.fullName.isNotEmpty ? dep.fullName[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Color(0xFF1664CD), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(dep.displayName,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF1B2C49))),
        subtitle: Text('${dep.relationship ?? 'Family'} • Age ${dep.age}',
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
