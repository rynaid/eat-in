import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/canteen_model.dart';
import '../models/menu_model.dart';
import '../models/order_model.dart';

class ApiService {
  // Mengambil instance Supabase Client resmi
  final _supabase = Supabase.instance.client;

  // 1. MENCATAT LOG AKTIVITAS (POST)
  Future<void> logActivity(String activityName, String details) async {
    try {
      await _supabase.from('log_activity').insert({
        'activity_name': activityName,
        'details': details,
      });
      debugPrint('Log berhasil dikirim ke Supabase: $activityName');
    } catch (e) {
      debugPrint('Gagal mengirim log ke Supabase: $e');
    }
  }

  // 2. MENGAMBIL DAFTAR KANTIN (GET ALL)
  Future<List<CanteenModel>> fetchCanteens() async {
    try {
      final List<dynamic> response = await _supabase.from('canteens').select();
      return response.map((item) => CanteenModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Gagal memuat data kantin dari Supabase: $e');
    }
  }

  // 3. MENGAMBIL MENU BERDASARKAN ID KANTIN (GET WITH FILTER)
  Future<List<MenuModel>> fetchMenusByCanteen(String canteenId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('menus')
          .select()
          .eq('canteen_id', canteenId);
          
      return response.map((item) => MenuModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Gagal memuat data menu dari Supabase: $e');
      return [];
    }
  }

  // 4. MENGIRIM PESANAN BARU — Mengembalikan orderId jika berhasil
  Future<String?> createOrder(Map<String, dynamic> orderData, List<Map<String, dynamic>> orderItems) async {
    try {
      // Tahap 1: Insert ke tabel 'orders' dan kembalikan data id-nya
      final orderResponse = await _supabase
          .from('orders')
          .insert(orderData)
          .select('id')
          .single();
      
      final String orderId = orderResponse['id'];

      // Tahap 2: Tambahkan order_id ke setiap item yang ada di keranjang
      final itemsToInsert = orderItems.map((item) {
        return {
          'order_id': orderId,
          'menu_id': item['menu_id'],
          'quantity': item['quantity'],
          'price_at_time': item['price_at_time']
        };
      }).toList();

      // Tahap 3: Insert secara massal (bulk insert) ke tabel 'order_items'
      await _supabase.from('order_items').insert(itemsToInsert);
      
      return orderId;
    } catch (e) {
      debugPrint('Gagal membuat pesanan di Supabase: $e');
      return null;
    }
  }

  // 5. MENGAMBIL RIWAYAT PESANAN USER
  Future<List<OrderModel>> fetchOrderHistory(String userId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('orders')
          .select('*, canteens(name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return response.map((item) => OrderModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Gagal memuat riwayat pesanan: $e');
      return [];
    }
  }

