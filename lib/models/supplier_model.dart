class SupplierModel {
  final String id;
  final String vendorId;
  final String namaVendor;
  final String? nomorHp;
  final String? email;
  final String? namaKtp;
  final String? nomorKtp;
  final String? idProvinsiKtp;
  final String? idKabupatenKtp;
  final String? idKecamatanKtp;
  final String? idDesaKtp;
  final String? rtKtp;
  final String? rwKtp;
  final String? jalanAlamatKtp;
  final String? alamatLengkapKtp;
  final String? namaNpwp;
  final String? nomorNpwp;
  final String? idProvinsiNpwp;
  final String? idKabupatenNpwp;
  final String? idKecamatanNpwp;
  final String? idDesaNpwp;
  final String? bankId;
  final String? namaBank;
  final String? nomorRekening;
  final String? namaPenerimaBank;
  final String? cabangBank;
  final String? supplierGroupId;
  final String? supplierGroupName;
  final String? buyerId;
  final String? buyerName;
  final String? ktpProvinceName;
  final String? ktpCityName;
  final int statusUser;
  final String? createdAt;

  SupplierModel({
    required this.id,
    required this.vendorId,
    required this.namaVendor,
    this.nomorHp,
    this.email,
    this.namaKtp,
    this.nomorKtp,
    this.idProvinsiKtp,
    this.idKabupatenKtp,
    this.idKecamatanKtp,
    this.idDesaKtp,
    this.rtKtp,
    this.rwKtp,
    this.jalanAlamatKtp,
    this.alamatLengkapKtp,
    this.namaNpwp,
    this.nomorNpwp,
    this.idProvinsiNpwp,
    this.idKabupatenNpwp,
    this.idKecamatanNpwp,
    this.idDesaNpwp,
    this.bankId,
    this.namaBank,
    this.nomorRekening,
    this.namaPenerimaBank,
    this.cabangBank,
    this.supplierGroupId,
    this.supplierGroupName,
    this.buyerId,
    this.buyerName,
    this.ktpProvinceName,
    this.ktpCityName,
    this.statusUser = 1,
    this.createdAt,
  });

  bool get isActive => statusUser == 1;

  String get initials {
    final parts = namaVendor.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'S';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    // Extract relations
    String? groupName;
    if (json['supplier_group'] != null && json['supplier_group'] is Map) {
      final g = json['supplier_group'] as Map<String, dynamic>;
      groupName = g['group_name'] ?? g['group_code'];
    }

    String? bName;
    if (json['master_buyer'] != null && json['master_buyer'] is Map) {
      final b = json['master_buyer'] as Map<String, dynamic>;
      bName = b['full_name'];
    }

    String? bnkName = json['nama_bank'];
    String? accNumber = json['nomor_rekening'];
    String? accHolder = json['nama_penerima_bank'];
    if (json['bank_accounts'] != null &&
        json['bank_accounts'] is List &&
        (json['bank_accounts'] as List).isNotEmpty) {
      final firstAcc = json['bank_accounts'][0] as Map<String, dynamic>;
      accNumber = firstAcc['account_number'] ?? accNumber;
      accHolder = firstAcc['account_holder_name'] ?? accHolder;
      if (firstAcc['master_bank'] != null && firstAcc['master_bank'] is Map) {
        bnkName = firstAcc['master_bank']['bank_name'] ?? bnkName;
      }
    } else if (json['master_bank'] != null && json['master_bank'] is Map) {
      bnkName = json['master_bank']['bank_name'] ?? bnkName;
    }

    String? provName;
    if (json['ktp_province'] != null && json['ktp_province'] is Map) {
      provName = json['ktp_province']['name'];
    }

    String? ctyName;
    if (json['ktp_city'] != null && json['ktp_city'] is Map) {
      ctyName = json['ktp_city']['name'];
    }

    return SupplierModel(
      id: json['id']?.toString() ?? '',
      vendorId: json['vendor_id']?.toString() ?? '',
      namaVendor: json['nama_vendor']?.toString() ?? json['nama_ktp']?.toString() ?? 'Supplier',
      nomorHp: json['nomor_hp']?.toString(),
      email: json['email']?.toString(),
      namaKtp: json['nama_ktp']?.toString(),
      nomorKtp: json['nomor_ktp']?.toString(),
      idProvinsiKtp: json['id_provinsiktp']?.toString(),
      idKabupatenKtp: json['id_kabupatenktp']?.toString(),
      idKecamatanKtp: json['id_kecamatanktp']?.toString(),
      idDesaKtp: json['id_desaktp']?.toString(),
      rtKtp: json['rt_ktp']?.toString(),
      rwKtp: json['rw_ktp']?.toString(),
      jalanAlamatKtp: json['jalan_alamat_ktp']?.toString(),
      alamatLengkapKtp: json['alamat_lengkap_ktp']?.toString(),
      namaNpwp: json['nama_npwp']?.toString(),
      nomorNpwp: json['nomor_npwp']?.toString(),
      idProvinsiNpwp: json['id_provinsinpwp']?.toString(),
      idKabupatenNpwp: json['id_kabupatennpwp']?.toString(),
      idKecamatanNpwp: json['id_kecamatannpwp']?.toString(),
      idDesaNpwp: json['id_desanpwp']?.toString(),
      bankId: json['bank_id']?.toString(),
      namaBank: bnkName,
      nomorRekening: accNumber,
      namaPenerimaBank: accHolder,
      cabangBank: json['cabang_bank']?.toString(),
      supplierGroupId: json['supplier_group_id']?.toString(),
      supplierGroupName: groupName,
      buyerId: json['buyer_id']?.toString(),
      buyerName: bName,
      ktpProvinceName: provName,
      ktpCityName: ctyName,
      statusUser: json['status_user'] is int
          ? json['status_user'] as int
          : (int.tryParse(json['status_user']?.toString() ?? '1') ?? 1),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor_id': vendorId,
      'nama_vendor': namaVendor,
      'nomor_hp': nomorHp,
      'email': email,
      'nama_ktp': namaKtp,
      'nomor_ktp': nomorKtp,
      'id_provinsiktp': idProvinsiKtp,
      'id_kabupatenktp': idKabupatenKtp,
      'id_kecamatanktp': idKecamatanKtp,
      'id_desaktp': idDesaKtp,
      'rt_ktp': rtKtp,
      'rw_ktp': rwKtp,
      'jalan_alamat_ktp': jalanAlamatKtp,
      'nama_npwp': namaNpwp,
      'nomor_npwp': nomorNpwp,
      'id_provinsinpwp': idProvinsiNpwp,
      'id_kabupatennpwp': idKabupatenNpwp,
      'id_kecamatannpwp': idKecamatanNpwp,
      'id_desanpwp': idDesaNpwp,
      'bank_id': bankId,
      'nama_bank': namaBank,
      'nomor_rekening': nomorRekening,
      'nama_penerima_bank': namaPenerimaBank,
      'cabang_bank': cabangBank,
      'supplier_group_id': supplierGroupId,
      'buyer_id': buyerId,
      'status_user': statusUser,
    };
  }
}

