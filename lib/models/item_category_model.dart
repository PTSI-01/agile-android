class ItemCategoryModel {
  final String id;
  final String code;
  final String name;
  final int status;
  final String? createdAt;

  const ItemCategoryModel({
    required this.id,
    required this.code,
    required this.name,
    this.status = 1,
    this.createdAt,
  });

  bool get isActive => status == 1;

  factory ItemCategoryModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] ?? json['status_user'] ?? 1;
    final normalizedStatus = rawStatus.toString().trim().toLowerCase();
    return ItemCategoryModel(
      id: json['id']?.toString() ?? '',
      code:
          (json['category_code'] ??
                  json['kategori_code'] ??
                  json['kode_kategori'] ??
                  json['code'] ??
                  '')
              .toString(),
      name:
          (json['category_name'] ??
                  json['kategori_name'] ??
                  json['nama_kategori'] ??
                  json['name'] ??
                  '')
              .toString(),
      status: rawStatus is int
          ? rawStatus
          : ['aktif', 'active', 'true', '1'].contains(normalizedStatus)
          ? 1
          : 0,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'category_code': code,
    'category_name': name,
    'status': status,
  };
}
