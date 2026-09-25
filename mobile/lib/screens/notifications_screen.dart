import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/application_providers.dart';
import '../services/notification_api_service.dart';
import '../theme/app_colors.dart';
import '../theme/glass_theme.dart';
import 'payments/installment_plan_view.dart';

/// The citizen's notifications. Opening the screen marks them all as read;
/// tapping an installment notification opens that plan's schedule.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // The badge may have cached an older list; always fetch fresh on open
    Future.microtask(_load);
  }

  /// Fetches fresh notifications, then clears the unread flags server-side. The loaded
  /// items keep their highlight until the next refresh.
  Future<void> _load() async {
    if (!mounted) return;
    try {
      final items = await ref.refresh(notificationsProvider.future);
      if (mounted && items.any((n) => !n.isRead)) {
        await ref.read(notificationsProvider.notifier).markAllRead();
      }
    } catch (_) {
      // The error is shown from the provider state
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuroraBackdrop(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Notifications'), backgroundColor: Colors.transparent, elevation: 0),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(ref.watch(notificationsProvider)),
      ),
    ),
    );
  }

  Widget _buildBody(AsyncValue<List<CitizenNotification>> notifications) {
    if (notifications.hasError) {
      return ListView(children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            notifications.error.toString().replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ]);
    }
    final items = notifications.value;
    if (items == null) return const Center(child: CupertinoActivityIndicator());
    if (items.isEmpty) {
      return ListView(children: const [
        Padding(
          padding: EdgeInsets.all(48),
          child: Text('No notifications yet.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.secondaryLabel)),
        ),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildTile(items[i]),
    );
  }

  Widget _buildTile(CitizenNotification n) {
    final isCancellation = n.type == 'ApplicationCancelled';
    final color = isCancellation ? AppColors.danger : AppColors.warning;
    final created = n.createdAt;
    String two(int v) => v.toString().padLeft(2, '0');

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: n.installmentPlanId == null || isCancellation
          ? null
          : () => Navigator.of(context).push(CupertinoPageRoute(
                builder: (_) => InstallmentPlanView(planId: n.installmentPlanId.toString()),
              )),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.isRead ? AppColors.cardBg : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: n.isRead ? AppColors.divider : color.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(isCancellation ? CupertinoIcons.xmark_octagon_fill : CupertinoIcons.bell_fill, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(n.message, style: const TextStyle(fontSize: 13, height: 1.35)),
                  const SizedBox(height: 6),
                  Text(
                    '${created.year}-${two(created.month)}-${two(created.day)} ${two(created.hour)}:${two(created.minute)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.secondaryLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
