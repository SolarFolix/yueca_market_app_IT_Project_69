import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sales_log_model.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';

class _SalesLog {
  String id;
  DateTime date;
  double revenue;
  int orders;
  String note;

  _SalesLog({
    required this.id,
    required this.date,
    required this.revenue,
    required this.orders,
    this.note = '',
  });
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static const _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  final List<_SalesLog> _logs = [
    _SalesLog(
      id: '1',
      date: DateTime(2026, 7, 27),
      revenue: 4200,
      orders: 18,
      note: 'Busy Monday, ran out of mangoes',
    ),
    _SalesLog(
      id: '2',
      date: DateTime(2026, 7, 29),
      revenue: 3100,
      orders: 12,
    ),
    _SalesLog(
      id: '3',
      date: DateTime(2026, 8, 1),
      revenue: 5400,
      orders: 21,
      note: 'New sign brought in more walk-ins',
    ),
    _SalesLog(
      id: '4',
      date: DateTime(2026, 8, 2),
      revenue: 4700,
      orders: 19,
    ),
  ];

  StreamSubscription<List<SalesLogModel>>? _logsSub;

  bool get _isBackedByFirestore => AuthService.instance.isAvailable;

  double get _totalRevenue => _logs.fold(0, (sum, log) => sum + log.revenue);

  int get _totalOrders => _logs.fold(0, (sum, log) => sum + log.orders);

  double get _averageOrderValue {
    if (_totalOrders == 0) return 0;
    return _totalRevenue / _totalOrders;
  }

  Map<String, double> get _revenueByWeekday {
    final totals = {
      for (final day in _dayLabels) day: 0.0,
    };

    for (final log in _logs) {
      final day = _dayLabels[log.date.weekday - 1];
      totals[day] = (totals[day] ?? 0) + log.revenue;
    }

    return totals;
  }

  @override
  void initState() {
    super.initState();

    if (_isBackedByFirestore) {
      _logsSub = AnalyticsService.instance.watchLogs().listen((models) {
        if (!mounted) return;

        setState(() {
          _logs
            ..clear()
            ..addAll(
              models.map(
                (m) => _SalesLog(
                  id: m.id,
                  date: m.date,
                  revenue: m.revenue,
                  orders: m.orders,
                  note: m.note,
                ),
              ),
            );
        });
      });
    }
  }

