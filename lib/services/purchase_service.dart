import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
class PurchaseService {
 static Future<List<Map<String,dynamic>>> list({String search=''}) async {final t=await AuthService.getToken();final u=Uri.parse('${ApiConfig.baseUrl}/purchase-orders').replace(queryParameters:{'per_page':'100',if(search.isNotEmpty)'search':search});final r=await http.get(u,headers:{'Accept':'application/json','Authorization':'Bearer $t'});final b=jsonDecode(r.body);if(r.statusCode>=400)throw Exception(b['message']??'Gagal memuat pembelian');return ((b['data']['data']??[]) as List).cast<Map<String,dynamic>>();}
 static Future<void> save(Map<String,dynamic> data,{String? id}) async {final t=await AuthService.getToken();final u=Uri.parse('${ApiConfig.baseUrl}/purchase-orders${id==null?'':'/$id'}');final r=id==null?await http.post(u,headers:{'Content-Type':'application/json','Authorization':'Bearer $t'},body:jsonEncode(data)):await http.put(u,headers:{'Content-Type':'application/json','Authorization':'Bearer $t'},body:jsonEncode(data));if(r.statusCode>=400)throw Exception((jsonDecode(r.body) as Map)['message']??'Gagal menyimpan pembelian');}
 static Future<void> remove(String id) async {final t=await AuthService.getToken();final r=await http.delete(Uri.parse('${ApiConfig.baseUrl}/purchase-orders/$id'),headers:{'Authorization':'Bearer $t'});if(r.statusCode>=400)throw Exception('Gagal menghapus pembelian');}
}
