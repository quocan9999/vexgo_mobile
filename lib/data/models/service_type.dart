import 'package:flutter/material.dart';

enum ServiceType { bus, cargo, ticketLookup }

extension ServiceTypeExt on ServiceType {
  String get label {
    switch (this) {
      case ServiceType.bus:
        return 'Vé xe khách';
      case ServiceType.cargo:
        return 'Gửi hàng hóa';
      case ServiceType.ticketLookup:
        return 'Tra cứu vé';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceType.bus:
        return Icons.directions_bus_rounded;
      case ServiceType.cargo:
        return Icons.local_shipping_rounded;
      case ServiceType.ticketLookup:
        return Icons.receipt_long_rounded;
    }
  }

  bool get isAvailable {
    switch (this) {
      case ServiceType.bus:
      case ServiceType.ticketLookup:
        return true;
      case ServiceType.cargo:
        return false; // Dịch vụ gửi hàng theo xe khách (Coming soon)
    }
  }
}
