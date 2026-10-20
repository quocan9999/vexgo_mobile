/// Utility to map frontend payment method IDs to backend-supported payment providers.
///
/// Supported backend providers per endpoint-api.md 5.7 & MySQL enum:
/// - MOMO
/// - ZALOPAY
/// - VNPAY (handles VietQR, domestic ATM Napas, international cards Visa/Mastercard/JCB)
abstract class PaymentProviderMapper {
  /// Canonical whitelist of supported backend payment providers
  static const Set<String> supportedProviders = {'MOMO', 'ZALOPAY', 'VNPAY'};

  /// Converts UI payment method identifier to uppercase backend provider string.
  ///
  /// Fails closed (throws [ArgumentError]) if [uiMethod] is null, empty, or unknown.
  static String toBackendProvider(String? uiMethod) {
    if (uiMethod == null || uiMethod.trim().isEmpty) {
      throw ArgumentError('Phương thức thanh toán không được để trống.');
    }

    final normalized = uiMethod.trim().toLowerCase();

    switch (normalized) {
      case 'momo':
        return 'MOMO';
      case 'zalopay':
        return 'ZALOPAY';
      case 'vietqr':
      case 'napas':
      case 'visa':
      case 'mastercard':
      case 'jcb':
      case 'vnpay':
        return 'VNPAY';
      default:
        final upper = uiMethod.trim().toUpperCase();
        if (supportedProviders.contains(upper)) {
          return upper;
        }
        throw ArgumentError(
          'Phương thức thanh toán "$uiMethod" không hợp lệ hoặc không được hỗ trợ.',
        );
    }
  }

  /// Checks if a payment method identifier is supported
  static bool isSupported(String? uiMethod) {
    if (uiMethod == null || uiMethod.trim().isEmpty) return false;
    try {
      toBackendProvider(uiMethod);
      return true;
    } catch (_) {
      return false;
    }
  }
}
