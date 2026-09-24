class BuyerGroupModel {
  final String id;
  final String code;
  final String name;
  final int status;
  final String? createdAt;

  const BuyerGroupModel({
    required this.id,
    required this.code,
    required this.name,
    this.status = 1,
    this.createdAt,
  });

  bool get isActive => status == 1;

  factory BuyerGroupModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] ?? json['status_user'] ?? 1;
    final normalizedStatus = rawStatus is String
        ? (rawStatus.toLowerCase() == 'active' ? 1 : 0)
        : (rawStatus is bool ? (rawStatus ? 1 : 0) : (int.tryParse(rawStatus.toString()) ?? 1));
    return BuyerGroupModel(
      id: json['id']?.toString() ?? '',
      code: (json['group_code'] ?? json['code'] ?? '').toString(),
      name: (json['group_name'] ?? json['name'] ?? '').toString(),
      status: normalizedStatus,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'group_code': code,
        'group_name': name,
        'status': status,
      };
}
