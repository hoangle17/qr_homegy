enum OrderStatus { paid, unpaid, free, cancelled }

class Order {
  final int id;
  final int customerId;
  final OrderStatus status;
  final String productId;
  final String orderInfo;

  Order({
    required this.id,
    required this.customerId,
    required this.status,
    required this.productId,
    required this.orderInfo,
  });
} 