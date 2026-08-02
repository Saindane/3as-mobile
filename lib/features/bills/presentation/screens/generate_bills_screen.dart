import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../providers/bill_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

class GenerateBillsScreen extends ConsumerStatefulWidget {
  const GenerateBillsScreen({super.key});

  @override
  ConsumerState<GenerateBillsScreen> createState() =>
      _GenerateBillsScreenState();
}

class _GenerateBillsScreenState extends ConsumerState<GenerateBillsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Form fields
  int    _month       = DateTime.now().month;
  int    _year        = DateTime.now().year;
  double _maintenance = 2000;
  bool   _includePenalty = true;
  DateTime get _defaultDueDate {
    // Handle December → due date is January of next year
    final dueMonth = _month == 12 ? 1 : _month + 1;
    final dueYear  = _month == 12 ? _year + 1 : _year;
    return DateTime(dueYear, dueMonth, 10);
  }
  late DateTime _dueDate;

  // Specific unit
  int?   _selectedPropertyId;
  String _selectedUnitNo = '';
  String _searchQuery   = '';
  late TextEditingController _maintenanceCtr;
  bool   _isLoading     = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dueDate = DateTime.now().month == 12
        ? DateTime(DateTime.now().year + 1, 1, 10)
        : DateTime(DateTime.now().year, DateTime.now().month + 1, 10);
    _maintenanceCtr = TextEditingController(text: _maintenance.toStringAsFixed(0));
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {
      _selectedPropertyId = null;
      _selectedUnitNo = '';
      _result = null;
      _error  = null;
    }));
  }

  @override
  void dispose() { _tabs.dispose(); _maintenanceCtr.dispose(); super.dispose(); }

  Future<void> _generate() async {
    // Validate specific unit mode
    if (_tabs.index == 1 && _selectedPropertyId == null) {
      setState(() => _error = 'Please select a unit first');
      return;
    }

    setState(() { _isLoading = true; _result = null; _error = null; });

    try {
      final client = ref.read(dioClientProvider);
      final body = {
        'month':           _month,
        'year':            _year,
        'maintenance':     _maintenance,
        'due_date':        '${_dueDate.year}-${_dueDate.month.toString().padLeft(2,'0')}-${_dueDate.day.toString().padLeft(2,'0')}',
        'include_penalty': _includePenalty,
        if (_tabs.index == 1 && _selectedPropertyId != null)
          'property_id': _selectedPropertyId,
      };

      final res = await client.post(ApiEndpoints.generateBills, data: body);
      final data = res.data as Map<String, dynamic>;

      // Refresh providers
      ref.invalidate(allBillsProvider);
      ref.invalidate(myBillsProvider);
      ref.invalidate(dashboardStatsProvider);

      // Check if all bills were skipped
      if (data['generated'] == 0 && (data['skipped'] ?? 0) > 0) {
        setState(() {
          _error = 'Bills already generated for this period. ${data['skipped']} bill(s) skipped.';
          _isLoading = false;
        });
      } else {
        setState(() { _result = data; _isLoading = false; });
      }
    } catch (e) {
      final msg = e.toString().toLowerCase().contains('not found')
          ? 'Unit not found. Please select a valid unit.'
          : e.toString().toLowerCase().contains('404')
              ? 'Unit not found.'
              : 'Failed to generate bills. Please try again.';
      setState(() { _error = msg; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Generate bills'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.apartment, size: 18), text: 'All units'),
            Tab(icon: Icon(Icons.search, size: 18),    text: 'Specific unit'),
          ],
        ),
      ),
      body: Column(children: [
        Expanded(child: TabBarView(
          controller: _tabs,
          children: [
            _buildForm(specificMode: false),
            _buildForm(specificMode: true),
          ],
        )),
      ]),
    );
  }

  Widget _buildForm({required bool specificMode}) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      // ── Bill details card ──────────────────────────────
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(title: 'Bill details'),
        const SizedBox(height: 12),

        // Month & Year
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Month', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            DropdownButtonFormField<int>(
              value: _month,
              decoration: const InputDecoration(border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              items: List.generate(12, (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(_monthName(i + 1)))),
              onChanged: (v) => setState(() {
                _month = v!;
                _dueDate = _defaultDueDate;
              }),
            ),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Year', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            TextFormField(
              initialValue: _year.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              onChanged: (v) => setState(() {
                _year = int.tryParse(v) ?? _year;
                _dueDate = _defaultDueDate;
              }),
            ),
          ])),
        ]),

        const SizedBox(height: 12),

        // Maintenance & Due date
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Maintenance (₹)', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _maintenanceCtr,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixText: '₹ ',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => setState(() => _maintenance = double.tryParse(v) ?? _maintenance),
            ),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Due date', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Text('${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                      style: const TextStyle(fontSize: 14)),
                ]),
              ),
            ),
          ])),
        ]),

        const SizedBox(height: 12),

        // Include penalty toggle
        Row(children: [
          Switch(
            value: _includePenalty,
            onChanged: (v) => setState(() => _includePenalty = v),
            activeColor: AppColors.primary,
          ),
          const SizedBox(width: 8),
          const Expanded(child: Text('Include pending penalties from previous months',
              style: TextStyle(fontSize: 13))),
        ]),
      ])),

      const SizedBox(height: 12),

      // ── Specific unit selector ─────────────────────────
      if (specificMode)
        _buildUnitSelector(),

      // ── All units info ─────────────────────────────────
      if (!specificMode)
        AppCard(child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.apartment, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('All units', style: TextStyle(fontWeight: FontWeight.w700)),
            Text('Bills will be generated for every unit.\nUnits with existing bills will be skipped.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ])),
        ])),

      const SizedBox(height: 12),

      // ── Error message ──────────────────────────────────
      if (_error != null)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13))),
          ]),
        ),

      const SizedBox(height: 12),

      // ── Result ────────────────────────────────────────
      if (_result != null)
        AppCard(
          borderColor: AppColors.success.withOpacity(.5),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 22),
              const SizedBox(width: 8),
              Text('Bills generated successfully!',
                  style: AppTextStyles.bodyBold
                      .copyWith(color: AppColors.success)),
            ]),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _ResultRow(label: 'Generated', value: '${_result!['generated']} bill(s)'),
            _ResultRow(label: 'Skipped',   value: '${_result!['skipped']} (already existed)'),
            _ResultRow(label: 'Total amount',
                value: '₹${(_result!['total_amount'] as num).toStringAsFixed(0)}'),
            if (_result!['details'] != null && (_result!['details'] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Details:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              ...(_result!['details'] as List).take(5).map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $d',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              )),
            ],
          ]),
        ),

      const SizedBox(height: 16),

      // ── Generate button ────────────────────────────────
      ElevatedButton.icon(
        onPressed: _isLoading ? null : _generate,
        icon: _isLoading
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.receipt_long_outlined, size: 18),
        label: Text(_isLoading
            ? 'Generating...'
            : specificMode && _selectedUnitNo.isNotEmpty
                ? 'Generate bill for Unit $_selectedUnitNo'
                : 'Generate bills for ${_monthName(_month)} $_year'),
        style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48)),
      ),

      const SizedBox(height: 20),
    ]);
  }

  Widget _buildUnitSelector() {
    final propertiesAsync = ref.watch(propertiesListProvider);

    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: 'Select unit'),
      const SizedBox(height: 10),

      // Search
      TextFormField(
        decoration: const InputDecoration(
          hintText: 'Search by unit number or owner...',
          prefixIcon: Icon(Icons.search, size: 18),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      ),

      const SizedBox(height: 10),

      // Property list
      propertiesAsync.when(
        loading: () => const Center(
            child: Padding(padding: EdgeInsets.all(16),
                child: CircularProgressIndicator())),
        error: (e, _) => Text('Error loading properties: $e',
            style: const TextStyle(color: AppColors.error)),
        data: (properties) {
          final filtered = properties.where((p) {
            final unit  = (p['unit_no'] ?? '').toString().toLowerCase();
            final owner = (p['owner']?['name'] ?? '').toString().toLowerCase();
            return _searchQuery.isEmpty ||
                unit.contains(_searchQuery) ||
                owner.contains(_searchQuery);
          }).toList();

          if (filtered.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No units found', style: TextStyle(color: AppColors.textMuted)),
            );
          }

          return Column(children: filtered.map((p) {
            final propId = p['property_id'] as int;
            final unitNo = p['unit_no'] as String;
            final floor  = p['floor'];
            final owner  = p['owner']?['name'] as String?;
            final isSelected = _selectedPropertyId == propId;

            return GestureDetector(
              onTap: () => setState(() {
                _selectedPropertyId = propId;
                _selectedUnitNo     = unitNo;
                _result = null;
                _error  = null;
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryLight
                      : AppColors.surface,
                  border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.slate100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.apartment,
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textMuted),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Unit $unitNo',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.text)),
                    Text(
                      owner != null
                          ? '$owner · Floor $floor'
                          : 'No owner · Floor $floor',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ])),
                  if (isSelected)
                    const Icon(Icons.check_circle,
                        color: AppColors.primary, size: 20),
                ]),
              ),
            );
          }).toList());
        },
      ),
    ]));
  }

  String _monthName(int m) => [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ][m];
}

class _ResultRow extends StatelessWidget {
  final String label, value;
  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
