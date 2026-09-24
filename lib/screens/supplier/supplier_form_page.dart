import 'package:flutter/material.dart';

import '../../models/supplier_model.dart';
import '../../services/supplier_service.dart';

class SupplierFormPage extends StatefulWidget {
  final SupplierModel? supplier;

  const SupplierFormPage({super.key, this.supplier});

  @override
  State<SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<SupplierFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _vendorIdController;
  late final TextEditingController _namaVendorController;
  late final TextEditingController _nomorHpController;
  late final TextEditingController _emailController;
  late final TextEditingController _nomorKtpController;
  late final TextEditingController _namaKtpController;
  late final TextEditingController _jalanAlamatKtpController;
  late final TextEditingController _rtKtpController;
  late final TextEditingController _rwKtpController;
  late final TextEditingController _nomorNpwpController;
  late final TextEditingController _namaNpwpController;
  late final TextEditingController _nomorRekeningController;
  late final TextEditingController _namaPenerimaBankController;
  late final TextEditingController _cabangBankController;

  // Selections
  String? _selectedGroupId;
  String? _selectedBuyerId;
  String? _selectedBankId;
  String? _selectedProvinsiCode;
  String? _selectedKabupatenCode;
  String? _selectedKecamatanCode;
  String? _selectedDesaCode;

  // References
  SupplierReferenceModel? _references;
  List<RegionRef> _kabupatens = [];
  List<RegionRef> _kecamatans = [];
  List<RegionRef> _desas = [];

  bool _isLoadingRef = true;
  bool _isSubmitting = false;

  bool get isEdit => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    _vendorIdController = TextEditingController(text: s?.vendorId ?? '');
    _namaVendorController = TextEditingController(text: s?.namaVendor ?? '');
    _nomorHpController = TextEditingController(text: s?.nomorHp ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _nomorKtpController = TextEditingController(text: s?.nomorKtp ?? '');
    _namaKtpController = TextEditingController(text: s?.namaKtp ?? '');
    _jalanAlamatKtpController =
        TextEditingController(text: s?.jalanAlamatKtp ?? s?.alamatLengkapKtp ?? '');
    _rtKtpController = TextEditingController(text: s?.rtKtp ?? '');
    _rwKtpController = TextEditingController(text: s?.rwKtp ?? '');
    _nomorNpwpController = TextEditingController(text: s?.nomorNpwp ?? '');
    _namaNpwpController = TextEditingController(text: s?.namaNpwp ?? '');
    _nomorRekeningController =
        TextEditingController(text: s?.nomorRekening ?? '');
    _namaPenerimaBankController =
        TextEditingController(text: s?.namaPenerimaBank ?? '');
    _cabangBankController = TextEditingController(text: s?.cabangBank ?? '');

    _selectedGroupId = s?.supplierGroupId;
    _selectedBuyerId = s?.buyerId;
    _selectedBankId = s?.bankId;
    _selectedProvinsiCode = s?.idProvinsiKtp;
    _selectedKabupatenCode = s?.idKabupatenKtp;
    _selectedKecamatanCode = s?.idKecamatanKtp;
    _selectedDesaCode = s?.idDesaKtp;

    _initReferences();
  }

  @override
  void dispose() {
    _vendorIdController.dispose();
    _namaVendorController.dispose();
    _nomorHpController.dispose();
    _emailController.dispose();
    _nomorKtpController.dispose();
    _namaKtpController.dispose();
    _jalanAlamatKtpController.dispose();
    _rtKtpController.dispose();
    _rwKtpController.dispose();
    _nomorNpwpController.dispose();
    _namaNpwpController.dispose();
    _nomorRekeningController.dispose();
    _namaPenerimaBankController.dispose();
    _cabangBankController.dispose();
    super.dispose();
  }

  Future<void> _initReferences() async {
    final ref = await SupplierService.getReferences();
    if (!mounted) return;

    setState(() {
      _references = ref;
      _isLoadingRef = false;
    });

    if (_selectedProvinsiCode != null && _selectedProvinsiCode!.isNotEmpty) {
      _loadKabupatens(_selectedProvinsiCode!);
    }
  }

  Future<void> _loadKabupatens(String provCode) async {
    final list = await SupplierService.getKabupaten(provCode);
    if (mounted) {
      setState(() {
        _kabupatens = list;
      });
      if (_selectedKabupatenCode != null) {
        _loadKecamatans(_selectedKabupatenCode!);
      }
    }
  }