class SupplierReferenceModel {
  final List<SupplierGroupRef> supplierGroups;
  final List<BankRef> banks;
  final List<BuyerRef> buyers;
  final List<RegionRef> provinces;

  SupplierReferenceModel({
    required this.supplierGroups,
    required this.banks,
    required this.buyers,
    required this.provinces,
  });

  factory SupplierReferenceModel.fromJson(Map<String, dynamic> json) {
    return SupplierReferenceModel(
      supplierGroups: (json['supplier_groups'] as List? ?? [])
          .map((e) => SupplierGroupRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      banks: (json['banks'] as List? ?? [])
          .map((e) => BankRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      buyers: (json['buyers'] as List? ?? [])
          .map((e) => BuyerRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      provinces: (json['provinces'] as List? ?? [])
          .map((e) => RegionRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SupplierGroupRef {
  final dynamic id;
  final String code;
  final String name;

  SupplierGroupRef({required this.id, required this.code, required this.name});

  factory SupplierGroupRef.fromJson(Map<String, dynamic> json) => SupplierGroupRef(
        id: json['id'],
        code: json['group_code'] ?? '',
        name: json['group_name'] ?? '',
      );
}

class SupplierGroupModel {
  final String id;
  final String code;
  final String name;
  final int status;
  final String? createdAt;

  const SupplierGroupModel({
    required this.id,
    required this.code,
    required this.name,
    this.status = 1,
    this.createdAt,
  });

  bool get isActive => status == 1;

  factory SupplierGroupModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] ?? json['status_user'] ?? 1;
    return SupplierGroupModel(
      id: json['id']?.toString() ?? '',
      code: (json['group_code'] ?? json['code'] ?? '').toString(),
      name: (json['group_name'] ?? json['name'] ?? '').toString(),
      status: rawStatus is int
          ? rawStatus
          : (int.tryParse(rawStatus.toString()) ?? 1),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'group_code': code,
        'group_name': name,
        'status': status,
      };
}

class BankRef {
  final dynamic id;
  final String code;
  final String name;

  BankRef({required this.id, required this.code, required this.name});

  factory BankRef.fromJson(Map<String, dynamic> json) => BankRef(
        id: json['id'],
        code: json['bank_code'] ?? '',
        name: json['bank_name'] ?? '',
      );
}

class BuyerRef {
  final String id;
  final String name;

  BuyerRef({required this.id, required this.name});

  factory BuyerRef.fromJson(Map<String, dynamic> json) => BuyerRef(
        id: json['buyer_id'] ?? '',
        name: json['full_name'] ?? '',
      );
}

class RegionRef {
  final dynamic id;
  final String code;
  final String name;

  RegionRef({required this.id, required this.code, required this.name});

  factory RegionRef.fromJson(Map<String, dynamic> json) => RegionRef(
        id: json['id'],
        code: json['code'] ?? '',
        name: json['name'] ?? '',
      );
}

