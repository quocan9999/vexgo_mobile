/// Legacy orders included cargo in the online amount; current bookings collect
/// ticket fare online and quote cargo separately for payment at the station.
enum CargoSettlement { none, atStation, includedOnline, unknown }

CargoSettlement cargoSettlement({
  required num onlineTotal,
  required num? ticketSubtotal,
  required num? cargoFee,
}) {
  if (ticketSubtotal == null || cargoFee == null) {
    return CargoSettlement.unknown;
  }
  if (onlineTotal == ticketSubtotal) {
    return cargoFee == 0 ? CargoSettlement.none : CargoSettlement.atStation;
  }
  if (cargoFee > 0 && onlineTotal == ticketSubtotal + cargoFee) {
    return CargoSettlement.includedOnline;
  }
  return CargoSettlement.unknown;
}

String cargoSettlementLabel(CargoSettlement mode) => switch (mode) {
  CargoSettlement.atStation => 'Cước dự tính · thanh toán tại bến',
  CargoSettlement.includedOnline => 'Cước đã cộng trong tổng thanh toán',
  CargoSettlement.none => 'Không phát sinh cước vật phẩm',
  CargoSettlement.unknown => 'Cước vật phẩm (toàn đơn)',
};

String cargoSettlementDescription(CargoSettlement mode) => switch (mode) {
  CargoSettlement.atStation =>
    'Thanh toán cước tại bến khi giao vật phẩm, không cộng vào tiền vé thanh toán trực tuyến.',
  CargoSettlement.includedOnline =>
    'Cước của đơn này đã nằm trong tổng thanh toán trực tuyến; không cộng thêm lần nữa.',
  CargoSettlement.none => 'Không phát sinh cước vật phẩm.',
  CargoSettlement.unknown =>
    'Xem chứng từ để kiểm tra cước đã nằm trong thanh toán hay cần thanh toán tại bến.',
};
