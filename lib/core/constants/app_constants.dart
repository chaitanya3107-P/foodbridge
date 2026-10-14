/// Core constants for the FoodBridge application.
class AppConstants {
  static const String appName = 'FoodBridge';
  static const String appTagline = 'Connecting Surplus Food to Communities';

  /// MANDATORY PRINCIPLE: App supports NGO procedures, does not replace them.
  static const String universalFoodSafetyDisclaimer =
      'Food-safety rules are set by the partner NGO. This app does not guarantee food safety.';

  /// Visible fallback contact for offline/emergency support
  static const String fallbackSupportContact =
      'NGO Support Hotline: +91 98765 43210 | emergency@foodbridge.ngo';

  /// Units of food quantity measurement
  static const List<String> supportedUnits = [
    'kg',
    'litres',
    'servings',
    'boxes',
  ];

  /// Standard food categories
  static const List<String> foodCategories = [
    'Cooked Meals',
    'Raw Produce / Veggies',
    'Bakery & Bread',
    'Packaged Goods',
    'Dairy & Eggs',
    'Beverages',
    'Other Surplus',
  ];

  /// Temperature and storage requirements declared by donor
  static const List<String> storageConditions = [
    'Ambient / Room Temp',
    'Chilled (1°C to 5°C)',
    'Frozen (< -18°C)',
    'Hot Held (> 63°C)',
  ];

  /// Standard allergen declarations
  static const List<String> commonAllergens = [
    'Peanuts',
    'Tree Nuts',
    'Gluten / Wheat',
    'Dairy / Milk',
    'Eggs',
    'Soy',
    'Fish / Shellfish',
    'Sesame',
    'Mustard',
    'None Declared',
  ];

  /// Standard destination categories for food-bank distribution records
  static const List<String> destinationCategories = [
    'Community Kitchen',
    'Homeless Shelter',
    'Student Food Pantry',
    'Low-Income Families',
    'Elderly Care Home',
    'Other Approved Partner',
  ];

  /// Standard remainder disposition options
  static const List<String> remainderDispositions = [
    'Compost',
    'Animal Feed',
    'Safely Discarded',
    'Carried Forward (Re-chilled)',
  ];

  /// Waste audit measurement methods
  static const List<String> auditMeasurementMethods = [
    'Direct Weighing (Scale)',
    'Volume Estimate',
    'Standard Tray Count',
  ];

  /// Standard starter safety checklist items for NGO review
  /// NGO reviewers can freely toggle, edit, or add custom items
  static const List<String> defaultNgoChecklistItems = [
    'Packaging is intact, food-grade, and securely sealed',
    'Visual inspection confirms freshness with no signs of spoilage',
    'Declared storage temperature condition matches food type',
    'Preparation timestamp is valid and within NGO intake guidelines',
    'Allergens are declared and container is adequately labeled',
    'Transport vehicle / insulated container requirement confirmed',
  ];
}
