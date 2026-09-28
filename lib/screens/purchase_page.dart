import 'package:flutter/material.dart';
import '../services/purchase_service.dart';

class PurchasePage extends StatefulWidget { const PurchasePage({super.key}); @override State<PurchasePage> createState()=>_PurchasePageState(); }
class _PurchasePageState extends State<PurchasePage> {
  String _fmt(num value,{bool decimal=false}) { final raw=value.toStringAsFixed(decimal?2:0).split('.'); var s=raw[0]; final sign=s.startsWith('-')?'-':''; if(sign.isNotEmpty)s=s.substring(1); final out=<String>[]; while(s.length>3){out.insert(0,s.substring(s.length-3));s=s.substring(0,s.length-3);} out.insert(0,s); return '$sign${out.join('.')}${decimal?',${raw[1]}':''}'; }
  List<Map<String,dynamic>> rows=[], suppliers=[], items=[], sites=[], provinces=[], priceLists=[]; bool loading=true; String search='';
  @override void initState(){super.initState(); _load();}
  Future<void> _load() async { try { rows=await PurchaseService.list(search:search); final r=await PurchaseService.references(); suppliers=(r['suppliers']??[]).cast<Map<String,dynamic>>(); items=(r['items']??[]).cast<Map<String,dynamic>>(); sites=(r['sites']??[]).cast<Map<String,dynamic>>(); provinces=(r['provinces']??[]).cast<Map<String,dynamic>>(); priceLists=(r['price_lists']??[]).cast<Map<String,dynamic>>(); } catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e'))); } if(mounted)setState(()=>loading=false); }
  Future<String?> _choose(String title, List<Map<String,dynamic>> data, String Function(Map<String,dynamic>) label, String current) async {
    final controller=TextEditingController();
    return showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:Text(title),content:SizedBox(width:400,height:420,child:Column(children:[TextField(controller:controller,decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:"Cari dengan kata..."),onChanged:(_)=>setState((){})),Expanded(child:ValueListenableBuilder<TextEditingValue>(valueListenable:controller,builder:(_,v,__){final q=v.text.toLowerCase();final list=data.where((x)=>label(x).toLowerCase().contains(q)).toList();return ListView(children:list.map((x)=>ListTile(title:Text(label(x)),trailing:label(x)==current?const Icon(Icons.check):null,onTap:()=>Navigator.pop(ctx,label(x)))).toList());}))]))));
  }
  Future<String?> _chooseSupplier(String current) async {
    final controller=TextEditingController();
    return showDialog<String>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh){
      final q=controller.text.trim().toLowerCase();
      final list=suppliers.where((x){final text='${x['vendor_id']??''} ${x['nama_vendor']??''}'.toLowerCase();return text.contains(q);}).toList();
      return AlertDialog(title:const Text('Pilih Supplier'),content:SizedBox(width:400,height:420,child:Column(children:[
        TextField(controller:controller,autofocus:true,onChanged:(_)=>refresh((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari kode atau nama supplier',border:OutlineInputBorder())),
        const SizedBox(height:8),Expanded(child:list.isEmpty?const Center(child:Text('Supplier tidak ditemukan')):ListView.builder(itemCount:list.length,itemBuilder:(_,i){final x=list[i];final id='${x['vendor_id']??x['id']??''}';final label='${x['vendor_id']??x['id']??''} - ${x['nama_vendor']??''}';return ListTile(title:Text(label),trailing:id==current?const Icon(Icons.check):null,onTap:()=>Navigator.pop(ctx,id));}))
      ])));
    }));
  }
  Future<void> _form([Map<String,dynamic>? row]) async {
    String selectedSupplier='${row?['supplier_id']??''}';
    String selectedCategory='${row?['kategori_transaksi']??''}';
    String selectedSite='${row?['site_id']??''}';
    String selectedItem='${row?['item_id']??''}';
    int step=1;
    List<Map<String,dynamic>> availableItems=List<Map<String,dynamic>>.from(items);
    final t=TextEditingController(text:'${row?['tonase_supplier']??''}');
    final price=TextEditingController(text:'${row?['harga_supplier']??''}');
    final n=TextEditingController(text:'${row?['nopol_truk']??''}');
    String selectedProvince='${row?['provinsi_id']??''}', selectedCity='${row?['kabupaten_id']??''}', selectedDistrict='${row?['kecamatan_id']??''}', selectedVillage='${row?['desa_id']??''}';
    String selectedShipping='${row?['jenis_pengiriman']??'SEWA'}', selectedPriceList='${row?['item_sewa_id']??''}';
    List<Map<String,dynamic>> cities=[], districts=[], villages=[];
    final scroll=ScrollController();
    final kuli=TextEditingController(text:'${row?['biaya_kuli']??''}'), intern=TextEditingController(text:'${row?['biaya_truk_intern']??''}');
    final sewaPrice=TextEditingController(text:'${row?['harga_sewa_truk']??'0'}');
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh){
      Map<String,dynamic>? supplier;
      for (final x in suppliers) { if ('${x['vendor_id']??x['id']}'==selectedSupplier) { supplier=x; break; } }
      final supplierLabel=supplier==null?'Pilih supplier':'${supplier['vendor_id']??supplier['id']} - ${supplier['nama_vendor']??''}';
      final itemOptions=availableItems.map((x)=>DropdownMenuItem<String>(value:'${x['item_id']??x['id']}',child:Text('${x['item']?['kode_item']??x['kode_item']??''} - ${x['item']?['nama_item']??x['nama_item']??''}',overflow:TextOverflow.ellipsis))).toList();
      final siteOptions=sites.map((x)=>DropdownMenuItem<String>(value:'${x['id']}',child:Text('${x['site_code']??''} - ${x['site_name']??''}'))).toList();
      final siteLabel=sites.where((x)=>'${x['id']}'==selectedSite).map((x)=>'${x['site_code']??''} - ${x['site_name']??''}').firstWhere((_)=>true,orElse:()=>selectedSite);
      final itemLabel=availableItems.where((x)=>'${x['item_id']??x['id']}'==selectedItem).map((x)=>'${x['item']?['nama_item']??x['nama_item']??selectedItem}').firstWhere((_)=>true,orElse:()=>selectedItem);
      final priceLabel=priceLists.where((x)=>'${x['id']}'==selectedPriceList).map((x){final item=x['item']??x['ItemSite']?['item'];return '${item?['nama_item']??x['price_list_name']??selectedPriceList}';}).firstWhere((_)=>true,orElse:()=>selectedPriceList);
      String regionLabel(List<Map<String,dynamic>> list,String code)=>list.where((x)=>'${x['code']}'==code).map((x)=>'${x['name']}').firstWhere((_)=>true,orElse:()=>code);
      final tonaseValue=double.tryParse(t.text.replaceAll(',','.'))??0, hargaValue=double.tryParse(price.text.replaceAll(',','.'))??0, sewaValue=double.tryParse(sewaPrice.text.replaceAll(',','.'))??0, kuliValue=double.tryParse(kuli.text.replaceAll(',','.'))??0, internValue=double.tryParse(intern.text.replaceAll(',','.'))??0;
      final incTransport=tonaseValue>0?(((tonaseValue*hargaValue)+sewaValue+kuliValue)/tonaseValue).roundToDouble():0; final totalGabah=(incTransport*tonaseValue)+internValue;
      final stepHeader=Row(children:[for(final item in const [(1,'Data Supplier'),(2,'Wilayah'),(3,'Logistik & Harga')])Expanded(child:Column(children:[CircleAvatar(radius:15,backgroundColor:step==item.$1?const Color(0xFF1F7A2E):const Color(0xFFE0E6DF),child:Text('${item.$1}',style:TextStyle(color:step==item.$1?Colors.white:Colors.black))),const SizedBox(height:3),FittedBox(fit:BoxFit.scaleDown,child:Text(item.$2,textAlign:TextAlign.center,style:const TextStyle(fontSize:9))) ]))]);
      return AlertDialog(insetPadding:const EdgeInsets.symmetric(horizontal:16,vertical:24),title:Text(row==null?'Tambah PO':'Ubah PO'),content:SizedBox(width:double.infinity,height:520,child:Column(children:[stepHeader,const SizedBox(height:12),Expanded(child:SingleChildScrollView(controller:scroll,child:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<String>(value:selectedCategory.isEmpty?null:selectedCategory,decoration:const InputDecoration(labelText:'Kategori pembelian *',border:OutlineInputBorder()),items:const [DropdownMenuItem(value:'1',child:Text('Harga Dibawah')),DropdownMenuItem(value:'2',child:Text('Titip'))],onChanged:(v)=>refresh((){selectedCategory=v??'';})),
        const SizedBox(height:10),
        DropdownButtonFormField<String>(value:selectedSite.isEmpty?null:selectedSite,decoration:const InputDecoration(labelText:'Lokasi site *',border:OutlineInputBorder()),items:siteOptions,onChanged:(v)async{if(v==null)return;try{final r=await PurchaseService.siteReferences(v);final list=(r['items']??[]).cast<Map<String,dynamic>>();refresh((){selectedSite=v;availableItems=list;selectedItem='';});}catch(e){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text('$e')));}}),
        const SizedBox(height:10),
        InkWell(onTap:()async{final v=await _chooseSupplier(selectedSupplier);if(v!=null)refresh((){selectedSupplier=v;});},child:InputDecorator(decoration:const InputDecoration(labelText:'Supplier *',suffixIcon:Icon(Icons.search),border:OutlineInputBorder()),child:Text(supplierLabel))),
        if(selectedCategory.isNotEmpty) ...[
          const SizedBox(height:10),
          DropdownButtonFormField<String>(value:selectedItem.isEmpty?null:selectedItem,decoration:const InputDecoration(labelText:'Item *',border:OutlineInputBorder()),items:itemOptions,onChanged:(v)=>refresh((){selectedItem=v??'';})),
          const SizedBox(height:10),
          TextField(controller:t,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:selectedCategory=='1'?'Tonase supplier *':'Tonase supplier *',border:const OutlineInputBorder())),
          if(selectedCategory=='1') ...[
            const SizedBox(height:10),
            TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Harga supplier *',border:OutlineInputBorder())),
          ],
          const SizedBox(height:10),
           TextField(controller:n,decoration:const InputDecoration(labelText:'Nopol truk *',border:OutlineInputBorder())),
         ],
         if(step>=2) ...[
           const Divider(height:24),
           const Align(alignment:Alignment.centerLeft,child:Text('Wilayah Pengambilan',style:TextStyle(fontWeight:FontWeight.bold))),
           const SizedBox(height:8),
           DropdownButtonFormField<String>(value:selectedProvince.isEmpty?null:selectedProvince,decoration:const InputDecoration(labelText:'Provinsi *',border:OutlineInputBorder()),items:provinces.map((x)=>DropdownMenuItem(value:'${x['code']}',child:Text('${x['name']}'))).toList(),onChanged:(v)async{if(v==null)return;try{final data=await PurchaseService.wilayah('kabupaten',v);refresh((){selectedProvince=v;selectedCity='';selectedDistrict='';selectedVillage='';cities=data;districts=[];villages=[];});}catch(e){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text('$e')));}}),
           const SizedBox(height:8),
           DropdownButtonFormField<String>(value:selectedCity.isEmpty?null:selectedCity,decoration:const InputDecoration(labelText:'Kabupaten/Kota *',border:OutlineInputBorder()),items:cities.map((x)=>DropdownMenuItem(value:'${x['code']}',child:Text('${x['name']}'))).toList(),onChanged:(v)async{if(v==null)return;try{final data=await PurchaseService.wilayah('kecamatan',v);refresh((){selectedCity=v;selectedDistrict='';selectedVillage='';districts=data;villages=[];});}catch(e){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text('$e')));}}),
            const SizedBox(height:8),
           DropdownButtonFormField<String>(value:selectedDistrict.isEmpty?null:selectedDistrict,decoration:const InputDecoration(labelText:'Kecamatan *',border:OutlineInputBorder()),items:districts.map((x)=>DropdownMenuItem(value:'${x['code']}',child:Text('${x['name']}'))).toList(),onChanged:(v)async{if(v==null)return;try{final data=await PurchaseService.wilayah('desa',v);refresh((){selectedDistrict=v;selectedVillage='';villages=data;});if(data.isEmpty&&ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content:Text('Desa untuk kecamatan ini tidak ditemukan')));}catch(e){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text('$e')));}}),
            const SizedBox(height:8),
           DropdownButtonFormField<String>(value:selectedVillage.isEmpty?null:selectedVillage,decoration:const InputDecoration(labelText:'Desa/Kelurahan *',border:OutlineInputBorder()),items:villages.map((x)=>DropdownMenuItem(value:'${x['code']}',child:Text('${x['name']}'))).toList(),onChanged:(v)=>refresh((){selectedVillage=v??'';})),
          ],
          if(step>=3) ...[
            const Divider(height:24),
            const Align(alignment:Alignment.centerLeft,child:Text('Logistik & Harga',style:TextStyle(fontWeight:FontWeight.bold))),
            const SizedBox(height:8),
            DropdownButtonFormField<String>(value:selectedShipping.isEmpty?null:selectedShipping,decoration:const InputDecoration(labelText:'Jenis pengiriman *',border:OutlineInputBorder()),items:const [DropdownMenuItem(value:'SEWA',child:Text('Sewa Truk')),DropdownMenuItem(value:'MILIK SENDIRI',child:Text('Milik Sendiri'))],onChanged:(v)=>refresh((){selectedShipping=v??'SEWA';})),
            if(selectedShipping=='SEWA') ...[
              const SizedBox(height:8),
              DropdownButtonFormField<String>(value:selectedPriceList.isEmpty?null:selectedPriceList,decoration:const InputDecoration(labelText:'Item sewa *',border:OutlineInputBorder()),items:priceLists.map((x){final item=x['item']??x['ItemSite']?['item'];return DropdownMenuItem(value:'${x['id']}',child:Text('${item?['nama_item']??x['price_list_name']??'Item sewa'}'));}).toList(),onChanged:(v){if(v==null)return;final p=priceLists.where((x)=>'${x['id']}'==v).toList();refresh((){selectedPriceList=v;sewaPrice.text=p.isNotEmpty?'${p.first['price']??p.first['harga']??0}':'0';});}),
            ],
            const SizedBox(height:8),
            TextField(controller:sewaPrice,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Harga sewa truk (otomatis, bisa diubah)',prefixText:'Rp ',border:OutlineInputBorder())),
            const SizedBox(height:8),
            TextField(controller:kuli,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Biaya kuli',border:OutlineInputBorder())),
            const SizedBox(height:8),
            TextField(controller:intern,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Biaya truk intern',border:OutlineInputBorder())),
          ],
         ])))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),FilledButton(onPressed:()async{
         if(selectedCategory.isEmpty||selectedSupplier.isEmpty||selectedSite.isEmpty||selectedItem.isEmpty){ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content:Text('Lengkapi kategori, site, supplier, dan item')));return;}
         if(step==1){refresh((){step=2;});WidgetsBinding.instance.addPostFrameCallback((_)=>scroll.animateTo(scroll.position.maxScrollExtent,duration:const Duration(milliseconds:350),curve:Curves.easeOut));return;}
         if(step==2){if(selectedProvince.isEmpty||selectedCity.isEmpty||selectedDistrict.isEmpty||selectedVillage.isEmpty){ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content:Text('Lengkapi wilayah pengambilan terlebih dahulu')));return;}refresh((){step=3;});WidgetsBinding.instance.addPostFrameCallback((_)=>scroll.animateTo(scroll.position.maxScrollExtent,duration:const Duration(milliseconds:350),curve:Curves.easeOut));return;}
         final tonase=double.tryParse(t.text.replaceAll(',','.'))??0; final harga=double.tryParse(price.text.replaceAll(',','.'))??0;
          final confirm=await showDialog<bool>(context:ctx,builder:(previewCtx)=>AlertDialog(title:const Text('Preview PO'),content:SizedBox(width:(MediaQuery.sizeOf(previewCtx).width-64).clamp(260.0,360.0),child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Kategori: ${selectedCategory=='1'?'Harga Dibawah':'Titip'}'),Text('Supplier: $supplierLabel'),Text('Site: $siteLabel'),Text('Item: $itemLabel'),Text('Tonase: ${_fmt(tonaseValue,decimal:true)}'),Text('Wilayah: ${regionLabel(provinces,selectedProvince)} / ${regionLabel(cities,selectedCity)} / ${regionLabel(districts,selectedDistrict)} / ${regionLabel(villages,selectedVillage)}'),Text('Pengiriman: ${selectedShipping=='SEWA'?'Sewa Truk':'Milik Sendiri'}'),if(selectedShipping=='SEWA')Text('Item sewa: $priceLabel'),if(selectedShipping=='SEWA')Text('Harga sewa: Rp ${_fmt(sewaValue,decimal:true)}'),Text('Biaya kuli: Rp ${_fmt(kuliValue)}'),Text('Biaya truk intern: Rp ${_fmt(internValue)}'),Text('Harga inc transport: Rp ${_fmt(incTransport)}'),Text('Total harga beli gabah: Rp ${_fmt(totalGabah)}',style:const TextStyle(fontWeight:FontWeight.bold))]))),actions:[TextButton(onPressed:()=>Navigator.pop(previewCtx,false),child:const Text('Kembali')),FilledButton(onPressed:()=>Navigator.pop(previewCtx,true),child:const Text('Simpan'))]));
          if(confirm!=true)return;
          try{await PurchaseService.save({'supplier_id':selectedSupplier,'tanggal_transaksi':DateTime.now().toIso8601String().substring(0,10),'site_id':selectedSite,'kategori_transaksi':selectedCategory,'item_id':selectedCategory=='2'?selectedItem:null,'tonase_supplier':tonase,'harga_supplier':selectedCategory=='2'?null:harga,'nopol_truk':n.text,'provinsi_id':selectedProvince,'kabupaten_id':selectedCity,'kecamatan_id':selectedDistrict,'desa_id':selectedVillage,'jenis_pengiriman':selectedShipping,'item_sewa_id':selectedShipping=='SEWA'&&selectedPriceList.isNotEmpty?selectedPriceList:null,'harga_sewa_truk':sewaValue,'harga_inc_transport':incTransport,'harga_beli_gabah':totalGabah,'biaya_kuli':kuliValue,'biaya_truk_intern':internValue,'details':selectedCategory=='1'?[{'item_id':selectedItem,'tonase_supplier':tonase,'harga_supplier':harga}]:[]},id:row?['id']?.toString());if(ctx.mounted)Navigator.pop(ctx,true);}catch(e){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text('$e')));}
        },child:Text(step==1?'Selanjutnya':step==2?'Selanjutnya':'Preview'))]);
    }));
    if(ok==true)_load();
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Pembelian / PO')),body:Column(children:[Padding(padding:const EdgeInsets.all(12),child:TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari PO atau supplier',border:OutlineInputBorder()),onChanged:(v){search=v;_load();})),Expanded(child:loading?const Center(child:CircularProgressIndicator()):ListView.builder(itemCount:rows.length,itemBuilder:(_,i){final r=rows[i];return Card(child:ListTile(title:Text('${r['kode_transaksi']??'-'}'),subtitle:Text('${r['nama_supplier']??r['supplier_id']??'-'}\nTonase ${r['tonase_supplier']??0}'),isThreeLine:true));}))]),floatingActionButton:FloatingActionButton.extended(onPressed:()=>_form(),label:const Text('Tambah PO'),icon:const Icon(Icons.add)));
}


