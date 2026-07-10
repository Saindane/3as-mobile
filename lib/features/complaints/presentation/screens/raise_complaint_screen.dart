import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/complaint_provider.dart';

class RaiseComplaintScreen extends ConsumerStatefulWidget {
  const RaiseComplaintScreen({super.key});

  @override
  ConsumerState<RaiseComplaintScreen> createState() => _RaiseComplaintScreenState();
}

class _RaiseComplaintScreenState extends ConsumerState<RaiseComplaintScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtr   = TextEditingController();
  final _descCtr    = TextEditingController();
  String _category  = 'electrical';
  String _priority  = 'medium';

  static const _categories = [
    'electrical', 'plumbing', 'civil',
    'security', 'housekeeping', 'common_area', 'other',
  ];
  static const _priorities = ['low', 'medium', 'high'];

  @override
  void dispose() {
    _titleCtr.dispose();
    _descCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(raiseComplaintProvider.notifier).raise_(
      title:       _titleCtr.text.trim(),
      category:    _category,
      priority:    _priority,
      description: _descCtr.text.trim().isEmpty ? null : _descCtr.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(raiseComplaintProvider);

    ref.listen(raiseComplaintProvider, (_, next) {
      if (next.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Complaint raised successfully'),
          backgroundColor: AppColors.success,
        ));
        Navigator.pop(context);
        ref.read(raiseComplaintProvider.notifier).reset();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
        ));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Raise complaint')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Category chips
            const Text('Category', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8,
              children: _categories.map((cat) {
                final selected = _category == cat;
                return FilterChip(
                  label: Text(cat.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: selected ? AppColors.primary : AppColors.textSecondary,
                      )),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = cat),
                  selectedColor: AppColors.primaryLight,
                  backgroundColor: AppColors.slate100,
                  side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Priority
            const Text('Priority', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(children: _priorities.map((p) {
              final selected = _priority == p;
              final color = p == 'high' ? AppColors.error
                          : p == 'medium' ? AppColors.warning
                          : AppColors.success;
              return Expanded(child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _priority = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? color.withOpacity(.12) : AppColors.slate100,
                      border: Border.all(
                        color: selected ? color : AppColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p[0].toUpperCase() + p.substring(1),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: selected ? color : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ));
            }).toList()),

            const SizedBox(height: 20),

            // Title
            const Text('Title', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleCtr,
              decoration: const InputDecoration(
                hintText: 'e.g. Lift not working in B block',
                filled: true, fillColor: AppColors.slate100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a title' : null,
            ),

            const SizedBox(height: 14),

            // Description
            const Text('Description (optional)', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtr,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe the issue in detail — location, what you see, when it started...',
                filled: true, fillColor: AppColors.slate100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),

            const SizedBox(height: 28),

            ElevatedButton.icon(
              onPressed: state.isLoading ? null : _submit,
              icon: state.isLoading
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, size: 18),
              label: Text(state.isLoading ? 'Submitting...' : 'Submit complaint'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
          ]),
        ),
      ),
    );
  }
}
