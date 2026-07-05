import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String senderRole;
  final String recipientAdminId;
  final String recipientAdminName;
  final String recipientAdminEmail;
  final List<String> recipientAdminIds;
  final List<String> recipientAdminNames;
  final List<String> recipientAdminEmails;
  final String message;
  final bool isRead;
  final bool isProcessed;
  final DateTime? readAt;
  final DateTime? processedAt;
  final String? processedById;
  final String? processedByName;
  final DateTime createdAt;

  const FeedbackMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.senderRole,
    required this.recipientAdminId,
    required this.recipientAdminName,
    required this.recipientAdminEmail,
    required this.recipientAdminIds,
    required this.recipientAdminNames,
    required this.recipientAdminEmails,
    required this.message,
    required this.isRead,
    required this.isProcessed,
    required this.readAt,
    required this.processedAt,
    required this.processedById,
    required this.processedByName,
    required this.createdAt,
  });

  factory FeedbackMessageModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return FeedbackMessageModel(
      id: id,
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? 'Ẩn danh',
      senderEmail: json['sender_email']?.toString() ?? '',
      senderRole: json['sender_role']?.toString() ?? 'user',
      recipientAdminId: json['recipient_admin_id']?.toString() ?? '',
      recipientAdminName: json['recipient_admin_name']?.toString() ?? 'System Admin',
      recipientAdminEmail: json['recipient_admin_email']?.toString() ?? 'admin@smartbite.com',
      recipientAdminIds: (json['recipient_admin_ids'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      recipientAdminNames: (json['recipient_admin_names'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      recipientAdminEmails: (json['recipient_admin_emails'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] as bool? ?? false,
      isProcessed: json['is_processed'] as bool? ?? false,
      readAt: parseDate(json['read_at']),
      processedAt: parseDate(json['processed_at']),
      processedById: json['processed_by_id']?.toString(),
      processedByName: json['processed_by_name']?.toString(),
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_email': senderEmail,
      'sender_role': senderRole,
      'recipient_admin_id': recipientAdminId,
      'recipient_admin_name': recipientAdminName,
      'recipient_admin_email': recipientAdminEmail,
      'recipient_admin_ids': recipientAdminIds,
      'recipient_admin_names': recipientAdminNames,
      'recipient_admin_emails': recipientAdminEmails,
      'message': message,
      'is_read': isRead,
      'is_processed': isProcessed,
      'read_at': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'processed_at': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'processed_by_id': processedById,
      'processed_by_name': processedByName,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  FeedbackMessageModel copyWith({
    bool? isRead,
    bool? isProcessed,
    DateTime? readAt,
    DateTime? processedAt,
    String? processedById,
    String? processedByName,
  }) {
    return FeedbackMessageModel(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderEmail: senderEmail,
      senderRole: senderRole,
      recipientAdminId: recipientAdminId,
      recipientAdminName: recipientAdminName,
      recipientAdminEmail: recipientAdminEmail,
      recipientAdminIds: recipientAdminIds,
      recipientAdminNames: recipientAdminNames,
      recipientAdminEmails: recipientAdminEmails,
      message: message,
      isRead: isRead ?? this.isRead,
      isProcessed: isProcessed ?? this.isProcessed,
      readAt: readAt ?? this.readAt,
      processedAt: processedAt ?? this.processedAt,
      processedById: processedById ?? this.processedById,
      processedByName: processedByName ?? this.processedByName,
      createdAt: createdAt,
    );
  }
}