import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/absen_model.dart';
import '../../providers/absen_provider.dart';
import 'detail_absen_view.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AbsenProvider>().fetchHistory();
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      if (mounted) {
        await context.read<AbsenProvider>().fetchHistory(
          start: picked.start,
          end: picked.end,
        );
      }
    }
  }

  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    context.read<AbsenProvider>().fetchHistory();
  }

  Future<void> _confirmDelete(BuildContext context, AbsenModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Presensi'),
        content: Text('Hapus riwayat presensi tanggal ${item.formattedShortDate}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final absenProvider = context.read<AbsenProvider>();
      final success = await absenProvider.deleteAbsen(item.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Riwayat presensi berhasil dihapus'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(absenProvider.errorMessage ?? 'Gagal menghapus'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final absenProvider = context.watch<AbsenProvider>();
    final history = absenProvider.history;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Presensi'),
        actions: [
          if (_startDate != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Reset Filter',
              onPressed: _clearFilter,
            ),
          IconButton(
            icon: Icon(
              Icons.date_range,
              color: _startDate != null ? AppColors.primary : null,
            ),
            tooltip: 'Filter Tanggal',
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => absenProvider.fetchHistory(
          start: _startDate,
          end: _endDate,
        ),
        child: Column(
          children: [
            // Filter info banner if active
            if (_startDate != null && _endDate != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.primary.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Filter: ${DateFormatter.formatShortDate(_startDate!)} - ${DateFormatter.formatShortDate(_endDate!)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _clearFilter,
                      child: const Text(
                        'Hapus',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // History List
            Expanded(
              child: absenProvider.isLoadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : history.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          itemCount: history.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = history[index];
                            return _buildHistoryCard(context, item, isDark);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 72,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Riwayat Presensi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Data absensi masuk dan keluar Anda akan tercatat secara otomatis di halaman ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, AbsenModel item, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailAbsenView(absen: item),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Date, Status Badge, and Delete Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.formattedDate,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.isIzin
                            ? AppColors.warningLight
                            : (item.isCheckedOut ? AppColors.successLight : AppColors.infoLight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.statusDisplay,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: item.isIzin
                              ? AppColors.warning
                              : (item.isCheckedOut ? AppColors.success : AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                      tooltip: 'Hapus',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmDelete(context, item),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),

            // Time & Location Details (Requirement 3.2)
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.login, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jam Masuk',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            item.checkInTimeDisplay,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jam Keluar',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            item.checkOutTimeDisplay,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.checkInAddress ?? 'Lokasi tidak tersedia',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (item.isIzin && item.alasanIzin != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Alasan: ${item.alasanIzin}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
