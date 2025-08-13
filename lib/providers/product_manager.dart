// lib/providers/product_manager.dart
import 'package:flutter/foundation.dart';

class ProductManager with ChangeNotifier {
  String _currentProduct = 'banana'; // Default to banana chips
  
  // Get the current product category
  String get currentProduct => _currentProduct;
  
  // Set the current product category
  void setProduct(String product) {
    if (_currentProduct != product) {
      _currentProduct = product;
      notifyListeners();
    }
  }
}
