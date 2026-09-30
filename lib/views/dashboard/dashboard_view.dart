import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/absen_provider.dart';
import '../map/map_view.dart';
import 'widgets/attendance_stats_card.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  LocationDataResult? _currentLocation;
  bool _isLoadingLocation = false;
  late Timer _clockTimer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _loadLocation();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(now);
    });
  }

  Future<void> _loadLocation() async {
    setState(() => _isLoadingLocation = true);
    final loc = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _currentLocation = loc;
        _isLoadingLocation = false;
      });
    }
  }

  void _showCheckInDialog() {
    String selectedStatus = 'masuk';
    final alasanController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: bottomInset + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pilih Jenis Presensi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Option Masuk vs Izin
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedStatus = 'masuk'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selectedStatus == 'masuk'
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedStatus == 'masuk'
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.login_rounded,
                                  color: selectedStatus == 'masuk' ? Colors.white : AppColors.primary,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Hadir / Masuk',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: selectedStatus == 'masuk' ? Colors.white : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedStatus = 'izin'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selectedStatus == 'izin'
                                  ? AppColors.warning
                                  : (isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedStatus == 'izin'
                                    ? AppColors.warning
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.assignment_late_outlined,
                                  color: selectedStatus == 'izin' ? Colors.white : AppColors.warning,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Permohonan Izin',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: selectedStatus == 'izin' ? Colors.white : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // If Izin, show Reason text field
                  if (selectedStatus == 'izin') ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Alasan Izin',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: alasanController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Izin sakit dengan surat dokter, atau urusan keluarga...',
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedStatus == 'izin' && alasanController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Alasan izin wajib diisi'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      final absenProvider = context.read<AbsenProvider>();

                      final success = await absenProvider.checkIn(
                        status: selectedStatus,
                        alasanIzin: selectedStatus == 'izin' ? alasanController.text.trim() : null,
                      );

                      if (mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(absenProvider.successMessage ?? 'Absen berhasil dicatat'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(absenProvider.errorMessage ?? 'Gagal absen masuk'),
                              backgroundColor: AppColors.danger,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedStatus == 'masuk' ? AppColors.primary : AppColors.warning,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      selectedStatus == 'masuk' ? 'Konfirmasi Absen Masuk' : 'Kirim Permohonan Izin',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleCheckOut() async {
    final absenProvider = context.read<AbsenProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Absen Pulang'),
        content: const Text('Apakah Anda yakin ingin melakukan absen pulang sekarang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Ya, Absen Pulang'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await absenProvider.checkOut();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(absenProvider.successMessage ?? 'Absen pulang berhasil dicatat'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(absenProvider.errorMessage ?? 'Gagal absen keluar'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final absenProvider = context.watch<AbsenProvider>();
    final user = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = absenProvider.todayAbsen;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              absenProvider.fetchHistory(),
              _loadLocation(),
              authProvider.fetchProfile(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Greeting & Date (Requirement 2.1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormatter.getGreeting()},',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.name.isNotEmpty == true ? user!.name : 'Peserta PPKD',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormatter.formatFullDate(DateTime.now()),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Clock & Today Attendance Status Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Waktu Sekarang',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentTime,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          _buildTodayBadge(absenProvider.todayStatus),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 16),
                      // Check-in and Check-out timestamps
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.login, color: Colors.white70, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Masuk',
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  today?.checkInTimeDisplay ?? '--:--',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.logout, color: Colors.white70, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Keluar',
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  today?.checkOutTimeDisplay ?? '--:--',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Quick Action Attendance Buttons (Requirement 2.2)
                const Text(
                  'Aksi Presensi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Button Absen Masuk
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (absenProvider.isSubmitting ||
                                absenProvider.todayStatus == 'masuk' ||
                                absenProvider.todayStatus == 'selesai' ||
                                absenProvider.todayStatus == 'izin')
                            ? null
                            : _showCheckInDialog,
                        icon: const Icon(Icons.fingerprint, size: 22),
                        label: const Text('Absen Masuk'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Button Absen Pulang
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (absenProvider.isSubmitting ||
                                absenProvider.todayStatus != 'masuk')
                            ? null
                            : _handleCheckOut,
                        icon: const Icon(Icons.time_to_leave, size: 22),
                        label: const Text('Absen Pulang'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          disabledBackgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (absenProvider.isSubmitting) ...[
                  const SizedBox(height: 12),
                  const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Sedang memproses absensi...',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // 4. Statistics Card (Requirement 2.5)
                AttendanceStatsCard(
                  totalAbsen: absenProvider.totalAbsen,
                  totalMasuk: absenProvider.totalMasuk,
                  totalIzin: absenProvider.totalIzin,
                  totalSelesai: absenProvider.totalSelesai,
                  percentage: absenProvider.attendancePercentage,
                ),
                const SizedBox(height: 24),

                // 5. Current GPS Location & Interactive Map Preview (Requirements 2.3 & 2.4)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lokasi Anda Saat Ini',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: _isLoadingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 20),
                      onPressed: _isLoadingLocation ? null : _loadLocation,
                      tooltip: 'Perbarui Lokasi GPS',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_pin, color: AppColors.danger, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _currentLocation?.address ?? 'Mencari lokasi GPS...',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_currentLocation != null)
                  InteractiveMapView(
                    latitude: _currentLocation!.latitude,
                    longitude: _currentLocation!.longitude,
                    height: 180,
                    showOpenInGoogleMapsButton: true,
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayBadge(String status) {
    String label;
    Color color;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'masuk':
        label = 'Sudah Masuk';
        color = Colors.white;
        textColor = AppColors.primary;
        icon = Icons.check_circle;
        break;
      case 'izin':
        label = 'Sedang Izin';
        color = AppColors.warning;
        textColor = Colors.black87;
        icon = Icons.assignment_late;
        break;
      case 'selesai':
        label = 'Sudah Pulang';
        color = Colors.white;
        textColor = AppColors.primary;
        icon = Icons.task_alt;
        break;
      default:
        label = 'Belum Absen';
        color = Colors.white.withOpacity(0.2);
        textColor = Colors.white;
        icon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
