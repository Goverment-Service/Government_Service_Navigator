import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/verification_models.dart';
import '../../screens/verification_detail_screen.dart';
import '../../services/verification_api_service.dart';
import '../../theme/app_colors.dart';

class ApplicationsTab extends StatefulWidget {
  const ApplicationsTab({super.key});

  @override
  State<ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<ApplicationsTab> {
  List<ApplicationItemModel> _applications = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // 'All', 'In Review', 'Approved', 'Needs Action'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    final apps = await VerificationApiService.fetchApplications();
    if (mounted) {
      setState(() {
        _applications = apps;
        _isLoading = false;
      });
    }
  }

  List<ApplicationItemModel> get _filteredApplications {
    return _applications.where((app) {
      // Filter tab check
      if (_selectedFilter == 'In Review' && app.status.toLowerCase() != 'pending') {
        return false;
      }
      if (_selectedFilter == 'Approved' && app.status.toLowerCase() != 'approved') {
        return false;
      }
      if (_selectedFilter == 'Needs Action' &&
          app.status.toLowerCase() != 'revised' &&
          app.status.toLowerCase() != 'rejected') {
        return false;
      }

      // Search query check
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesRef = app.referenceNumber.toLowerCase().contains(query);
        final matchesService = app.serviceName.toLowerCase().contains(query);
        final matchesCategory = app.category.toLowerCase().contains(query);
        return matchesRef || matchesService || matchesCategory;
      }
      return true;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'revised':
        return AppColors.warning;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Verified';
      case 'revised':
        return 'Action Required';
      case 'rejected':
        return 'Rejected';
      default:
        return 'In Review';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return CupertinoIcons.checkmark_seal_fill;
      case 'revised':
        return CupertinoIcons.exclamationmark_triangle_fill;
      case 'rejected':
        return CupertinoIcons.xmark_circle_fill;
      default:
        return CupertinoIcons.clock_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Applications & Verification',
          style: TextStyle(
            color: AppColors.dark,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.arrow_clockwise, color: AppColors.primary),
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar & Status Chips
          Container(
            color: AppColors.cardBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              children: [
                // iOS-Style Search Field
                CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: 'Search by reference ID or service...',
                  onChanged: (val) => setState(() => _searchQuery = val),
                  onSubmitted: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 12),
                // Filter Segment Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip('All', _applications.length),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'In Review',
                        _applications.where((a) => a.status.toLowerCase() == 'pending').length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Approved',
                        _applications.where((a) => a.status.toLowerCase() == 'approved').length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Needs Action',
                        _applications.where((a) =>
                            a.status.toLowerCase() == 'revised' ||
                            a.status.toLowerCase() == 'rejected').length,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // 2. Application List
          Expanded(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator(radius: 14))
                : RefreshIndicator(
                    onRefresh: _loadApplications,
                    child: _filteredApplications.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _filteredApplications.length,
                            itemBuilder: (context, index) {
                              final app = _filteredApplications[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14.0),
                                child: _buildTrackingCard(app),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String title, int count) {
    final isSelected = _selectedFilter == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.secondaryLabel,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.dark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingCard(ApplicationItemModel app) {
    final statusColor = _getStatusColor(app.status);
    final reviews = app.verificationTask?.reviews ?? [];
    final latestReview = reviews.isNotEmpty ? reviews.last : null;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<ApplicationItemModel>(
          context,
          CupertinoPageRoute(
            builder: (context) => VerificationDetailScreen(application: app),
          ),
        );
        if (result != null) {
          _loadApplications();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Ref ID & Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.doc_text_fill, size: 14, color: AppColors.secondaryLabel),
                    const SizedBox(width: 5),
                    Text(
                      app.referenceNumber,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryLabel,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(app.status), size: 12, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        _getStatusDisplay(app.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Service Title
            Text(
              app.serviceName,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              app.category,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.secondaryLabel,
              ),
            ),

            // Officer feedback preview if available
            if (latestReview != null && latestReview.comments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(left: BorderSide(color: statusColor, width: 3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        latestReview.comments,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.dark,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),

            // Bottom row: Submitted date and Action CTA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Submitted ${app.submittedDate.year}-${app.submittedDate.month.toString().padLeft(2, '0')}-${app.submittedDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryLabel,
                  ),
                ),
                Row(
                  children: const [
                    Text(
                      'View Verification',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(CupertinoIcons.chevron_right, size: 14, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text_search,
              size: 56,
              color: AppColors.secondaryLabel.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Applications Found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try changing your status filter or search keywords.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}