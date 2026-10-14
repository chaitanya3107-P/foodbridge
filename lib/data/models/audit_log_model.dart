class AuditLogModel {
  final String logId;
  final String actorId;
  final String actorName;
  final String actorRole;
  final String action;
  final String targetCollection;
  final String targetId;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const AuditLogModel({
    required this.logId,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.targetCollection,
    required this.targetId,
    this.metadata = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'actorId': actorId,
      'actorName': actorName,
      'actorRole': actorRole,
      'action': action,
      'targetCollection': targetCollection,
      'targetId': targetId,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> map, String id) {
    return AuditLogModel(
      logId: id,
      actorId: map['actorId'] ?? '',
      actorName: map['actorName'] ?? '',
      actorRole: map['actorRole'] ?? '',
      action: map['action'] ?? '',
      targetCollection: map['targetCollection'] ?? '',
      targetId: map['targetId'] ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }
}