  @override
  void dispose() {
    _logsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final revenueByDay = _revenueByWeekday;

    final maxRevenue = revenueByDay.values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Analytics'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openLogEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Sale'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        children: [
          Text(
            'Track your sales activity and revenue.',
            style: AppTextStyles.subheading,
          ),

          const SizedBox(height: 20),

          // ─────────────────────────────────────────
          // OVERVIEW
          // ─────────────────────────────────────────

          Row(
            children: [
              Expanded(
                child: _metricCard(
                  label: 'Revenue',
                  value: '฿${_formatMoney(_totalRevenue)}',
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCard(
                  label: 'Orders',
                  value: '$_totalOrders',
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _wideMetricCard(
            label: 'Average Order Value',
            value: '฿${_formatMoney(_averageOrderValue)}',
            description: 'Average revenue generated per order',
            icon: Icons.receipt_long_outlined,
          ),

          const SizedBox(height: 20),

          // ─────────────────────────────────────────
          // REVENUE CHART
          // ─────────────────────────────────────────

          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Revenue by Day',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${_logs.length} logs',
                      style: AppTextStyles.subheading,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on your sales history',
                  style: AppTextStyles.subheading,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _dayLabels.map((day) {
                      final value = revenueByDay[day] ?? 0;

                      final fraction =
                          maxRevenue == 0 ? 0.0 : value / maxRevenue;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (value > 0)
                                Text(
                                  _compactMoney(value),
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              const SizedBox(height: 5),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: value == 0 ? 4 : 8 + (100 * fraction),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: value == 0
                                      ? AppColors.border
                                      : AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                day,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ─────────────────────────────────────────
          // SALES HISTORY
          // ─────────────────────────────────────────

          Row(
            children: [
              Expanded(
                child: Text(
                  'Sales History',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${_logs.length} entries',
                style: AppTextStyles.subheading,
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (_logs.isEmpty)
            _emptyState()
          else
            ..._logs.reversed.map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _logCard(log),
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(
        currentIndex: 1,
      ),
    );
  }

  // ============================================================
  // METRIC CARDS
  // ============================================================

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.more_horiz,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wideMetricCard({
    required String label,
    required String value,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: child,
    );
  }

  // ============================================================
  // SALES LOG
  // ============================================================

  Widget _logCard(_SalesLog log) {
    final dateLabel = '${log.date.day}/${log.date.month}/${log.date.year}';

    return GestureDetector(
      onTap: () => _openLogEditor(existing: log),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '฿${_formatMoney(log.revenue)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${log.orders} orders'
                    '${log.note.isNotEmpty ? ' · ${log.note}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _openLogEditor(existing: log);
                }

                if (value == 'delete') {
                  _deleteLog(log);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 32,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          Text(
            'No sales recorded yet',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Add Sale" to record your first sale.',
            textAlign: TextAlign.center,
            style: AppTextStyles.subheading,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteLog(_SalesLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete sale?'),
          content: const Text(
            'This sales record will be permanently removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (_isBackedByFirestore) {
      try {
        await AnalyticsService.instance.deleteLog(log.id);
      } catch (_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete sale. Please try again.'),
            backgroundColor: AppColors.danger,
          ),
        );

        return;
      }
    } else {
      setState(() {
        _logs.removeWhere((item) => item.id == log.id);
      });
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sale deleted'),
      ),
    );
  }

  // ============================================================
  // ADD / EDIT LOG
  // ============================================================

  Future<void> _openLogEditor({
    _SalesLog? existing,
  }) async {
    final revenueController = TextEditingController(
      text: existing != null ? existing.revenue.toStringAsFixed(0) : '',
    );

    final ordersController = TextEditingController(
      text: existing != null ? existing.orders.toString() : '',
    );

    final noteController = TextEditingController(
      text: existing?.note ?? '',
    );

    DateTime selectedDate = existing?.date ?? DateTime.now();

    final formKey = GlobalKey<FormState>();

    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            existing == null
                                ? 'Add Sales Record'
                                : 'Edit Sales Record',
                            style: AppTextStyles.heading,
                          ),
                        ),
                        if (existing != null)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.danger,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteLog(existing);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Date',
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );

                        if (picked != null) {
                          setSheetState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: AppTextStyles.body,
                            ),
                            const Spacer(),
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Revenue (฿)',
                      style: AppTextStyles.label,
                    ),
                    TextFormField(
                      controller: revenueController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 3200',
                      ),
                      validator: (value) {
                        final amount = double.tryParse(value ?? '');

                        if (amount == null || amount < 0) {
                          return 'Enter a valid amount';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Orders',
                      style: AppTextStyles.label,
                    ),
                    TextFormField(
                      controller: ordersController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 14',
                      ),
                      validator: (value) {
                        final orders = int.tryParse(value ?? '');

                        if (orders == null || orders < 0) {
                          return 'Enter a valid number';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Note (optional)',
                      style: AppTextStyles.label,
                    ),
                    TextFormField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Anything worth remembering',
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                final revenue = double.parse(
                                  revenueController.text,
                                );

                                final orders = int.parse(
                                  ordersController.text,
                                );

                                final note = noteController.text.trim();

                                if (_isBackedByFirestore) {
                                  setSheetState(() {
                                    isSaving = true;
                                  });

                                  try {
                                    if (existing != null) {
                                      await AnalyticsService.instance.updateLog(
                                        existing.id,
                                        date: selectedDate,
                                        revenue: revenue,
                                        orders: orders,
                                        note: note,
                                      );
                                    } else {
                                      await AnalyticsService.instance.addLog(
                                        date: selectedDate,
                                        revenue: revenue,
                                        orders: orders,
                                        note: note,
                                      );
                                    }
                                  } catch (_) {
                                    setSheetState(() {
                                      isSaving = false;
                                    });

                                    if (!context.mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not save. Please try again.',
                                        ),
                                        backgroundColor: AppColors.danger,
                                      ),
                                    );

                                    return;
                                  }
                                } else {
                                  setState(() {
                                    if (existing != null) {
                                      existing
                                        ..date = selectedDate
                                        ..revenue = revenue
                                        ..orders = orders
                                        ..note = note;
                                    } else {
                                      _logs.add(
                                        _SalesLog(
                                          id: DateTime.now()
                                              .millisecondsSinceEpoch
                                              .toString(),
                                          date: selectedDate,
                                          revenue: revenue,
                                          orders: orders,
                                          note: note,
                                        ),
                                      );
                                    }
                                  });
                                }

                                if (!context.mounted) return;

                                Navigator.pop(context);

                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      existing == null
                                          ? 'Sale recorded'
                                          : 'Sale updated',
                                    ),
                                  ),
                                );
                              },
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                existing == null ? 'Save Sale' : 'Save Changes',
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    revenueController.dispose();
    ordersController.dispose();
    noteController.dispose();
  }

  // ============================================================
  // FORMATTERS
  // ============================================================

  String _formatMoney(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return value.toStringAsFixed(0);
  }

  String _compactMoney(double value) {
    if (value >= 1000) {
      return '฿${(value / 1000).toStringAsFixed(1)}k';
    }

    return '฿${value.toStringAsFixed(0)}';
  }
}
