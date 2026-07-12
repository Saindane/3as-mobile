import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../providers/bill_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

class GenerateBillsScreen extends ConsumerStatefulWidget {
  const GenerateBillsScreen({super.key});

  @override
  ConsumerState<GenerateBillsScreen> createState() => _GenerateBillsScreenState();
}

class _GenerateBillsScreenState extends ConsumerState<GenerateBillsScreen> {
  final _maintenanceCtr = TextEditingController(text: '2000');
  int _selectedMonth = DateTime.now().month;
  int _selectedYear  = DateTime.now().year;
  DateTime _dueDate  = DateTime.now().add(const Duration(days: 10));
  bool _includePenalty = true;

  static const _months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];

  @override
  void dispose() {
    _maintenanceCtr.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    final maintenance = double.tryParse(_maintenanceCtr.text);
    if (maintenance == null || maintenance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid maintenance amount'),
            backgroundColor: AppColors.error));
      return;
    }

    await ref.read(generateBillsProvider.notifier).generate(
      month: _selectedMonth,
      year: _selectedYear,
      maintenance: maintenance,
      dueDate: _dueDate.toIso8601String().split('T')[0],
      includepenalty: _includePenalty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generateBillsProvider);

    ref.listen(generateBillsProvider, (_, next) {
      if (next.result != null) {
        // Invalidate all bill providers so fresh data loads immediately
        ref.invalidate(allBillsProvider);
        ref.invalidate(myBillsProvider);
        ref.invalidate(collectionSummaryProvider);
        ref.invalidate(dashboardStatsProvider);
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.error));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Generate bills')),
      body: state.result != null
          ? _SuccessView(result: state.result!, onDone: () => Navigator.pop(context))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('New billing cycle', style: AppTextStyles.heading3),
                const SizedBox(height: 4),
                Text('Bills will be generated for every active unit.',
                    style: AppTextStyles.body),
                const SizedBox(height: 20),

                // Month + Year
                Row(children: [
                  Expanded(child: _FieldLabel(
                    label: 'Month',
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: const InputDecoration(),
                      items: List.generate(12, (i) => DropdownMenuItem(
                        value: i + 1, child: Text(_months[i]))),
                      onChanged: (v) => setState(() => _selectedMonth = v!),
                    ),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _FieldLabel(
                    label: 'Year',
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: const InputDecoration(),
                      items: [2024, 2025, 2026].map((y) =>
                          DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                      onChanged: (v) => setState(() => _selectedYear = v!),
                    ),
                  )),
                ]),
                const SizedBox(height: 14),

                // Maintenance amount
                _FieldLabel(
                  label: 'Maintenance amount (₹)',
                  child: TextFormField(
                    controller: _maintenanceCtr,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(prefixText: '₹ '),
                  ),
                ),
                const SizedBox(height: 14),

                // Due date
                _FieldLabel(
                  label: 'Due date',
                  child: InkWell(
                    onTap: _pickDueDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(),
                      child: Row(children: [
                        Text(
                          '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                          style: AppTextStyles.bodyBold,
                        ),
                        const Spacer(),
                        const Icon(Icons.calendar_today_outlined,
                            size: 16, color: AppColors.textMuted),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Include penalty switch
                AppCard(child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include existing penalties', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Carry forward unpaid penalties into new bill',
                      style: TextStyle(fontSize: 11)),
                  value: _includePenalty,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _includePenalty = v),
                )),

                const SizedBox(height: 20),

                // Preview box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bills will be created for all properties without an existing bill for ${_months[_selectedMonth - 1]} $_selectedYear.',
                        style: AppTextStyles.body.copyWith(color: AppColors.primaryDark, fontSize: 12),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: state.isLoading ? null : _submit,
                  icon: state.isLoading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.bolt, size: 18),
                  label: Text(state.isLoading ? 'Generating...' : 'Generate bills'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),
              ],
            ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldLabel({required this.label, required this.child});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.label),
      const SizedBox(height: 6),
      child,
    ],
  );
}

class _SuccessView extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback onDone;
  const _SuccessView({required this.result, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final generated = result['generated'] as int;
    final skipped   = result['skipped'] as int;
    final total     = (result['total_amount'] as num).toDouble();
    final details   = (result['details'] as List).cast<String>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(child: Column(children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: AppColors.success, size: 36),
          ),
          const SizedBox(height: 14),
          Text('Bills generated', style: AppTextStyles.heading2),
          const SizedBox(height: 6),
          Text('$generated bills created · $skipped skipped',
              style: AppTextStyles.body, textAlign: TextAlign.center),
        ])),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: StatCard(label: 'Generated', value: '$generated',
              color: AppColors.success, icon: Icons.check_circle_outline)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(label: 'Total amount', value: '₹${total.toStringAsFixed(0)}',
              color: AppColors.primary, icon: Icons.payments_outlined)),
        ]),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Details'),
        const SizedBox(height: 8),
        AppCard(child: Column(
          children: details.take(10).map((d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              const Icon(Icons.circle, size: 5, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(child: Text(d, style: AppTextStyles.caption)),
            ]),
          )).toList(),
        )),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onDone,
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
