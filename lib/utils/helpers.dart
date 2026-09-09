String formatQuantity(int quantity) {
  if (quantity >= 1000) {
    return '${(quantity / 1000).toStringAsFixed(1)}K';
  }
  return quantity.toString();
}

String getShiftLabel(String shift) {
  switch (shift) {
    case 'morning':
      return 'Morning (6AM-2PM)';
    case 'afternoon':
      return 'Afternoon (2PM-10PM)';
    case 'night':
      return 'Night (10PM-6AM)';
    default:
      return shift;
  }
}
