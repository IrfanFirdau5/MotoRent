// FILE: lib/services/firebase_report_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';

class FirebaseReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _reportsCollection = 'reports';

  // Fetch reports with optional filtering
  Future<List<Report>> fetchReports({String? status}) async {
    try {
      Query query = _firestore.collection(_reportsCollection);
      
      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }
      
      final snapshot = await query.orderBy('created_at', descending: true).get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['report_id'] = doc.id;
        
        // Handle Timestamp conversions
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        if (data['resolved_at'] is Timestamp) {
          data['resolved_at'] = (data['resolved_at'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        
        return Report.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load reports: $e');
    }
  }

  // Get report by ID
  Future<Report?> getReportById(String reportId) async {
    try {
      final doc = await _firestore.collection(_reportsCollection).doc(reportId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['report_id'] = doc.id;
      
      if (data['created_at'] is Timestamp) {
        data['created_at'] = (data['created_at'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      if (data['resolved_at'] is Timestamp) {
        data['resolved_at'] = (data['resolved_at'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      
      return Report.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // Update report status
  Future<bool> updateReportStatus(
    String reportId,
    String newStatus, {
    String? adminNotes,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'status': newStatus, // pending, investigating, resolved, dismissed
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (adminNotes != null && adminNotes.isNotEmpty) {
        updateData['admin_notes'] = adminNotes;
      }

      if (newStatus == 'resolved' || newStatus == 'dismissed') {
        updateData['resolved_at'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection(_reportsCollection).doc(reportId).update(updateData);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete report
  Future<bool> deleteReport(String reportId) async {
    try {
      await _firestore.collection(_reportsCollection).doc(reportId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update admin notes
  Future<bool> updateAdminNotes(String reportId, String notes) async {
    try {
      await _firestore.collection(_reportsCollection).doc(reportId).update({
        'admin_notes': notes,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Stream reports for real-time updates
  Stream<List<Report>> streamReports({String? status}) {
    Query query = _firestore.collection(_reportsCollection);
    
    if (status != null && status != 'all') {
      query = query.where('status', isEqualTo: status);
    }
    
    return query.orderBy('created_at', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['report_id'] = doc.id;
        
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        if (data['resolved_at'] is Timestamp) {
          data['resolved_at'] = (data['resolved_at'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        
        return Report.fromJson(data);
      }).toList();
    });
  }

  // Get report statistics
  Future<Map<String, dynamic>> getReportStats() async {
    try {
      final allReports = await fetchReports();
      
      int total = allReports.length;
      int pending = allReports.where((r) => r.status == 'pending').length;
      int investigating = allReports.where((r) => r.status == 'investigating').length;
      int resolved = allReports.where((r) => r.status == 'resolved').length;
      int dismissed = allReports.where((r) => r.status == 'dismissed').length;

      return {
        'total': total,
        'pending': pending,
        'investigating': investigating,
        'resolved': resolved,
        'dismissed': dismissed,
        'resolution_rate': total > 0 ? (resolved / total * 100) : 0.0,
      };
    } catch (e) {
      return {
        'total': 0,
        'pending': 0,
        'investigating': 0,
        'resolved': 0,
        'dismissed': 0,
        'resolution_rate': 0.0,
      };
    }
  }
}