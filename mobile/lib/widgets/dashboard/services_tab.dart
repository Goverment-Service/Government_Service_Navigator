import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../services/service_api_client.dart';
import '../../services/application_service.dart';
import '../../screens/procedure_detail_screen.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  final _applicationService = ApplicationService();
  List services = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final data = await ServiceApiClient.fetchServices();
      // Only show services a Verifying Officer has actually built an
      // application form for - not the raw, unfiltered Service Catalog.
      final templatedIds = await _applicationService.fetchServiceIdsWithActiveTemplate();
      setState(() {
        services = data.where((s) => templatedIds.contains(s['id'])).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Applications'),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : services.isEmpty
              ? const Center(child: Text('No application forms are available yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    final fees = service['feeSchedules'] ?? [];
                    final feeString = fees.isNotEmpty ? 'LKR ${fees[0]['amount']}' : 'Free';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProcedureDetailScreen(serviceId: service['id']),
                            ),
                          );
                        },
                        child: _buildServiceItem(
                          title: service['name'] ?? 'Untitled Service',
                          category: service['category'] ?? 'General',
                          fee: feeString,
                          icon: CupertinoIcons.briefcase,
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildServiceItem({
    required String title,
    required String category,
    required String fee,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fee,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: AppColors.secondaryLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
