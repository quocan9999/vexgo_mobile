/// Public receiving-account settings, shared with the deployed SePay backend.
/// Never place a SePay webhook secret or provider API credential in the app.
class VietQrConfig {
  static const bankId = String.fromEnvironment('SEPAY_BANK_ID');
  static const accountNumber = String.fromEnvironment('SEPAY_ACCOUNT_NUMBER');
  static const accountName = String.fromEnvironment('SEPAY_ACCOUNT_NAME');

  static const account = VietQrReceivingAccount(
    bankId: bankId,
    accountNumber: accountNumber,
    accountName: accountName,
  );

  static bool get isConfigured => account.isConfigured;
  static String? imageUrl(int amount, String orderCode) =>
      account.imageUrl(amount, orderCode);
}

/// Public receiving details. Injectable for deterministic checkout tests; never
/// contains a webhook secret or credentials. Production uses VietQrConfig.account.
class VietQrReceivingAccount {
  final String bankId;
  final String accountNumber;
  final String accountName;
  const VietQrReceivingAccount({
    required this.bankId,
    required this.accountNumber,
    required this.accountName,
  });

  bool get isConfigured =>
      RegExp(r'^[A-Za-z0-9]{2,32}$').hasMatch(bankId) &&
      RegExp(r'^[A-Za-z0-9]{1,19}$').hasMatch(accountNumber) &&
      accountName.trim().isNotEmpty &&
      accountName.length <= 100 &&
      !RegExp(r'[\x00-\x1f\x7f]').hasMatch(accountName);

  String? imageUrl(int amount, String orderCode) {
    if (!isConfigured || amount <= 0 || orderCode.trim().isEmpty) return null;
    return Uri.https(
      'img.vietqr.io',
      '/image/$bankId-$accountNumber-compact2.png',
      {
        'amount': amount.toString(),
        'addInfo': orderCode,
        'accountName': accountName,
      },
    ).toString();
  }
}