  // 6. MENGAMBIL DETAIL PESANAN BERDASARKAN ID
  Future<OrderModel?> fetchOrder(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, canteens(name)')
          .eq('id', orderId)
          .single();
      
      return OrderModel.fromJson(response);
    } catch (e) {
      debugPrint('Gagal memuat pesanan: $e');
      return null;
    }
  }

  // 7. MENGAMBIL PROFILE USER
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      debugPrint('Gagal memuat profile: $e');
      return null;
    }
  }

  // 8. INSERT/UPDATE PROFILE
  Future<void> upsertProfile(String userId, String fullName, String phoneNumber) async {
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'full_name': fullName,
        'phone_number': phoneNumber,
      });
    } catch (e) {
      debugPrint('Gagal menyimpan profile: $e');
    }
  }

  // 9. GET USER ROLE AND CANTEEN (WITH FALLBACK)
  Future<Map<String, dynamic>> getUserRoleAndCanteen(String userId, String email) async {
    try {
      final profile = await fetchProfile(userId);
      if (profile != null) {
        final String role = profile['role']?.toString() ?? '';
        final String canteenId = profile['canteen_id']?.toString() ?? '';
        
        if (role.isNotEmpty) {
          return {
            'role': role,
            'canteen_id': canteenId,
          };
        }
      }
    } catch (e) {
      debugPrint('Info: profiles.role belum ada di DB. Menggunakan fallback email.');
    }

    // Fallback berdasarkan email jika data role belum ada di DB
    if (email.toLowerCase().contains('admin')) {
      String defaultCanteenId = '';
      try {
        final canteens = await fetchCanteens();
        if (canteens.isNotEmpty) {
          defaultCanteenId = canteens.first.id;
        }
      } catch (e) {
        debugPrint('Gagal mencari kantin default: $e');
      }
      return {
        'role': 'admin',
        'canteen_id': defaultCanteenId,
      };
    }

    return {
      'role': 'mahasiswa',
      'canteen_id': '',
    };
  }

  // 10. MENGAMBIL PESANAN KHUSUS UNTUK KANTIN TERTENTU
  Future<List<OrderModel>> fetchOrdersByCanteen(String canteenId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('orders')
          .select('*, canteens(name)')
          .eq('canteen_id', canteenId)
          .order('created_at', ascending: false);
      
      return response.map((item) => OrderModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Gagal memuat pesanan kantin: $e');
      return [];
    }
  }

  // 11. MENGAMBIL ITEM DETAIL PESANAN
  Future<List<Map<String, dynamic>>> fetchOrderItems(String orderId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('order_items')
          .select('*, menus(name)')
          .eq('order_id', orderId);
      
      return response.map((item) {
        final menuMap = item['menus'] as Map<String, dynamic>?;
        return {
          'menu_name': menuMap?['name'] ?? 'Menu Tidak Dikenal',
          'quantity': item['quantity'] ?? 0,
          'price_at_time': item['price_at_time'] ?? 0,
        };
      }).toList();
    } catch (e) {
      debugPrint('Gagal memuat detail item pesanan: $e');
      return [];
    }
  }

  // 12. UPDATE STATUS PESANAN & PEMBAYARAN
  Future<bool> updateOrderStatus(String orderId, String status, {String? paymentStatus}) async {
    try {
      final Map<String, dynamic> updateData = {'order_status': status};
      if (paymentStatus != null) {
        updateData['payment_status'] = paymentStatus;
      }
      await _supabase
          .from('orders')
          .update(updateData)
          .eq('id', orderId);
      return true;
    } catch (e) {
      debugPrint('Gagal memperbarui status pesanan: $e');
      return false;
    }
  }

  // 13. UPDATE STATUS KESIBUKAN KANTIN
  Future<bool> updateCanteenStatus(String canteenId, String status) async {
    try {
      await _supabase
          .from('canteens')
          .update({'status': status})
          .eq('id', canteenId);
      return true;
    } catch (e) {
      debugPrint('Gagal memperbarui status kantin: $e');
      return false;
    }
  }

  // 14. TAMBAH MENU BARU
  Future<bool> addMenuItem(String canteenId, String name, int price, String type) async {
    try {
      await _supabase.from('menus').insert({
        'canteen_id': canteenId,
        'name': name,
        'price': price,
        'type': type,
      });
      return true;
    } catch (e) {
      debugPrint('Gagal menambahkan menu: $e');
      return false;
    }
  }

  // 15. UPDATE MENU
  Future<bool> updateMenuItem(String menuId, String name, int price, String type) async {
    try {
      await _supabase.from('menus').update({
        'name': name,
        'price': price,
        'type': type,
      }).eq('id', menuId);
      return true;
    } catch (e) {
      debugPrint('Gagal memperbarui menu: $e');
      return false;
    }
  }

  // 16. HAPUS MENU
  Future<bool> deleteMenuItem(String menuId) async {
    try {
      await _supabase.from('menus').delete().eq('id', menuId);
      return true;
    } catch (e) {
      debugPrint('Gagal menghapus menu: $e');
      return false;
    }
  }
}