  Future<void> _loadKecamatans(String cityCode) async {
    final list = await SupplierService.getKecamatan(cityCode);
    if (mounted) {
      setState(() {
        _kecamatans = list;
      });
      if (_selectedKecamatanCode != null) {
        _loadDesas(_selectedKecamatanCode!);
      }
    }
  }

  Future<void> _loadDesas(String distCode) async {
    final list = await SupplierService.getDesa(distCode);
    if (mounted) {
      setState(() {
        _desas = list;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);

    final payload = <String, dynamic>{
      'vendor_id': _vendorIdController.text.trim(),
      'nama_vendor': _namaVendorController.text.trim(),
      'nomor_hp': _nomorHpController.text.trim(),
      'email': _emailController.text.trim(),
      'supplier_group_id': _selectedGroupId,
      'buyer_id': _selectedBuyerId,
      'nama_ktp': _namaKtpController.text.trim(),
      'nomor_ktp': _nomorKtpController.text.trim(),
      'id_provinsiktp': _selectedProvinsiCode,
      'id_kabupatenktp': _selectedKabupatenCode,
      'id_kecamatanktp': _selectedKecamatanCode,
      'id_desaktp': _selectedDesaCode,
      'rt_ktp': _rtKtpController.text.trim(),
      'rw_ktp': _rwKtpController.text.trim(),
      'jalan_alamat_ktp': _jalanAlamatKtpController.text.trim(),
      'bank_id': _selectedBankId,
      'nomor_rekening': _nomorRekeningController.text.trim(),
      'nama_penerima_bank': _namaPenerimaBankController.text.trim(),
      'cabang_bank': _cabangBankController.text.trim(),
      'nomor_npwp': _nomorNpwpController.text.trim(),
      'nama_npwp': _namaNpwpController.text.trim(),
    };

    final res = isEdit
        ? await SupplierService.updateSupplier(widget.supplier!.id, payload)
        : await SupplierService.createSupplier(payload);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Berhasil menyimpan supplier.'),
          backgroundColor: const Color(0xFF1F7A2E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal menyimpan supplier.'),
          backgroundColor: const Color(0xFFD14942),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF183C32);
    const green = Color(0xFF1F7A2E);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Supplier' : 'Tambah Supplier Baru',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFF7F9F5),
        elevation: 0,
      ),
      body: _isLoadingRef
          ? const Center(child: CircularProgressIndicator(color: green))
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  children: [
                    // 1. INFORMASI VENDOR
                    _sectionHeader(
                      '1. Informasi Vendor & Kontak',
                      Icons.storefront_rounded,
                    ),
                    const SizedBox(height: 12),
                    _cardWrapper([
                      _textField(
                        controller: _vendorIdController,
                        label: 'Kode Vendor / Supplier *',
                        hint: 'Contoh: VND-0042',
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Kode Vendor wajib diisi.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        controller: _namaVendorController,
                        label: 'Nama Vendor / Usaha *',
                        hint: 'Nama Toko / Petani / Usaha',
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Nama Vendor wajib diisi.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        controller: _nomorHpController,
                        label: 'Nomor Telepon / WhatsApp',
                        hint: '081234567890',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        controller: _emailController,
                        label: 'Alamat Email',
                        hint: 'supplier@email.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _dropdownField<String>(
                        label: 'Grup Supplier',
                        value: _selectedGroupId,
                        items: (_references?.supplierGroups ?? [])
                            .map((g) => DropdownMenuItem(
                                  value: g.id?.toString(),
                                  child: Text(g.name),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedGroupId = val),
                      ),
                      const SizedBox(height: 14),
                      _dropdownField<String>(
                        label: 'Buyer Terkait',
                        value: _selectedBuyerId,
                        items: (_references?.buyers ?? [])
                            .map((b) => DropdownMenuItem(
                                  value: b.id,
                                  child: Text('${b.id} - ${b.name}'),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedBuyerId = val),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // 2. REKENING BANK
                    _sectionHeader(
                      '2. Rekening Bank Pembayaran',
                      Icons.account_balance_rounded,
                    ),
                    const SizedBox(height: 12),
                    _cardWrapper([
                      _dropdownField<String>(
                        label: 'Nama Bank',
                        value: _selectedBankId,
                        items: (_references?.banks ?? [])
                            .map((b) => DropdownMenuItem(
                                  value: b.id?.toString(),
                                  child: Text('${b.code} - ${b.name}'),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedBankId = val),
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        controller: _nomorRekeningController,
                        label: 'Nomor Rekening',
                        hint: '1234567890',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        controller: _namaPenerimaBankController,
                        label: 'Nama Pemilik Rekening',
                        hint: 'Sesuai buku tabungan',
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        controller: _cabangBankController,
                        label: 'Kantor Cabang Bank',
                        hint: 'Contoh: KCP Kediri',
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // 3. DATA KTP & WILAYAH
                    _sectionHeader(
                      '3. Data KTP & Wilayah',
                      Icons.badge_rounded,
                    ),
                    const SizedBox(height: 12),
                    _cardWrapper([
                      _textField(
                        controller: _nomorKtpController,
                        label: 'Nomor NIK / KTP',
                        hint: '16 digit NIK',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        controller: _namaKtpController,
                        label: 'Nama Sesuai KTP',
                        hint: 'Nama lengkap di KTP',
                      ),
                      const SizedBox(height: 14),
                      _dropdownField<String>(
                        label: 'Provinsi',
                        value: _selectedProvinsiCode,
                        items: (_references?.provinces ?? [])
                            .map((p) => DropdownMenuItem(
                                  value: p.code,
                                  child: Text(p.name),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedProvinsiCode = val;
                            _selectedKabupatenCode = null;
                            _selectedKecamatanCode = null;
                            _selectedDesaCode = null;
                            _kabupatens = [];
                            _kecamatans = [];
                            _desas = [];
                          });
                          if (val != null) _loadKabupatens(val);
                        },
                      ),
                      const SizedBox(height: 14),
                      _dropdownField<String>(
                        label: 'Kota / Kabupaten',
                        value: _selectedKabupatenCode,
                        items: _kabupatens
                            .map((k) => DropdownMenuItem(
                                  value: k.code,
                                  child: Text(k.name),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedKabupatenCode = val;
                            _selectedKecamatanCode = null;
                            _selectedDesaCode = null;
                            _kecamatans = [];
                            _desas = [];
                          });
                          if (val != null) _loadKecamatans(val);
                        },
                      ),
                      const SizedBox(height: 14),
                      _dropdownField<String>(
                        label: 'Kecamatan',
                        value: _selectedKecamatanCode,
                        items: _kecamatans
                            .map((k) => DropdownMenuItem(
                                  value: k.code,
                                  child: Text(k.name),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedKecamatanCode = val;
                            _selectedDesaCode = null;
                            _desas = [];
                          });
                          if (val != null) _loadDesas(val);
                        },
                      ),
                      const SizedBox(height: 14),
                      _dropdownField<String>(
                        label: 'Desa / Kelurahan',
                        value: _selectedDesaCode,
                        items: _desas
                            .map((d) => DropdownMenuItem(
                                  value: d.code,
                                  child: Text(d.name),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedDesaCode = val),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              controller: _rtKtpController,
                              label: 'RT',
                              hint: '001',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _textField(
                              controller: _rwKtpController,
                              label: 'RW',
                              hint: '002',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        controller: _jalanAlamatKtpController,
                        label: 'Alamat Jalan / Detail',
                        hint: 'Jl. Raya Padi No. 12',
                        maxLines: 2,
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // 4. DATA NPWP
                    _sectionHeader(
                      '4. Data NPWP Pajak',
                      Icons.receipt_long_rounded,
                    ),
                    const SizedBox(height: 12),
                    _cardWrapper([
                      _textField(
                        controller: _nomorNpwpController,
                        label: 'Nomor NPWP',
                        hint: 'Nomor Pokok Wajib Pajak',
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        controller: _namaNpwpController,
                        label: 'Nama Wajib Pajak NPWP',
                        hint: 'Nama terdaftar di NPWP',
                      ),
                    ]),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE9EDE5))),
        ),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 20),
            label: Text(
              _isSubmitting
                  ? 'Menyimpan...'
                  : (isEdit ? 'Simpan Perubahan' : 'Tambah Supplier'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1F7A2E)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF183C32),
          ),
        ),
      ],
    );
  }

  Widget _cardWrapper(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EDE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF183C32),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF7F9F8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE9EDE5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE9EDE5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1F7A2E)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF183C32),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F9F8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE9EDE5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE9EDE5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1F7A2E)),
            ),
          ),
        ),
      ],
    );
  }
}
