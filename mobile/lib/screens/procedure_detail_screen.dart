import 'dart:convert';
import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/catalog_providers.dart';
import '../providers/session_provider.dart';
import '../providers/application_providers.dart';
import '../models/verification_models.dart';
import '../widgets/service_roadmap_tracker.dart';
import 'eligibility_self_check_screen.dart';
import 'application_form_screen.dart';
import 'verification_detail_screen.dart';
import 'payments/payment_screen.dart';

class ProcedureDetailScreen extends ConsumerWidget {
  final int serviceId;
  const ProcedureDetailScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(serviceDetailsProvider(serviceId));
    final isSignedIn = ref.watch(sessionProvider.select((s) => s.isSignedIn));
    final myAppsAsync = ref.watch(myApplicationsProvider);
    final myApps = myAppsAsync.value ?? const <ApplicationItemModel>[];

    if (details.isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final serviceDetails = details.value;
    if (serviceDetails == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Failed to load details')),
      );
    }

    final activeApp = myApps.cast<ApplicationItemModel?>().firstWhere(
      (a) => a != null && (a.serviceProcedureId == serviceId || 
          a.serviceName.trim().toLowerCase() == (serviceDetails['name']?.toString() ?? '').trim().toLowerCase()),
      orElse: () => null,
    );

    final docs = serviceDetails['documentRequirements'] ?? [];
    final fees = serviceDetails['feeSchedules'] ?? [];

