import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../services/refund_service.dart';
import '../../models/refund.dart';
import '../../widgets/status_badge.dart';
import 'refund_detail_screen.dart';
import 'refund_request_screen.dart';

class MyRefundsScreen extends StatefulWidget {
  final String? token;

  const MyRefundsScreen({super.key, this.token});

  @override
  State<MyRefundsScreen> createState() => _MyRefundsScreenState();
}

class _MyRefundsScreenState extends State<MyRefundsScreen> {
  List<RefundRequest> _refunds = [];
  bool _isLoading = true;
  String? _errorMessage;

  String get _effectiveToken {
    if (widget.token != null && widget.token!.isNotEmpty) {
      return widget.token!;
    }
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is Map<String, dynamic> && routeArgs.containsKey('token')) {
      return routeArgs['token']?.toString() ?? '';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRefunds();
    });
  }

  Future<void> _loadRefunds() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final service = RefundService(_effectiveToken);
      final list = await service.myRefunds();
      if (mounted) setState(() => _refunds = list);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Refunds'),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.chevron_left, color: AppColors.primary),
        ),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.only(right: 16),
            onPressed: () async {
              await Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => RefundRequestScreen(token: _effectiveToken),
                ),
              );
              if (mounted) _loadRefunds();
            },
            child: const Icon(CupertinoIcons.add, color: AppColors.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : _errorMessage != null
                ? _buildError()
                : _refunds.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoActivityIndicator(radius: 14),
          SizedBox(height: 12),
          Text(
            'Loading refund requests...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle_fill,
                color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to load refunds',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Failed to load refund requests.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryLabel, fontSize: 14),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              onPressed: _loadRefunds,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: _loadRefunds,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.arrow_uturn_left_circle_fill,
                      color: AppColors.primary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No refund requests yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You have not submitted any refund requests yet. Tap + to create one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.secondaryLabel),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadRefunds,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _refunds.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final r = _refunds[index];
          return Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => RefundDetailScreen(
                        token: _effectiveToken,
                        refundId: r.id,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          CupertinoIcons.arrow_uturn_left,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment #${r.paymentId}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'LKR ${r.refundAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.secondaryLabel,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (r.reason != null && r.reason!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                r.reason!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryLabel,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      StatusBadge(status: r.status),
                      const SizedBox(width: 6),
                      const Icon(
                        CupertinoIcons.chevron_right,
                        size: 14,
                        color: AppColors.secondaryLabel,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

