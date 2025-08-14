// lib/config/product_config.dart
class ProductConfig {
  // Define the pack types
  static const String standPouch = 'Stand Pouch';
  static const String squarePack = 'Square Pack';

  // Define the price types
  static const String wholesale = 'Wholesale';
  static const String retail = 'Retail';

  // Central map for product pricing and packaging information
  static const Map<String, Map<String, Map<String, dynamic>>> productPricing = {
    'banana': {
      standPouch: {
        'weight': '180g',
        wholesale: 70.0,
        retail: 100.0,
      },
      squarePack: {
        'weight': '75g',
        wholesale: 20.0,
        retail: 35.0,
      },
    },
    'karlang': {
      standPouch: {
        'weight': '130g',
        wholesale: 70.0,
        retail: 100.0,
      },
      squarePack: {
        'weight': '50g',
        wholesale: 20.0,
        retail: 35.0,
      },
    },
    'kamote': {
      standPouch: {
        'weight': '120g',
        wholesale: 70.0,
        retail: 100.0,
      },
      squarePack: {
        'weight': '45g',
        wholesale: 20.0,
        retail: 35.0,
      },
    },
  };

  // Get the available pack types
  static List<String> get packTypes => [standPouch, squarePack];

  // Get the available price types
  static List<String> get priceTypes => [wholesale, retail];

  // Utility function to get unit price based on product, pack type and price type
  static double getUnitPrice(String product, String packType, String priceType) {
    try {
      return productPricing[product]?[packType]?[priceType] as double? ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Utility function to get weight based on product and pack type
  static String getWeight(String product, String packType) {
    try {
      return productPricing[product]?[packType]?['weight'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  // Utility function to calculate total price
  static double calculateTotalPrice(double unitPrice, int quantity) {
    return unitPrice * quantity;
  }
}
