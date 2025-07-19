class QRCodeModel {
  final String id;
  final int orderId;
  final int customerId;
  final bool isActive;
  final String productId;
  final DateTime createdAt;
  final String genCode;

  QRCodeModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.isActive,
    required this.productId,
    required this.createdAt,
    required this.genCode,
  });
}