    List<String> workflowDepts = [];
    final rawDepts = serviceDetails['workflowDepartments'];
    if (rawDepts is List) {
      workflowDepts = rawDepts.map((e) => e.toString()).toList();
    } else if (rawDepts is String && rawDepts.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawDepts);
        if (decoded is List) {
          workflowDepts = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    final totalStages = (serviceDetails['totalStages'] as num?)?.toInt() ?? 
                        (workflowDepts.isNotEmpty ? workflowDepts.length : 1);

    return Scaffold(
      appBar: AppBar(title: Text(serviceDetails['name'])),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myApplicationsProvider);
          ref.invalidate(serviceDetailsProvider(serviceId));
          await ref.read(myApplicationsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Service ID: ${serviceDetails['serviceId']}',
              style: const TextStyle(color: AppColors.secondaryLabel),
            ),
            const SizedBox(height: 14),

            // Dynamic Multi-Department Verification Roadmap Tracker
            if (totalStages > 1 || workflowDepts.isNotEmpty || activeApp != null) ...[
              ServiceRoadmapTracker(
                currentStage: activeApp?.currentStage ?? 1,
                maxStages: activeApp != null && activeApp.maxStages > 1 ? activeApp.maxStages : totalStages,
                stageStatus: activeApp?.stageStatus ?? 'NotStarted',
                stageDepartments: workflowDepts.isNotEmpty ? workflowDepts : activeApp?.workflowDepartments,
                currentDepartment: activeApp?.currentDepartment ?? (workflowDepts.isNotEmpty ? workflowDepts[0] : null),
                fillStageFormButtonText: 'Fill Stage ${activeApp?.currentStage ?? 1} Form for ${activeApp?.currentDepartment ?? (workflowDepts.isNotEmpty && (activeApp?.currentStage ?? 1) - 1 < workflowDepts.length ? workflowDepts[(activeApp?.currentStage ?? 1) - 1] : "Next Dept")}',
                onFillStageFormTap: (activeApp != null && (activeApp.stageStatus == 'StageApproved' || activeApp.stageStatus.endsWith('Unlocked')))
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ApplicationFormScreen(
                              serviceId: serviceId,
                              serviceName: serviceDetails['name'] ?? 'Government Service',
                              stageNumber: activeApp.currentStage,
                              applicationId: activeApp.applicationId,
                            ),
                          ),
                        ).then((_) => ref.invalidate(myApplicationsProvider));
                      }
                    : null,
                onActionTap: activeApp != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VerificationDetailScreen(application: activeApp),
                          ),
                        ).then((_) => ref.invalidate(myApplicationsProvider));
                      }
                    : null,
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              'Required Documents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (docs.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  'You will upload these in the application form after tapping Apply Now.',
                  style: TextStyle(color: AppColors.secondaryLabel, fontSize: 13),
                ),
              ),
            ...docs.map<Widget>(
              (doc) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(doc['documentName']),
                subtitle: (doc['description'] ?? '').toString().isEmpty ? null : Text(doc['description']),
                trailing: Text(
                  doc['isMandatory'] == true ? 'Required' : 'Optional',
                  style: TextStyle(
                    fontSize: 12,
                    color: doc['isMandatory'] == true ? AppColors.danger : AppColors.secondaryLabel,
                  ),
                ),
              ),
            ),
            const Divider(height: 30),
            const Text(
              'Fee Schedule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...fees.map<Widget>(
              (fee) => ListTile(
                title: Text(fee['feeType']),
                trailing: Text('LKR ${fee['amount']}'),
              ),
            ),
            const SizedBox(height: 30),
            if (isSignedIn) ...[
              _buildStageActionButton(context, ref, serviceDetails, totalStages, workflowDepts, activeApp),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Run Eligibility Self-Check'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EligibilitySelfCheckScreen(
                      serviceId: serviceId,
                      serviceName:
                          serviceDetails['name'] ?? 'Government Service',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageActionButton(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> serviceDetails,
    int totalStages,
    List<String> workflowDepts,
    ApplicationItemModel? activeApp,
  ) {
    if (activeApp == null) {
      // Citizen has not submitted yet
      final firstDept = workflowDepts.isNotEmpty ? workflowDepts[0] : "Initial Gate";
      return ElevatedButton.icon(
        icon: const Icon(Icons.edit_document),
        label: Text(totalStages > 1 
          ? 'Apply for Stage 1 ($firstDept)'
          : 'Apply Now'
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApplicationFormScreen(
                serviceId: serviceId,
                serviceName: serviceDetails['name'] ?? 'Government Service',
                stageNumber: 1,
              ),
            ),
          ).then((_) => ref.invalidate(myApplicationsProvider));
        },
      );
    }

    // Active Application Exists
    final stage = activeApp.currentStage;
    final dept = activeApp.currentDepartment ?? 
        (stage - 1 < workflowDepts.length ? workflowDepts[stage - 1] : "Assigned Dept");
    final status = activeApp.stageStatus;

    if (status == 'StageApproved' || status.endsWith('Unlocked')) {
      // Officer approved previous stage! Next stage is ready to fill!
      return ElevatedButton.icon(
        icon: const Icon(Icons.arrow_forward),
        label: Text('Continue to Stage $stage ($dept)'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApplicationFormScreen(
                serviceId: serviceId,
                serviceName: serviceDetails['name'] ?? 'Government Service',
                stageNumber: stage,
                applicationId: activeApp.applicationId,
              ),
            ),
          ).then((_) => ref.invalidate(myApplicationsProvider));
        },
      );
    }

    if (status == 'AwaitingFeePayment') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.payment),
        label: Text('Pay Stage $stage Statutory Fee'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                applicationId: activeApp.applicationId.toString(),
                amount: activeApp.amount > 0 ? activeApp.amount : 1000.0,
                userEmail: activeApp.userEmail,
                popOnPaid: true,
              ),
            ),
          ).then((_) => ref.invalidate(myApplicationsProvider));
        },
      );
    }

    if (status == 'Completed' || activeApp.status == 'Approved') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.check_circle),
        label: const Text('All Stages Verified & Completed'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationDetailScreen(application: activeApp),
            ),
          );
        },
      );
    }

    // Default: PendingReview / Submitted -> Waiting for officer verification
    return Column(
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.hourglass_top, color: Color(0xFFB25E00)),
          label: Text(
            'Stage $stage Under Review ($dept)',
            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB25E00)),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFFFFF9E6),
            side: const BorderSide(color: Color(0xFFFFD466), width: 1.5),
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerificationDetailScreen(application: activeApp),
              ),
            ).then((_) => ref.invalidate(myApplicationsProvider));
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Your Stage $stage submission is waiting for official verification by $dept. Once verified, Stage ${(stage + 1).clamp(1, activeApp.maxStages)} will unlock.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryLabel),
        ),
      ],
    );
  }
}
