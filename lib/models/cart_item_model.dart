import 'menu_model.dart';
import '../utils/format_utils.dart';

class CartItemModel {
  final MenuModel menu;
  int quantity;

  CartItemModel({
    required this.menu,
    this.quantity = 1,
  });

  int get subtotal => menu.price * quantity;

  String get formattedSubtotal => FormatUtils.formatRupiah(subtotal);
}
