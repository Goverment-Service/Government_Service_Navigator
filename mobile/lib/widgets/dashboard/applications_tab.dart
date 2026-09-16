import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../models/application.dart';
import '../../services/application_service.dart';
import '../../screens/applications/application_detail_screen.dart';

class ApplicationsTab extends StatefulWidget {
  const ApplicationsTab({super.key});

  @override
  State<ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<ApplicationsTab> {
  final _applicationService = ApplicationService();
  List<ServiceApplication> _applications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final applications = await _applicationService.fetchMyApplications();
      if (!mounted) return;
      setState(() {
        _applications = applications;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your applications.';
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.success;
      case 'Rejected':
        return AppColors.danger;
      case 'Revised':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  Map<String, List<ServiceApplication>> _groupByDepartment() {
    final groups = <String, List<ServiceApplication>>{};
    for (final app in _applications) {
      groups.putIfAbsent(app.department.isEmpty ? 'Other' : app.department, () => []).add(app);
    }
    for (final list in groups.values) {
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDepartment();
    final departments = groups.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Applications'),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : _error != null
                ? ListView(children: [Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(_error!)))])
                : _applications.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: Text('You haven\'t submitted any applications yet.')),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: departments.length,
                        itemBuilder: (context, index) {
                          final department = departments[index];
                          final apps = groups[department]!;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10, left: 4),
                                  child: Row(
                                    children: [
                                      Text(
                                        department,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.divider,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text('${apps.length}', style: const TextStyle(fontSize: 12, color: AppColors.secondaryLabel)),
                                      ),
                                    ],
                                  ),
                                ),
                                ...apps.map((app) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: GestureDetector(
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => ApplicationDetailScreen(application: app)),
                                        ),
                                        child: _buildTrackingCard(app),
                                      ),
                                    )),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildTrackingCard(ServiceApplication app) {
    final statusColor = _statusColor(app.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                app.applicationReference,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondaryLabel),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  app.status,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(app.serviceName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.dark)),
          const SizedBox(height: 8),
          Text(
            'Submitted ${app.submittedAt.year}-${app.submittedAt.month.toString().padLeft(2, '0')}-${app.submittedAt.day.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 13, color: AppColors.secondaryLabel),
          ),
          if (app.decisionNotes != null && app.decisionNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(app.decisionNotes!, style: const TextStyle(fontSize: 13, color: AppColors.secondaryLabel)),
          ],
        ],
      ),
    );
  }
}
