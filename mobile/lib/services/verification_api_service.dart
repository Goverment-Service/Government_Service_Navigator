import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/verification_models.dart';

class VerificationApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5119/api/verification';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5119/api/verification';
      }
    } catch (_) {}
    return 'http://localhost:5119/api/verification';
  }

  // Pre-configured golden data representing real citizen applications
  // across all 4 verification states: Pending, Approved, Revised, and Rejected.
  static final List<ApplicationItemModel> _demoApplications = [
    ApplicationItemModel(
      applicationId: 8841,
      referenceNumber: 'APP-2026-8841',
      serviceName: 'Small Business Registration',
      category: 'Finance Department',
      submittedDate: DateTime.now().subtract(const Duration(days: 2)),
      status: 'Pending',
      applicantName: 'Kamal Perera',
      verificationTask: VerificationTaskModel(
        id: 101,
        applicationId: 8841,
        status: 'Pending',
        createdDate: DateTime.now().subtract(const Duration(days: 2)),
        reviews: [],
        complianceChecks: [
          ComplianceCheckModel(
            id: 1,
            checkType: 'NIC & Identity Authenticity',
            isPassed: true,
            details: 'Government identity database match confirmed (NIC: 199423401928).',
          ),
          ComplianceCheckModel(
            id: 2,
            checkType: 'Business Location Clearance',
            isPassed: true,
            details: 'Municipal zoning permit validated.',
          ),
          ComplianceCheckModel(
            id: 3,
            checkType: 'Tax Identification Registration',
            isPassed: true,
            details: 'TIN verification confirmed active status.',
          ),
          ComplianceCheckModel(
            id: 4,
            checkType: 'Officer Document Inspection',
            isPassed: false,
            details: 'In queue for Verifying Officer assignment.',
          ),
        ],
      ),
      auditLogs: [
        AuditLogModel(
          id: 1,
          applicationId: 8841,
          action: 'Application Submitted',
          performedBy: 'Citizen (Kamal Perera)',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          oldValues: '',
          newValues: 'Status: Submitted',
        ),
        AuditLogModel(
          id: 2,
          applicationId: 8841,
          action: 'Pre-Compliance Checks Executed',
          performedBy: 'Automated AI Compliance Engine',
          timestamp: DateTime.now().subtract(const Duration(days: 2, minutes: -5)),
          oldValues: 'Status: Submitted',
          newValues: 'Score: 100%, Identity: Match, Tax: Valid',
        ),
        AuditLogModel(
          id: 3,
          applicationId: 8841,
          action: 'Enqueued for Officer Verification',
          performedBy: 'Verification Workflow Dispatcher',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          oldValues: 'Queue: Incoming',
          newValues: 'Queue: Pending Review, TaskId: 101',
        ),
      ],
    ),
    ApplicationItemModel(
      applicationId: 7102,
      referenceNumber: 'APP-2026-7102',
      serviceName: 'Driving Licence Replacement',
      category: 'Transport Department',
      submittedDate: DateTime.now().subtract(const Duration(days: 14)),
      status: 'Approved',
      applicantName: 'Kamal Perera',
      verificationTask: VerificationTaskModel(
        id: 88,
        applicationId: 7102,
        status: 'Approved',
        createdDate: DateTime.now().subtract(const Duration(days: 14)),
        reviews: [
          OfficerReviewModel(
            id: 201,
            officerId: 'OFFICER-BANDARA',
            reviewDate: DateTime.now().subtract(const Duration(days: 10)),
            comments: 'All identity biometric data and police clearance records verified successfully. Certificate issued.',
          ),
        ],
        complianceChecks: [
          ComplianceCheckModel(
            id: 10,
            checkType: 'Biometric & Medical Fitness Report',
            isPassed: true,
            details: 'National Transport Medical Institute certificate verified valid.',
          ),
          ComplianceCheckModel(
            id: 11,
            checkType: 'Police Clearance Record',
            isPassed: true,
            details: 'Zero pending endorsements or driving violations.',
          ),
          ComplianceCheckModel(
            id: 12,
            checkType: 'Officer Verification Sign-Off',
            isPassed: true,
            details: 'Approved by Officer Bandara (Transport Dept).',
          ),
        ],
      ),
      auditLogs: [
        AuditLogModel(
          id: 10,
          applicationId: 7102,
          action: 'Application Submitted',
          performedBy: 'Citizen',
          timestamp: DateTime.now().subtract(const Duration(days: 14)),
          oldValues: '',
          newValues: 'Status: Submitted',
        ),
        AuditLogModel(
          id: 11,
          applicationId: 7102,
          action: 'Verification Review Assigned',
          performedBy: 'Transport Dispatcher',
          timestamp: DateTime.now().subtract(const Duration(days: 12)),
          oldValues: 'Status: Pending',
          newValues: 'Assigned: OFFICER-BANDARA',
        ),
        AuditLogModel(
          id: 12,
          applicationId: 7102,
          action: 'Decision: Approved',
          performedBy: 'OFFICER-BANDARA',
          timestamp: DateTime.now().subtract(const Duration(days: 10)),
          oldValues: 'Status: Pending',
          newValues: 'Status: Approved, Digital Seal Issued',
        ),
      ],
    ),
    ApplicationItemModel(
      applicationId: 6540,
      referenceNumber: 'APP-2026-6540',
      serviceName: 'Building Plan Approval',
      category: 'Urban Development Authority',
      submittedDate: DateTime.now().subtract(const Duration(days: 5)),
      status: 'Revised',
      applicantName: 'Kamal Perera',
      verificationTask: VerificationTaskModel(
        id: 92,
        applicationId: 6540,
        status: 'Revised',
        createdDate: DateTime.now().subtract(const Duration(days: 5)),
        reviews: [
          OfficerReviewModel(
            id: 202,
            officerId: 'OFFICER-SENEVIRATNE',
            reviewDate: DateTime.now().subtract(const Duration(days: 1)),
            comments: 'Please re-upload an updated boundary survey plan stamped by a licensed surveyor. The current plan copy is cut off at the eastern edge.',
            rejectionReasonCode: 'DOC-003',
            rejectionReasonDescription: 'Illegible or incomplete surveyor diagram',
          ),
        ],
        complianceChecks: [
          ComplianceCheckModel(
            id: 20,
            checkType: 'Deed of Land Ownership',
            isPassed: true,
            details: 'Registered title deed verified with Land Registry.',
          ),
          ComplianceCheckModel(
            id: 21,
            checkType: 'Boundary Survey Compliance',
            isPassed: false,
            details: 'Action required: Certified survey plan missing full dimensional markers.',
          ),
          ComplianceCheckModel(
            id: 22,
            checkType: 'Environmental Health Clearance',
            isPassed: true,
            details: 'Drainage and sewage layout approved.',
          ),
        ],
      ),
      auditLogs: [
        AuditLogModel(
          id: 20,
          applicationId: 6540,
          action: 'Application Submitted',
          performedBy: 'Citizen',
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
          oldValues: '',
          newValues: 'Status: Submitted',
        ),
        AuditLogModel(
          id: 21,
          applicationId: 6540,
          action: 'Decision: Revised',
          performedBy: 'OFFICER-SENEVIRATNE',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          oldValues: 'Status: Pending',
          newValues: 'Status: Revised, Reason: DOC-003',
        ),
      ],
    ),
    ApplicationItemModel(
      applicationId: 5219,
      referenceNumber: 'APP-2026-5219',
      serviceName: 'Senior Citizen Health Grant',
      category: 'Social Services Department',
      submittedDate: DateTime.now().subtract(const Duration(days: 20)),
      status: 'Rejected',
      applicantName: 'Kamal Perera',
      verificationTask: VerificationTaskModel(
        id: 74,
        applicationId: 5219,
        status: 'Rejected',
        createdDate: DateTime.now().subtract(const Duration(days: 20)),
        reviews: [
          OfficerReviewModel(
            id: 203,
            officerId: 'OFFICER-JAYASINGHE',
            reviewDate: DateTime.now().subtract(const Duration(days: 18)),
            comments: 'Applicant does not meet the minimum age criterion of 60 years on the application cut-off date.',
            rejectionReasonCode: 'ELIG-001',
            rejectionReasonDescription: 'Applicant does not satisfy age eligibility threshold',
          ),
        ],
        complianceChecks: [
          ComplianceCheckModel(
            id: 30,
            checkType: 'Citizenship & Identity',
            isPassed: true,
            details: 'Valid Sri Lankan National Identity Card.',
          ),
          ComplianceCheckModel(
            id: 31,
            checkType: 'Statutory Age Verification',
            isPassed: false,
            details: 'Calculated age does not meet requirement (Rule: Age >= 60).',
          ),
        ],
      ),
      auditLogs: [
        AuditLogModel(
          id: 30,
          applicationId: 5219,
          action: 'Application Submitted',
          performedBy: 'Citizen',
          timestamp: DateTime.now().subtract(const Duration(days: 20)),
          oldValues: '',
          newValues: 'Status: Submitted',
        ),
        AuditLogModel(
          id: 31,
          applicationId: 5219,
          action: 'Decision: Rejected',
          performedBy: 'OFFICER-JAYASINGHE',
          timestamp: DateTime.now().subtract(const Duration(days: 18)),
          oldValues: 'Status: Pending',
          newValues: 'Status: Rejected, Reason: ELIG-001',
        ),
      ],
    ),
  ];

  /// Fetches citizen applications and enriches them with real-time verification tasks from backend
  static Future<List<ApplicationItemModel>> fetchApplications({String? token}) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Try fetching pending and verified tasks from the backend
      final pendingResponse = await http
          .get(Uri.parse('$baseUrl/tasks/pending'), headers: headers)
          .timeout(const Duration(seconds: 4));

      final verifiedResponse = await http
          .get(Uri.parse('$baseUrl/tasks/verified'), headers: headers)
          .timeout(const Duration(seconds: 4));

      List<dynamic> backendTasks = [];

      if (pendingResponse.statusCode == 200) {
        final data = jsonDecode(pendingResponse.body);
        if (data is List) backendTasks.addAll(data);
      }
      if (verifiedResponse.statusCode == 200) {
        final data = jsonDecode(verifiedResponse.body);
        if (data is List) backendTasks.addAll(data);
      }

      // Merge backend verification records with application list
      if (backendTasks.isNotEmpty) {
        final Map<int, dynamic> taskMap = {};
        for (var t in backendTasks) {
          if (t['applicationId'] != null) {
            taskMap[t['applicationId'] as int] = t;
          }
        }

        return _demoApplications.map((app) {
          if (taskMap.containsKey(app.applicationId)) {
            final raw = taskMap[app.applicationId];
            final updatedTask = VerificationTaskModel.fromJson(raw);
            return app.copyWith(
              status: updatedTask.status,
              verificationTask: updatedTask,
            );
          }
          return app;
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('VerificationApiService: Using cached/fallback data: $e');
      }
    }

    // Return the demo applications if backend is unreachable or empty
    return List<ApplicationItemModel>.from(_demoApplications);
  }

  /// Fetches audit logs for a specific application from the backend
  static Future<List<AuditLogModel>> fetchAuditLogs(int applicationId, {String? token}) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(Uri.parse('$baseUrl/audit-logs?applicationId=$applicationId'), headers: headers)
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AuditLogModel.fromJson(json)).toList();
      }
    } catch (_) {}

    // Fallback to local demo logs for this application
    final match = _demoApplications.firstWhere(
      (a) => a.applicationId == applicationId,
      orElse: () => _demoApplications.first,
    );
    return match.auditLogs;
  }

  /// Simulates citizen resubmission for an application marked "Revised"
  static Future<bool> submitRevision({
    required int applicationId,
    required String notes,
    required String documentAttachmentName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final index = _demoApplications.indexWhere((a) => a.applicationId == applicationId);
    if (index != -1) {
      final existing = _demoApplications[index];
      final newLog = AuditLogModel(
        id: DateTime.now().millisecondsSinceEpoch,
        applicationId: applicationId,
        action: 'Revision Submitted by Citizen',
        performedBy: 'Citizen (${existing.applicantName ?? "Applicant"})',
        timestamp: DateTime.now(),
        oldValues: 'Status: Revised',
        newValues: 'Status: Pending (Re-submitted), Doc: $documentAttachmentName, Note: $notes',
      );

      final updatedTask = VerificationTaskModel(
        id: existing.verificationTask?.id ?? 999,
        applicationId: applicationId,
        status: 'Pending',
        createdDate: existing.verificationTask?.createdDate ?? DateTime.now(),
        reviews: existing.verificationTask?.reviews ?? [],
        complianceChecks: (existing.verificationTask?.complianceChecks ?? []).map((c) {
          if (!c.isPassed) {
            return ComplianceCheckModel(
              id: c.id,
              checkType: c.checkType,
              isPassed: true,
              details: 'Updated document attached ($documentAttachmentName). Pending final officer sign-off.',
            );
          }
          return c;
        }).toList(),
      );

      _demoApplications[index] = existing.copyWith(
        status: 'Pending',
        verificationTask: updatedTask,
        auditLogs: [newLog, ...existing.auditLogs],
      );
    }
    return true;
  }
}
