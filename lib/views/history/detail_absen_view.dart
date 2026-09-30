import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/absen_model.dart';
import '../../providers/absen_provider.dart';
import '../map/map_view.dart';

class DetailAbsenView extends StatelessWidget {
  final AbsenModel absen;

  const DetailAbsenView({super.key, required this.absen});

  Future<void> _handleDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data Presensi'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus data presensi ini? Tindakan ini tidak dapat dibatalkan.',
        ),
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

    if (confirm != true) return;

    if (context.mounted) {
      final absenProvider = context.read<AbsenProvider>();
      final success = await absenProvider.deleteAbsen(absen.id);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(absenProvider.successMessage ?? 'Data berhasil dihapus'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(absenProvider.errorMessage ?? 'Gagal menghapus data'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Presensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: 'Hapus Presensi',
            onPressed: () => _handleDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: absen.isIzin
                          ? AppColors.warningLight
                          : (absen.isCheckedOut ? AppColors.successLight : AppColors.infoLight),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      absen.isIzin
                          ? Icons.assignment_late
                          : (absen.isCheckedOut ? Icons.task_alt : Icons.login),
                      color: absen.isIzin
                          ? AppColors.warning
                          : (absen.isCheckedOut ? AppColors.success : AppColors.primary),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          absen.formattedDate,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: absen.isIzin
                                ? AppColors.warning.withOpacity(0.15)
                                : AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            absen.isIzin ? 'Status: Permohonan Izin' : 'Status: Hadir / Masuk',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: absen.isIzin ? AppColors.warning : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Alasan Izin (if applicable)
            if (absen.isIzin && absen.alasanIzin != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFFDE68A),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notes, color: AppColors.warning, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Alasan Izin',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      absen.alasanIzin!,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Check In Details
            _buildDetailSection(
              context,
              title: 'Presensi Masuk',
              icon: Icons.login,
              iconColor: AppColors.primary,
              time: absen.checkInTimeDisplay,
              location: absen.checkInAddress ?? 'Lokasi tidak tersedia',
              coordinates: absen.checkInLat != null
                  ? '${absen.checkInLat}, ${absen.checkInLng}'
                  : (absen.checkInLocation ?? '-'),
            ),
            const SizedBox(height: 16),

            // Check Out Details
            if (!absen.isIzin) ...[
              _buildDetailSection(
                context,
                title: 'Presensi Keluar',
                icon: Icons.logout,
                iconColor: AppColors.accent,
                time: absen.checkOutTimeDisplay,
                location: absen.checkOutAddress ?? (absen.isCheckedOut ? 'Lokasi tidak tersedia' : '-'),
                coordinates: absen.checkOutLat != null
                    ? '${absen.checkOutLat}, ${absen.checkOutLng}'
                    : (absen.checkOutLocation ?? '-'),
              ),
              const SizedBox(height: 20),
            ],

            // Interactive Map (Requirement 2.4)
            const Text(
              'Peta Lokasi Presensi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            InteractiveMapView(
              latitude: absen.displayLatitude,
              longitude: absen.displayLongitude,
              address: absen.checkInAddress,
              height: 240,
              showOpenInGoogleMapsButton: true,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required String time,
    required String location,
    required String coordinates,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(
                width: 90,
                child: Text(
                  'Waktu',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
              Expanded(
                child: Text(
                  time,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 90,
                child: Text(
                  'Alamat',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(
                width: 90,
                child: Text(
                  'Koordinat',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
              Expanded(
                child: Text(
                  coordinates,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
