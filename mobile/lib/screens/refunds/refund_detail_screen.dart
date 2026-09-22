import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../services/refund_service.dart';
import '../../models/refund.dart';
import '../../widgets/refund_tracker_widget.dart';

class RefundDetailScreen extends StatefulWidget {
  final String? token;
  final String? refundId;

  const RefundDetailScreen({
    super.key,
    this.token,
    this.refundId,
  });

  @override
  State<RefundDetailScreen> createState() => _RefundDetailScreenState();
}

class _RefundDetailScreenState extends State<RefundDetailScreen> {
  Refund? _refund;
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

  String get _effectiveRefundId {
    if (widget.refundId != null && widget.refundId!.isNotEmpty) {
      return widget.refundId!;
    }
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is Map<String, dynamic>) {
      if (routeArgs.containsKey('refundId')) {
        return routeArgs['refundId']?.toString() ?? '';
      }
      if (routeArgs.containsKey('id')) {
        return routeArgs['id']?.toString() ?? '';
      }
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRefund();
    });
  }

  Future<void> _loadRefund() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final rId = _effectiveRefundId;
    if (rId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No refund ID specified.';
      });
      return;
    }

    try {
      final service = RefundService(_effectiveToken);
      final refund = await service.getRefund(rId);

      // Also try fetching status endpoint GET /api/refunds/{id}/status to ensure latest status
      try {
        final freshStatus = await service.getRefundStatus(rId);
        if (mounted) {
          // If fresh status differs, update
          final updated = RefundRequest(
            id: refund.id,
            paymentId: refund.paymentId,
            refundAmount: refund.refundAmount,
            reason: refund.reason,
            status: freshStatus,
            refundTransactionRef: refund.refundTransactionRef,
            requestedByEmail: refund.requestedByEmail,
            decidedByEmail: refund.decidedByEmail,
            decisionNote: refund.decisionNote,
            requestedDate: refund.requestedDate,
            decidedDate: refund.decidedDate,
            completedDate: refund.completedDate,
          );
          if (mounted) setState(() => _refund = updated);
        } else if (mounted) {
          setState(() => _refund = refund);
        }
      } catch (_) {
        if (mounted) setState(() => _refund = refund);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final parsed = DateTime.parse(raw);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[parsed.month - 1]} ${parsed.day.toString().padLeft(2, '0')}, ${parsed.year}';
    } catch (_) {
      return raw.contains('T') ? raw.split('T')[0] : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Refund Tracking'),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.chevron_left, color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 14))
            : _errorMessage != null
                ? _buildError()
                : _buildContent(),
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
            Text(
              _errorMessage ?? 'Failed to load refund details.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryLabel, fontSize: 14),
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              onPressed: _loadRefund,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final r = _refund!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual Stepper / Progress Tracker Widget
          RefundTrackerWidget(
            status: r.status,
            decisionNote: r.decisionNote,
          ),
          const SizedBox(height: 20),

          // Detail rows card
          _buildDetailCard([
            _detailRow('Refund ID', r.id),
            _detailRow('Payment ID', r.paymentId),
            _detailRow('Refund Amount', 'LKR ${r.refundAmount.toStringAsFixed(2)}'),
            if (r.reason != null && r.reason!.isNotEmpty)
              _detailRow('Reason', r.reason!),
            if (r.requestedDate != null && r.requestedDate!.isNotEmpty)
              _detailRow('Requested Date', _formatDate(r.requestedDate)),
            if (r.decidedByEmail != null && r.decidedByEmail!.isNotEmpty)
              _detailRow('Decided By', r.decidedByEmail!),
            if (r.decidedDate != null && r.decidedDate!.isNotEmpty)
              _detailRow('Decided Date', _formatDate(r.decidedDate)),
            if (r.completedDate != null && r.completedDate!.isNotEmpty)
              _detailRow('Completed Date', _formatDate(r.completedDate)),
            if (r.refundTransactionRef != null && r.refundTransactionRef!.isNotEmpty)
              _detailRow('Transaction Ref', r.refundTransactionRef!),
          ]),
        ],
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> rows) {
    return Container(
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
        children: List.generate(rows.length, (i) {
          return Column(
            children: [
              rows[i],
              if (i < rows.length - 1)
                const Divider(height: 1, color: AppColors.divider, indent: 16),
            ],
          );
        }),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.secondaryLabel, fontSize: 14),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.dark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

