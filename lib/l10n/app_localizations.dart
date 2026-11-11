import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @uiHome.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get uiHome;

  /// No description provided for @uiMyTickets.
  ///
  /// In vi, this message translates to:
  /// **'Vé của tôi'**
  String get uiMyTickets;

  /// No description provided for @uiShipments.
  ///
  /// In vi, this message translates to:
  /// **'Gửi hàng'**
  String get uiShipments;

  /// No description provided for @uiNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get uiNotifications;

  /// No description provided for @uiAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get uiAccount;

  /// No description provided for @uiLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get uiLanguage;

  /// No description provided for @uiTiNgViT.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get uiTiNgViT;

  /// No description provided for @uiTryAgain.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get uiTryAgain;

  /// No description provided for @uiRefresh.
  ///
  /// In vi, this message translates to:
  /// **'Tải lại'**
  String get uiRefresh;

  /// No description provided for @uiClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get uiClose;

  /// No description provided for @uiCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get uiCancel;

  /// No description provided for @uiStay.
  ///
  /// In vi, this message translates to:
  /// **'Ở lại'**
  String get uiStay;

  /// No description provided for @uiBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get uiBack;

  /// No description provided for @uiSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get uiSignIn;

  /// No description provided for @uiSignOut.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get uiSignOut;

  /// No description provided for @uiSignUp.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get uiSignUp;

  /// No description provided for @uiCreateAccount.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký mới'**
  String get uiCreateAccount;

  /// No description provided for @uiConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get uiConfirm;

  /// No description provided for @uiSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get uiSave;

  /// No description provided for @uiAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get uiAll;

  /// No description provided for @uiSelect.
  ///
  /// In vi, this message translates to:
  /// **'Chọn'**
  String get uiSelect;

  /// No description provided for @uiContinue.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get uiContinue;

  /// No description provided for @uiNo.
  ///
  /// In vi, this message translates to:
  /// **'Không'**
  String get uiNo;

  /// No description provided for @uiYes.
  ///
  /// In vi, this message translates to:
  /// **'Có'**
  String get uiYes;

  /// No description provided for @uiSelectOrigin.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điểm đi'**
  String get uiSelectOrigin;

  /// No description provided for @uiSelectDestination.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điểm đến'**
  String get uiSelectDestination;

  /// No description provided for @uiDestination.
  ///
  /// In vi, this message translates to:
  /// **'Điểm đến'**
  String get uiDestination;

  /// No description provided for @uiOrigin.
  ///
  /// In vi, this message translates to:
  /// **'Điểm đi'**
  String get uiOrigin;

  /// No description provided for @uiOrigind7f375.
  ///
  /// In vi, this message translates to:
  /// **'Điểm xuất phát'**
  String get uiOrigind7f375;

  /// No description provided for @uiSelectOrigin829747.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điểm xuất phát'**
  String get uiSelectOrigin829747;

  /// No description provided for @uiSwapOriginAndDestination.
  ///
  /// In vi, this message translates to:
  /// **'Đổi chiều điểm đi và điểm đến'**
  String get uiSwapOriginAndDestination;

  /// No description provided for @uiBusOperator.
  ///
  /// In vi, this message translates to:
  /// **'Nhà xe'**
  String get uiBusOperator;

  /// No description provided for @uiAccountAndSupport.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản và hỗ trợ'**
  String get uiAccountAndSupport;

  /// No description provided for @uiWhereWouldYouLikeToGo.
  ///
  /// In vi, this message translates to:
  /// **'Bạn muốn đi đâu?'**
  String get uiWhereWouldYouLikeToGo;

  /// No description provided for @uiFindTheRightBusForYourJourney.
  ///
  /// In vi, this message translates to:
  /// **'Tìm chuyến xe phù hợp cho hành trình của bạn.'**
  String get uiFindTheRightBusForYourJourney;

  /// No description provided for @uiUnableToLoadTripSearch.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được dữ liệu tìm chuyến'**
  String get uiUnableToLoadTripSearch;

  /// No description provided for @uiCheckYourConnectionAndTryAgain.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra kết nối và thử lại nhé.'**
  String get uiCheckYourConnectionAndTryAgain;

  /// No description provided for @uiSearchCitiesStationsOrOffices.
  ///
  /// In vi, this message translates to:
  /// **'Tìm tỉnh thành, bến xe, văn phòng...'**
  String get uiSearchCitiesStationsOrOffices;

  /// No description provided for @uiPopularLocations.
  ///
  /// In vi, this message translates to:
  /// **'Địa điểm phổ biến'**
  String get uiPopularLocations;

  /// No description provided for @uiAllLocations.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả địa điểm'**
  String get uiAllLocations;

  /// No description provided for @uiNoMatchingLocations.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy địa điểm phù hợp'**
  String get uiNoMatchingLocations;

  /// No description provided for @uiDistrict.
  ///
  /// In vi, this message translates to:
  /// **'Quận/huyện'**
  String get uiDistrict;

  /// No description provided for @uiProvinceOrCity.
  ///
  /// In vi, this message translates to:
  /// **'Tỉnh/thành phố'**
  String get uiProvinceOrCity;

  /// No description provided for @uiOperatorOffers.
  ///
  /// In vi, this message translates to:
  /// **'Ưu đãi nhà xe'**
  String get uiOperatorOffers;

  /// No description provided for @uiRefreshOffers.
  ///
  /// In vi, this message translates to:
  /// **'Làm mới ưu đãi'**
  String get uiRefreshOffers;

  /// No description provided for @uiUnableToLoadThisOperatorSOffers.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được ưu đãi của nhà xe này.'**
  String get uiUnableToLoadThisOperatorSOffers;

  /// No description provided for @uiRetryOffers.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại ưu đãi'**
  String get uiRetryOffers;

  /// No description provided for @uiThereAreNoCurrentOffersForThisOperator.
  ///
  /// In vi, this message translates to:
  /// **'Hiện chưa có ưu đãi đang mở cho nhà xe này.'**
  String get uiThereAreNoCurrentOffersForThisOperator;

  /// No description provided for @uiEligibilityIsCheckedAgainWhenYouBook.
  ///
  /// In vi, this message translates to:
  /// **'Điều kiện áp dụng được kiểm tra lại khi đặt vé.'**
  String get uiEligibilityIsCheckedAgainWhenYouBook;

  /// No description provided for @uiOfferCodeCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã ưu đãi.'**
  String get uiOfferCodeCopied;

  /// No description provided for @uiOurBusOperatorPartners.
  ///
  /// In vi, this message translates to:
  /// **'Nhà xe uy tín đối tác'**
  String get uiOurBusOperatorPartners;

  /// No description provided for @uiPopularRoutes.
  ///
  /// In vi, this message translates to:
  /// **'Tuyến đường phổ biến'**
  String get uiPopularRoutes;

  /// No description provided for @uiFrom.
  ///
  /// In vi, this message translates to:
  /// **'Từ '**
  String get uiFrom;

  /// No description provided for @uiViewFares.
  ///
  /// In vi, this message translates to:
  /// **'Xem giá vé'**
  String get uiViewFares;

  /// No description provided for @uiNewMemberOffer.
  ///
  /// In vi, this message translates to:
  /// **'ƯU ĐÃI THÀNH VIÊN MỚI'**
  String get uiNewMemberOffer;

  /// No description provided for @uiSave20OnYourFirstTrip.
  ///
  /// In vi, this message translates to:
  /// **'Giảm ngay 20% cho chuyến xe đầu tiên'**
  String get uiSave20OnYourFirstTrip;

  /// No description provided for @uiUseHellovexgoUpToVnd60000.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã HELLOVEXGO • Tối đa 60.000đ'**
  String get uiUseHellovexgoUpToVnd60000;

  /// No description provided for @uiThisWeekSDeal.
  ///
  /// In vi, this message translates to:
  /// **'HOT DEAL TUẦN NÀY'**
  String get uiThisWeekSDeal;

  /// No description provided for @uiSaveVnd50000OnSaigonDaLat.
  ///
  /// In vi, this message translates to:
  /// **'Tuyến Sài Gòn - Đà Lạt giảm 50.000đ'**
  String get uiSaveVnd50000OnSaigonDaLat;

  /// No description provided for @uiForPhNgTrangThNhBI.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng cho nhà xe Phương Trang & Thành Bưởi'**
  String get uiForPhNgTrangThNhBI;

  /// No description provided for @uiTripProtection.
  ///
  /// In vi, this message translates to:
  /// **'BẢO HIỂM CHUYẾN ĐI'**
  String get uiTripProtection;

  /// No description provided for @uiTravelWithAGuaranteedSeat.
  ///
  /// In vi, this message translates to:
  /// **'Cam kết giữ chỗ 100% an tâm'**
  String get uiTravelWithAGuaranteedSeat;

  /// No description provided for @uiLabel150CompensationIfTheOperatorCannotProvideYour.
  ///
  /// In vi, this message translates to:
  /// **'Đền bù gấp rưỡi nếu nhà xe không có chỗ'**
  String get uiLabel150CompensationIfTheOperatorCannotProvideYour;

  /// No description provided for @uiFeaturedOffers.
  ///
  /// In vi, this message translates to:
  /// **'Ưu đãi nổi bật'**
  String get uiFeaturedOffers;

  /// No description provided for @uiViewAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get uiViewAll;

  /// No description provided for @uiRoundTrip.
  ///
  /// In vi, this message translates to:
  /// **'Khứ hồi'**
  String get uiRoundTrip;

  /// No description provided for @uiToggleRoundTrip.
  ///
  /// In vi, this message translates to:
  /// **'Bật tắt vé khứ hồi'**
  String get uiToggleRoundTrip;

  /// No description provided for @uiDepartureDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày đi'**
  String get uiDepartureDate;

  /// No description provided for @uiReturnDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày về'**
  String get uiReturnDate;

  /// No description provided for @uiFindTrips.
  ///
  /// In vi, this message translates to:
  /// **'Tìm chuyến'**
  String get uiFindTrips;

  /// No description provided for @uiIntercityParcelShippingIsComingSoon.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ Gửi hàng hóa theo xe khách liên tỉnh sẽ sớm ra mắt theo đề cương!'**
  String get uiIntercityParcelShippingIsComingSoon;

  /// No description provided for @uiComingSoon.
  ///
  /// In vi, this message translates to:
  /// **'Sắp có'**
  String get uiComingSoon;

  /// No description provided for @uiGuaranteedSeats.
  ///
  /// In vi, this message translates to:
  /// **'Chắc chắn có chỗ 100%'**
  String get uiGuaranteedSeats;

  /// No description provided for @uiLabel150RefundIfTheOperatorDoesNotHonour.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tiền 150% nếu nhà xe không giữ đúng chỗ của bạn.'**
  String get uiLabel150RefundIfTheOperatorDoesNotHonour;

  /// No description provided for @uiLabel247CustomerSupport.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ khách hàng 24/7'**
  String get uiLabel247CustomerSupport;

  /// No description provided for @uiOurSupportTeamIsHereToHelpThroughout.
  ///
  /// In vi, this message translates to:
  /// **'Tổng đài viên luôn sẵn sàng giải đáp và xử lý phát sinh trên hành trình.'**
  String get uiOurSupportTeamIsHereToHelpThroughout;

  /// No description provided for @uiGreatOffersTransparentFares.
  ///
  /// In vi, this message translates to:
  /// **'Nhiều ưu đãi & Giá minh bạch'**
  String get uiGreatOffersTransparentFares;

  /// No description provided for @uiClearlyListedOperatorFaresWithNoHiddenCharges.
  ///
  /// In vi, this message translates to:
  /// **'Giá vé niêm yết rõ ràng từ nhà xe, không phụ phí ẩn.'**
  String get uiClearlyListedOperatorFaresWithNoHiddenCharges;

  /// No description provided for @uiConvenientETickets.
  ///
  /// In vi, this message translates to:
  /// **'Vé điện tử nhanh chóng'**
  String get uiConvenientETickets;

  /// No description provided for @uiBoardWithAScanOfTheQrCode.
  ///
  /// In vi, this message translates to:
  /// **'Lên xe chỉ với một chạm quét mã QR trên điện thoại.'**
  String get uiBoardWithAScanOfTheQrCode;

  /// No description provided for @uiTheVexgoServicePromise.
  ///
  /// In vi, this message translates to:
  /// **'Cam kết dịch vụ từ VexGo'**
  String get uiTheVexgoServicePromise;

  /// No description provided for @uiChatWithOperator.
  ///
  /// In vi, this message translates to:
  /// **'Chat với nhà xe'**
  String get uiChatWithOperator;

  /// No description provided for @uiPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại'**
  String get uiPhoneNumber;

  /// No description provided for @uiFullName.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên *'**
  String get uiFullName;

  /// No description provided for @uiPhoneNumber42d534.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại *'**
  String get uiPhoneNumber42d534;

  /// No description provided for @uiPasswordChangedSuccessfully.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu thành công.'**
  String get uiPasswordChangedSuccessfully;

  /// No description provided for @uiChangePassword.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu'**
  String get uiChangePassword;

  /// No description provided for @uiKeepYourAccountSecure.
  ///
  /// In vi, this message translates to:
  /// **'Bảo vệ tài khoản của bạn'**
  String get uiKeepYourAccountSecure;

  /// No description provided for @uiEnterYourCurrentAndNewPasswordsDoNot.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu hiện tại và mật khẩu mới. Không chia sẻ mật khẩu với người khác.'**
  String get uiEnterYourCurrentAndNewPasswordsDoNot;

  /// No description provided for @uiCurrentPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu hiện tại'**
  String get uiCurrentPassword;

  /// No description provided for @uiCurrentPassword03603d.
  ///
  /// In vi, this message translates to:
  /// **'mật khẩu hiện tại'**
  String get uiCurrentPassword03603d;

  /// No description provided for @uiEnterYourCurrentPassword.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu hiện tại.'**
  String get uiEnterYourCurrentPassword;

  /// No description provided for @uiNewPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới'**
  String get uiNewPassword;

  /// No description provided for @uiNewPassword31bb86.
  ///
  /// In vi, this message translates to:
  /// **'mật khẩu mới'**
  String get uiNewPassword31bb86;

  /// No description provided for @uiPasswordMustBe872Utf8Bytes.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu cần dài 8–72 byte UTF-8.'**
  String get uiPasswordMustBe872Utf8Bytes;

  /// No description provided for @uiYourNewPasswordMustDifferFromYourCurrent.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới phải khác mật khẩu hiện tại.'**
  String get uiYourNewPasswordMustDifferFromYourCurrent;

  /// No description provided for @uiConfirmNewPassword.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu mới'**
  String get uiConfirmNewPassword;

  /// No description provided for @uiPasswordConfirmation.
  ///
  /// In vi, this message translates to:
  /// **'mật khẩu xác nhận'**
  String get uiPasswordConfirmation;

  /// No description provided for @uiPasswordsDoNotMatch.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu xác nhận không khớp.'**
  String get uiPasswordsDoNotMatch;

  /// No description provided for @uiSaving.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu…'**
  String get uiSaving;

  /// No description provided for @uiSavePassword.
  ///
  /// In vi, this message translates to:
  /// **'Lưu mật khẩu'**
  String get uiSavePassword;

  /// No description provided for @uiYourSessionHasChangedOpenForgotPasswordAgain.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đã thay đổi. Vui lòng mở lại Quên mật khẩu.'**
  String get uiYourSessionHasChangedOpenForgotPasswordAgain;

  /// No description provided for @uiTheServerResultCouldNotBeConfirmedTry.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác nhận được kết quả từ máy chủ. Nếu vừa đặt lại mật khẩu, hãy thử đăng nhập bằng mật khẩu mới; nếu chưa được, yêu cầu OTP mới.'**
  String get uiTheServerResultCouldNotBeConfirmedTry;

  /// No description provided for @uiUnableToCompletePleaseTryAgain.
  ///
  /// In vi, this message translates to:
  /// **'Không thể hoàn tất. Vui lòng thử lại.'**
  String get uiUnableToCompletePleaseTryAgain;

  /// No description provided for @uiThisCodeHasExpiredRequestANewCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP đã hết hạn. Vui lòng gửi lại mã.'**
  String get uiThisCodeHasExpiredRequestANewCode;

  /// No description provided for @uiVerificationHasExpiredRequestANewCode.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực đã hết hạn. Vui lòng yêu cầu OTP mới.'**
  String get uiVerificationHasExpiredRequestANewCode;

  /// No description provided for @uiLabel872Utf8BytesAccentedCharactersMay.
  ///
  /// In vi, this message translates to:
  /// **'8–72 byte UTF-8; ký tự có dấu có thể chiếm nhiều byte.'**
  String get uiLabel872Utf8BytesAccentedCharactersMay;

  /// No description provided for @uiHidePassword.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn mật khẩu'**
  String get uiHidePassword;

  /// No description provided for @uiShowPassword.
  ///
  /// In vi, this message translates to:
  /// **'Hiện mật khẩu'**
  String get uiShowPassword;

  /// No description provided for @uiPasswordsDoNotMatchYet.
  ///
  /// In vi, this message translates to:
  /// **'Hai mật khẩu chưa khớp.'**
  String get uiPasswordsDoNotMatchYet;

  /// No description provided for @uiForgotPassword.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu'**
  String get uiForgotPassword;

  /// No description provided for @uiRecoverYourAccount.
  ///
  /// In vi, this message translates to:
  /// **'Lấy lại quyền truy cập'**
  String get uiRecoverYourAccount;

  /// No description provided for @uiVerifyPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực số điện thoại'**
  String get uiVerifyPhoneNumber;

  /// No description provided for @uiSetANewPassword.
  ///
  /// In vi, this message translates to:
  /// **'Đặt mật khẩu mới'**
  String get uiSetANewPassword;

  /// No description provided for @uiPasswordResetSuccessfully.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại mật khẩu thành công'**
  String get uiPasswordResetSuccessfully;

  /// No description provided for @uiEnterYourRegisteredPhoneNumberToRequestA.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số điện thoại đã đăng ký để yêu cầu mã xác thực.'**
  String get uiEnterYourRegisteredPhoneNumberToRequestA;

  /// No description provided for @uiExample0912345678.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: 0912345678'**
  String get uiExample0912345678;

  /// No description provided for @uiVerificationCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP'**
  String get uiVerificationCode;

  /// No description provided for @uiEnterAll6Digits.
  ///
  /// In vi, this message translates to:
  /// **'Nhập đủ 6 chữ số.'**
  String get uiEnterAll6Digits;

  /// No description provided for @uiResendCode.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã OTP'**
  String get uiResendCode;

  /// No description provided for @uiResettingYourPasswordWillEndYourExistingSign.
  ///
  /// In vi, this message translates to:
  /// **'Sau khi đặt lại mật khẩu, các phiên đăng nhập cũ sẽ hết hiệu lực.'**
  String get uiResettingYourPasswordWillEndYourExistingSign;

  /// No description provided for @uiSignInWithYourNewPasswordToContinue.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng đăng nhập bằng mật khẩu mới để tiếp tục.'**
  String get uiSignInWithYourNewPasswordToContinue;

  /// No description provided for @uiRequestCode.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu mã OTP'**
  String get uiRequestCode;

  /// No description provided for @uiVerifyCode.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận OTP'**
  String get uiVerifyCode;

  /// No description provided for @uiResetPassword.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại mật khẩu'**
  String get uiResetPassword;

  /// No description provided for @uiBackToSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Về đăng nhập'**
  String get uiBackToSignIn;

  /// No description provided for @uiChangePhoneNumberStartAgain.
  ///
  /// In vi, this message translates to:
  /// **'Đổi số điện thoại / Bắt đầu lại'**
  String get uiChangePhoneNumberStartAgain;

  /// No description provided for @uiUnableToLoadYourSession.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải phiên đăng nhập.'**
  String get uiUnableToLoadYourSession;

  /// No description provided for @uiVexgoPoints.
  ///
  /// In vi, this message translates to:
  /// **'Điểm tích lũy VexGo'**
  String get uiVexgoPoints;

  /// No description provided for @uiPersonalInformation.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin cá nhân'**
  String get uiPersonalInformation;

  /// No description provided for @uiAiAssistant.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý AI'**
  String get uiAiAssistant;

  /// No description provided for @uiAboutVexgo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin VexGo'**
  String get uiAboutVexgo;

  /// No description provided for @uiSignOut6827e6.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất tài khoản'**
  String get uiSignOut6827e6;

  /// No description provided for @uiVersion100.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản 1.0.0'**
  String get uiVersion100;

  /// No description provided for @uiNoEmailAdded.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cập nhật email'**
  String get uiNoEmailAdded;

  /// No description provided for @uiEditProfile.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa hồ sơ'**
  String get uiEditProfile;

  /// No description provided for @uiWelcomeToVexgo.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng bạn đến với VexGo'**
  String get uiWelcomeToVexgo;

  /// No description provided for @uiSignInForEasierBookingAndToManage.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để đặt vé thuận tiện và quản lý thông tin chuyến đi'**
  String get uiSignInForEasierBookingAndToManage;

  /// No description provided for @uiSignInSignUp.
  ///
  /// In vi, this message translates to:
  /// **'ĐĂNG NHẬP / ĐĂNG KÝ'**
  String get uiSignInSignUp;

  /// No description provided for @uiAreYouSureYouWantToSignOut.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản VexGo không?'**
  String get uiAreYouSureYouWantToSignOut;

  /// No description provided for @uiEnterYourPhoneNumberAndPassword.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập đầy đủ Số điện thoại và Mật khẩu'**
  String get uiEnterYourPhoneNumberAndPassword;

  /// No description provided for @uiCompleteAllRegistrationFields.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập đầy đủ thông tin đăng ký'**
  String get uiCompleteAllRegistrationFields;

  /// No description provided for @uiEnterTheFull6DigitVerificationCode.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập đủ 6 chữ số mã OTP'**
  String get uiEnterTheFull6DigitVerificationCode;

  /// No description provided for @uiCreateAVexgoAccount.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký tài khoản VexGo'**
  String get uiCreateAVexgoAccount;

  /// No description provided for @uiSignInToVexgo.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập VexGo'**
  String get uiSignInToVexgo;

  /// No description provided for @uiEnterYourFullName.
  ///
  /// In vi, this message translates to:
  /// **'Nhập họ và tên đầy đủ'**
  String get uiEnterYourFullName;

  /// No description provided for @uiExample0987654321.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: 0987654321'**
  String get uiExample0987654321;

  /// No description provided for @uiPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu *'**
  String get uiPassword;

  /// No description provided for @uiEnterPassword.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu'**
  String get uiEnterPassword;

  /// No description provided for @uiForgotPassword1630fc.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get uiForgotPassword1630fc;

  /// No description provided for @uiContinueVerifyPhone.
  ///
  /// In vi, this message translates to:
  /// **'TIẾP TỤC (XÁC THỰC OTP)'**
  String get uiContinueVerifyPhone;

  /// No description provided for @uiSignInfe480c.
  ///
  /// In vi, this message translates to:
  /// **'ĐĂNG NHẬP NGAY'**
  String get uiSignInfe480c;

  /// No description provided for @uiByContinuingYouAgreeToVexgoSTerms.
  ///
  /// In vi, this message translates to:
  /// **'Bằng việc tiếp tục, bạn đồng ý với Điều khoản sử dụng của VexGo'**
  String get uiByContinuingYouAgreeToVexgoSTerms;

  /// No description provided for @uiVerifyYourCode.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực mã OTP'**
  String get uiVerifyYourCode;

  /// No description provided for @uiTestCodeHint123456.
  ///
  /// In vi, this message translates to:
  /// **'(Gợi ý mã thử nghiệm: 123456)'**
  String get uiTestCodeHint123456;

  /// No description provided for @uiBackb26cc0.
  ///
  /// In vi, this message translates to:
  /// **'QUAY LẠI'**
  String get uiBackb26cc0;

  /// No description provided for @uiConfirm592364.
  ///
  /// In vi, this message translates to:
  /// **'XÁC NHẬN'**
  String get uiConfirm592364;

  /// No description provided for @uiFullNameIsRequired.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên không được để trống'**
  String get uiFullNameIsRequired;

  /// No description provided for @uiEditPersonalInformation.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa thông tin cá nhân'**
  String get uiEditPersonalInformation;

  /// No description provided for @uiUpdateYourVexgoProfile.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật hồ sơ tài khoản VexGo'**
  String get uiUpdateYourVexgoProfile;

  /// No description provided for @uiVerified.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác thực'**
  String get uiVerified;

  /// No description provided for @uiNotVerified.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác thực'**
  String get uiNotVerified;

  /// No description provided for @uiYourPhoneNumberIsUsedToSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại dùng để đăng nhập và tra cứu vé, không thể thay đổi.'**
  String get uiYourPhoneNumberIsUsedToSignIn;

  /// No description provided for @uiNationalIdNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số CCCD / CMND'**
  String get uiNationalIdNumber;

  /// No description provided for @uiLabel12Digits.
  ///
  /// In vi, this message translates to:
  /// **'12 chữ số'**
  String get uiLabel12Digits;

  /// No description provided for @uiDateOfBirthYyyyMmDd.
  ///
  /// In vi, this message translates to:
  /// **'Ngày sinh (YYYY-MM-DD)'**
  String get uiDateOfBirthYyyyMmDd;

  /// No description provided for @uiSaveChanges.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thay đổi'**
  String get uiSaveChanges;

  /// No description provided for @uiVexgoRewardPoints.
  ///
  /// In vi, this message translates to:
  /// **'Điểm tích lũy VexGo Points'**
  String get uiVexgoRewardPoints;

  /// No description provided for @uiPoints.
  ///
  /// In vi, this message translates to:
  /// **'điểm'**
  String get uiPoints;

  /// No description provided for @uiRedeemPoints.
  ///
  /// In vi, this message translates to:
  /// **'Đổi điểm'**
  String get uiRedeemPoints;

  /// No description provided for @uiYouHaveReachedTheHighestMembershipTier.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã đạt hạng thành viên cao nhất!'**
  String get uiYouHaveReachedTheHighestMembershipTier;

  /// No description provided for @uiVnd30000VoucherForAnyTrip.
  ///
  /// In vi, this message translates to:
  /// **'Voucher 30.000đ mọi chuyến xe'**
  String get uiVnd30000VoucherForAnyTrip;

  /// No description provided for @uiVnd50000VoucherForDaLatVung.
  ///
  /// In vi, this message translates to:
  /// **'Voucher 50.000đ chặng Đà Lạt/Vũng Tàu'**
  String get uiVnd50000VoucherForDaLatVung;

  /// No description provided for @uiVnd100000VoucherForNorthSouthTrips.
  ///
  /// In vi, this message translates to:
  /// **'Voucher 100.000đ chặng Bắc - Nam'**
  String get uiVnd100000VoucherForNorthSouthTrips;

  /// No description provided for @uiVexgoRewardPoints7b38b8.
  ///
  /// In vi, this message translates to:
  /// **'Điểm thưởng VexGo Points'**
  String get uiVexgoRewardPoints7b38b8;

  /// No description provided for @uiAvailableToRedeem.
  ///
  /// In vi, this message translates to:
  /// **'Khả dụng để đổi thưởng'**
  String get uiAvailableToRedeem;

  /// No description provided for @uiRedeemPointsForVouchers.
  ///
  /// In vi, this message translates to:
  /// **'ĐỔI ĐIỂM LẤY VOUCHER'**
  String get uiRedeemPointsForVouchers;

  /// No description provided for @uiRedeem.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mã'**
  String get uiRedeem;

  /// No description provided for @uiPointsHistory.
  ///
  /// In vi, this message translates to:
  /// **'LỊCH SỬ TÍCH & DÙNG ĐIỂM'**
  String get uiPointsHistory;

  /// No description provided for @uiNoPointsTransactionsYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch sử giao dịch điểm.'**
  String get uiNoPointsTransactionsYet;

  /// No description provided for @uiUnableToOpenTheTicketTryAgainIn.
  ///
  /// In vi, this message translates to:
  /// **'Không thể mở vé. Vui lòng thử lại trong Vé của tôi.'**
  String get uiUnableToOpenTheTicketTryAgainIn;

  /// No description provided for @uiMarkAllAsRead.
  ///
  /// In vi, this message translates to:
  /// **'Đọc tất cả'**
  String get uiMarkAllAsRead;

  /// No description provided for @uiTrips.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến đi'**
  String get uiTrips;

  /// No description provided for @uiOffers.
  ///
  /// In vi, this message translates to:
  /// **'Ưu đãi'**
  String get uiOffers;

  /// No description provided for @uiSystem.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống'**
  String get uiSystem;

  /// No description provided for @uiSignInToViewNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để xem thông báo.'**
  String get uiSignInToViewNotifications;

  /// No description provided for @uiUnableToLoadNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải thông báo.'**
  String get uiUnableToLoadNotifications;

  /// No description provided for @uiNoNotificationsYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thông báo nào'**
  String get uiNoNotificationsYet;

  /// No description provided for @uiThereAreNoNotificationsInThisCategoryTrip.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có thông báo trong mục này. Các cập nhật chuyến đi và ưu đãi sẽ xuất hiện tại đây.'**
  String get uiThereAreNoNotificationsInThisCategoryTrip;

  /// No description provided for @uiFilters.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc'**
  String get uiFilters;

  /// No description provided for @uiSearchingForTrips.
  ///
  /// In vi, this message translates to:
  /// **'Đang tìm kiếm chuyến xe...'**
  String get uiSearchingForTrips;

  /// No description provided for @uiSomethingWentWrong.
  ///
  /// In vi, this message translates to:
  /// **'Có lỗi xảy ra'**
  String get uiSomethingWentWrong;

  /// No description provided for @uiUnableToLoadTripsRightNow.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách chuyến xe lúc này.'**
  String get uiUnableToLoadTripsRightNow;

  /// No description provided for @uiNoMatchingTrips.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy chuyến xe phù hợp'**
  String get uiNoMatchingTrips;

  /// No description provided for @uiNoTripsMatchYourFiltersTryChangingThe.
  ///
  /// In vi, this message translates to:
  /// **'Không có chuyến xe nào thỏa mãn các tiêu chí lọc của bạn. Hãy thử thay đổi bộ lọc.'**
  String get uiNoTripsMatchYourFiltersTryChangingThe;

  /// No description provided for @uiResetFilters.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập lại bộ lọc'**
  String get uiResetFilters;

  /// No description provided for @uiToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get uiToday;

  /// No description provided for @uiTomorrow.
  ///
  /// In vi, this message translates to:
  /// **'Ngày mai'**
  String get uiTomorrow;

  /// No description provided for @uiOpenFilters.
  ///
  /// In vi, this message translates to:
  /// **'Mở bộ lọc'**
  String get uiOpenFilters;

  /// No description provided for @uiMorning06001200.
  ///
  /// In vi, this message translates to:
  /// **'Sáng (06:00 - 12:00)'**
  String get uiMorning06001200;

  /// No description provided for @uiEvening18002400.
  ///
  /// In vi, this message translates to:
  /// **'Tối (18:00 - 24:00)'**
  String get uiEvening18002400;

  /// No description provided for @uiThisTripIsSoldOut.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến xe đã hết chỗ'**
  String get uiThisTripIsSoldOut;

  /// No description provided for @uiTripDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết chuyến xe'**
  String get uiTripDetails;

  /// No description provided for @uiSelectTrip.
  ///
  /// In vi, this message translates to:
  /// **'Chọn chuyến'**
  String get uiSelectTrip;

  /// No description provided for @uiUnableToLoadTripDetails.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải chi tiết chuyến'**
  String get uiUnableToLoadTripDetails;

  /// No description provided for @uiAnErrorOccurredWhileLoadingData.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi khi tải dữ liệu.'**
  String get uiAnErrorOccurredWhileLoadingData;

  /// No description provided for @uiCloseTripDetails.
  ///
  /// In vi, this message translates to:
  /// **'Đóng chi tiết chuyến'**
  String get uiCloseTripDetails;

  /// No description provided for @uiRetryLoadingTripDetails.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại tải chi tiết chuyến'**
  String get uiRetryLoadingTripDetails;

  /// No description provided for @uiVehiclePhotos.
  ///
  /// In vi, this message translates to:
  /// **'Hình ảnh xe'**
  String get uiVehiclePhotos;

  /// No description provided for @uiAmenities.
  ///
  /// In vi, this message translates to:
  /// **'Tiện ích'**
  String get uiAmenities;

  /// No description provided for @uiPickUpDropOff.
  ///
  /// In vi, this message translates to:
  /// **'Đón / Trả'**
  String get uiPickUpDropOff;

  /// No description provided for @uiCancellationPolicy.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách hủy'**
  String get uiCancellationPolicy;

  /// No description provided for @uiFaresFrom.
  ///
  /// In vi, this message translates to:
  /// **'Giá chỉ từ'**
  String get uiFaresFrom;

  /// No description provided for @uiSelectThisTrip.
  ///
  /// In vi, this message translates to:
  /// **'CHỌN CHUYẾN NÀY'**
  String get uiSelectThisTrip;

  /// No description provided for @uiSoldOut.
  ///
  /// In vi, this message translates to:
  /// **'CHUYẾN XE ĐÃ HẾT CHỖ'**
  String get uiSoldOut;

  /// No description provided for @uiNoVehiclePhotosAreAvailableForThisTrip.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hình ảnh thực tế cho chuyến xe này'**
  String get uiNoVehiclePhotosAreAvailableForThisTrip;

  /// No description provided for @uiNoAmenityInformationIsAvailableForThisTrip.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thông tin tiện ích cho chuyến xe này'**
  String get uiNoAmenityInformationIsAvailableForThisTrip;

  /// No description provided for @uiCancellationConditions.
  ///
  /// In vi, this message translates to:
  /// **'Điều kiện hủy vé'**
  String get uiCancellationConditions;

  /// No description provided for @uiOpenTicketDetailsToCheckConfirmedCancellationConditions.
  ///
  /// In vi, this message translates to:
  /// **'Mở chi tiết vé để xem điều kiện, phí hủy và số tiền hoàn do hệ thống xác nhận trước khi hủy.'**
  String get uiOpenTicketDetailsToCheckConfirmedCancellationConditions;

  /// No description provided for @uiNoteDuringPublicHolidaysTheOperatorSSpecial.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ý: Vào dịp Lễ/Tết chính sách hoàn hủy vé sẽ tuân theo quy định riêng của nhà xe.'**
  String get uiNoteDuringPublicHolidaysTheOperatorSSpecial;

  /// No description provided for @uiSearchFilters.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc tìm kiếm'**
  String get uiSearchFilters;

  /// No description provided for @uiReset.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập lại'**
  String get uiReset;

  /// No description provided for @uiDepartureTime.
  ///
  /// In vi, this message translates to:
  /// **'GIỜ XUẤT BẾN'**
  String get uiDepartureTime;

  /// No description provided for @uiFareRange.
  ///
  /// In vi, this message translates to:
  /// **'KHOẢNG GIÁ'**
  String get uiFareRange;

  /// No description provided for @uiBusOperatorb6c7ac.
  ///
  /// In vi, this message translates to:
  /// **'NHÀ XE'**
  String get uiBusOperatorb6c7ac;

  /// No description provided for @uiVehicleType.
  ///
  /// In vi, this message translates to:
  /// **'LOẠI XE'**
  String get uiVehicleType;

  /// No description provided for @uiOnboardAmenities.
  ///
  /// In vi, this message translates to:
  /// **'TIỆN ÍCH TRÊN XE'**
  String get uiOnboardAmenities;

  /// No description provided for @uiApplyFilters.
  ///
  /// In vi, this message translates to:
  /// **'ÁP DỤNG BỘ LỌC'**
  String get uiApplyFilters;

  /// No description provided for @uiSortBy.
  ///
  /// In vi, this message translates to:
  /// **'Sắp xếp theo'**
  String get uiSortBy;

  /// No description provided for @uiBookTickets.
  ///
  /// In vi, this message translates to:
  /// **'Đặt vé'**
  String get uiBookTickets;

  /// No description provided for @uiPayment.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán'**
  String get uiPayment;

  /// No description provided for @uiLeaveBooking.
  ///
  /// In vi, this message translates to:
  /// **'Thoát khỏi đặt vé?'**
  String get uiLeaveBooking;

  /// No description provided for @uiThisBookingHasNotBeenFullyVerifiedCheck.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hiện tại chưa hoàn tất xác minh. Kiểm tra trong Vé của tôi trước khi tạo đơn khác.'**
  String get uiThisBookingHasNotBeenFullyVerifiedCheck;

  /// No description provided for @uiLeaveThisBookingYourHeldSeatsWillBe.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn rời khỏi tiến trình đặt vé này không? Vị trí ghế đang giữ sẽ được giải phóng cho người khác.'**
  String get uiLeaveThisBookingYourHeldSeatsWillBe;

  /// No description provided for @uiContinueBooking.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục đặt vé'**
  String get uiContinueBooking;

  /// No description provided for @uiLeave.
  ///
  /// In vi, this message translates to:
  /// **'Rời khỏi'**
  String get uiLeave;

  /// No description provided for @uiTimeExpired.
  ///
  /// In vi, this message translates to:
  /// **'Hết thời gian'**
  String get uiTimeExpired;

  /// No description provided for @uiExpired.
  ///
  /// In vi, this message translates to:
  /// **'hết hạn'**
  String get uiExpired;

  /// No description provided for @uiSeatHoldExpired.
  ///
  /// In vi, this message translates to:
  /// **'Hết giờ giữ ghế'**
  String get uiSeatHoldExpired;

  /// No description provided for @uiTheTemporary10MinuteSeatHoldHasEnded.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian giữ ghế tạm thời (10 phút) đã kết thúc. Vị trí ghế đã được giải phóng để nhường cho khách khác. Vui lòng chọn lại chỗ ngồi để tiếp tục.'**
  String get uiTheTemporary10MinuteSeatHoldHasEnded;

  /// No description provided for @uiGotIt.
  ///
  /// In vi, this message translates to:
  /// **'Đã hiểu'**
  String get uiGotIt;

  /// No description provided for @uiYourAccountSessionHasChanged.
  ///
  /// In vi, this message translates to:
  /// **'Phiên tài khoản đã thay đổi.'**
  String get uiYourAccountSessionHasChanged;

  /// No description provided for @uiOpenBookingAgainIfYouSubmittedABooking.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng mở lại đặt vé. Nếu đã gửi tạo đơn, hãy đăng nhập đúng tài khoản và kiểm tra Vé của tôi trước khi tạo đơn khác. Ghế chưa tạo đơn sẽ được yêu cầu giải phóng hoặc tự hết hạn theo máy chủ.'**
  String get uiOpenBookingAgainIfYouSubmittedABooking;

  /// No description provided for @uiLeaveBooking6d56ab.
  ///
  /// In vi, this message translates to:
  /// **'Rời khỏi đặt vé'**
  String get uiLeaveBooking6d56ab;

  /// No description provided for @uiTicketCodeCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã vé vào bộ nhớ tạm!'**
  String get uiTicketCodeCopied;

  /// No description provided for @uiTicketInformation.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin vé'**
  String get uiTicketInformation;

  /// No description provided for @uiYourSessionHasChangedOpenYourTicketAgain.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đã thay đổi. Vui lòng mở lại vé của bạn.'**
  String get uiYourSessionHasChangedOpenYourTicketAgain;

  /// No description provided for @uiGoToHome.
  ///
  /// In vi, this message translates to:
  /// **'Về trang chủ'**
  String get uiGoToHome;

  /// No description provided for @uiVexgoETicket.
  ///
  /// In vi, this message translates to:
  /// **'Vé điện tử VexGo'**
  String get uiVexgoETicket;

  /// No description provided for @uiBookingSuccessful.
  ///
  /// In vi, this message translates to:
  /// **'Đặt vé thành công!'**
  String get uiBookingSuccessful;

  /// No description provided for @uiYourPaymentHasBeenConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch đã được hệ thống xác nhận'**
  String get uiYourPaymentHasBeenConfirmed;

  /// No description provided for @uiTicketCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã vé:'**
  String get uiTicketCode;

  /// No description provided for @uiCopyTicketCode.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép mã vé'**
  String get uiCopyTicketCode;

  /// No description provided for @uiPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán'**
  String get uiPaid;

  /// No description provided for @uiDepartureDateefda3f.
  ///
  /// In vi, this message translates to:
  /// **'Ngày đi:'**
  String get uiDepartureDateefda3f;

  /// No description provided for @uiPickUpTime.
  ///
  /// In vi, this message translates to:
  /// **'Giờ đón:'**
  String get uiPickUpTime;

  /// No description provided for @uiPickUp.
  ///
  /// In vi, this message translates to:
  /// **'Điểm đón:'**
  String get uiPickUp;

  /// No description provided for @uiDropOff.
  ///
  /// In vi, this message translates to:
  /// **'Điểm trả:'**
  String get uiDropOff;

  /// No description provided for @uiSeats.
  ///
  /// In vi, this message translates to:
  /// **'Chỗ ngồi:'**
  String get uiSeats;

  /// No description provided for @uiTotalPayment.
  ///
  /// In vi, this message translates to:
  /// **'Tổng thanh toán:'**
  String get uiTotalPayment;

  /// No description provided for @uiNumberOfTickets.
  ///
  /// In vi, this message translates to:
  /// **'Số lượng vé:'**
  String get uiNumberOfTickets;

  /// No description provided for @uiShowThisCodeToTheAttendantWhenBoarding.
  ///
  /// In vi, this message translates to:
  /// **'Đưa mã này cho phụ xe khi lên xe'**
  String get uiShowThisCodeToTheAttendantWhenBoarding;

  /// No description provided for @uiPaymentMustBeConfirmedBeforeABoardingCode.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có xác nhận thanh toán để hiển thị mã lên xe.'**
  String get uiPaymentMustBeConfirmedBeforeABoardingCode;

  /// No description provided for @uiPassengerInformation.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin hành khách'**
  String get uiPassengerInformation;

  /// No description provided for @uiFullName2d81b7.
  ///
  /// In vi, this message translates to:
  /// **'Họ tên:'**
  String get uiFullName2d81b7;

  /// No description provided for @uiPhoneNumber3179db.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại:'**
  String get uiPhoneNumber3179db;

  /// No description provided for @uiSaveYourTicketCodeAndBookingPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Lưu mã vé và số điện thoại đã dùng khi đặt vé để tra cứu vé không cần đăng nhập.'**
  String get uiSaveYourTicketCodeAndBookingPhoneNumber;

  /// No description provided for @uiViewMyTickets.
  ///
  /// In vi, this message translates to:
  /// **'Xem vé của tôi'**
  String get uiViewMyTickets;

  /// No description provided for @uiNotProvided.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cập nhật'**
  String get uiNotProvided;

  /// No description provided for @uiNoSeatsAreOnSaleForThisTrip.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến xe chưa có ghế mở bán.'**
  String get uiNoSeatsAreOnSaleForThisTrip;

  /// No description provided for @uiEnterThePassengerSFullName.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập họ và tên hành khách'**
  String get uiEnterThePassengerSFullName;

  /// No description provided for @uiFullNameMustHaveAtLeast2Characters.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên cần ít nhất 2 ký tự'**
  String get uiFullNameMustHaveAtLeast2Characters;

  /// No description provided for @uiEnterAContactPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập số điện thoại liên hệ'**
  String get uiEnterAContactPhoneNumber;

  /// No description provided for @uiInvalidPhoneNumberEG0912345678Or84912345678.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại không hợp lệ (ví dụ: 0912345678 hoặc +84912345678)'**
  String get uiInvalidPhoneNumberEG0912345678Or84912345678;

  /// No description provided for @uiInvalidEmailAddressEGNameEmailCom.
  ///
  /// In vi, this message translates to:
  /// **'Email không đúng định dạng (ví dụ: ten@email.com)'**
  String get uiInvalidEmailAddressEGNameEmailCom;

  /// No description provided for @uiBookingContactDetails.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin liên hệ cho đơn đặt vé'**
  String get uiBookingContactDetails;

  /// No description provided for @uiUsedToConfirmYourBookingAndArrangePick.
  ///
  /// In vi, this message translates to:
  /// **'Dùng để xác nhận thông tin đặt chỗ và liên hệ đón trả trong chuyến đi này.'**
  String get uiUsedToConfirmYourBookingAndArrangePick;

  /// No description provided for @uiFullNamead9f29.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên'**
  String get uiFullNamead9f29;

  /// No description provided for @uiExampleNguyNVNAn.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Nguyễn Văn An'**
  String get uiExampleNguyNVNAn;

  /// No description provided for @uiVietnameseMobileNumbersStartingWith0Or84.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ số di động Việt Nam bắt đầu bằng 0 hoặc +84.'**
  String get uiVietnameseMobileNumbersStartingWith0Or84;

  /// No description provided for @uiEmailOptional.
  ///
  /// In vi, this message translates to:
  /// **'Email (tùy chọn)'**
  String get uiEmailOptional;

  /// No description provided for @uiExampleNameGmailCom.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: nguyenvanan@gmail.com'**
  String get uiExampleNameGmailCom;

  /// No description provided for @uiOptionalIfEnteredUseAValidEmailAddress.
  ///
  /// In vi, this message translates to:
  /// **'Không bắt buộc. Nếu nhập, vui lòng dùng đúng định dạng email.'**
  String get uiOptionalIfEnteredUseAValidEmailAddress;

  /// No description provided for @uiUpdatingFaresOffers.
  ///
  /// In vi, this message translates to:
  /// **'Đang cập nhật giá vé & ưu đãi...'**
  String get uiUpdatingFaresOffers;

  /// No description provided for @uiUpdateFare.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật giá vé'**
  String get uiUpdateFare;

  /// No description provided for @uiReviewYourBooking.
  ///
  /// In vi, this message translates to:
  /// **'Xem lại thông tin chuyến đi'**
  String get uiReviewYourBooking;

  /// No description provided for @uiCheckYourJourneyAndPassengerDetailsBeforeProceeding.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng kiểm tra kỹ thông tin hành trình và hành khách trước khi sang bước thanh toán.'**
  String get uiCheckYourJourneyAndPassengerDetailsBeforeProceeding;

  /// No description provided for @uiEditPickUpDropOff.
  ///
  /// In vi, this message translates to:
  /// **'Sửa đón/trả'**
  String get uiEditPickUpDropOff;

  /// No description provided for @uiSelectedSeats.
  ///
  /// In vi, this message translates to:
  /// **'Chỗ ngồi đã chọn'**
  String get uiSelectedSeats;

  /// No description provided for @uiChangeSeats.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ghế'**
  String get uiChangeSeats;

  /// No description provided for @uiEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get uiEdit;

  /// No description provided for @uiFullName3da3c8.
  ///
  /// In vi, this message translates to:
  /// **'Họ tên'**
  String get uiFullName3da3c8;

  /// No description provided for @uiNotEntered.
  ///
  /// In vi, this message translates to:
  /// **'Chưa nhập'**
  String get uiNotEntered;

  /// No description provided for @uiNotProvidedOptional.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cung cấp (tùy chọn)'**
  String get uiNotProvidedOptional;

  /// No description provided for @uiPromoCodesOffers.
  ///
  /// In vi, this message translates to:
  /// **'Mã khuyến mãi & ưu đãi'**
  String get uiPromoCodesOffers;

  /// No description provided for @uiValidCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã hợp lệ'**
  String get uiValidCode;

  /// No description provided for @uiRemoveCode.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ mã'**
  String get uiRemoveCode;

  /// No description provided for @uiSelectOrEnterAPromoCode.
  ///
  /// In vi, this message translates to:
  /// **'Chọn hoặc nhập mã khuyến mãi'**
  String get uiSelectOrEnterAPromoCode;

  /// No description provided for @uiEnterACodeToCheckEligibility.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã để hệ thống kiểm tra điều kiện'**
  String get uiEnterACodeToCheckEligibility;

  /// No description provided for @uiPaymentDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết thanh toán'**
  String get uiPaymentDetails;

  /// No description provided for @uiFareUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giá vé'**
  String get uiFareUnavailable;

  /// No description provided for @uiServiceFee.
  ///
  /// In vi, this message translates to:
  /// **'Phí dịch vụ'**
  String get uiServiceFee;

  /// No description provided for @uiVerifying.
  ///
  /// In vi, this message translates to:
  /// **'Đang xác minh'**
  String get uiVerifying;

  /// No description provided for @uiFree.
  ///
  /// In vi, this message translates to:
  /// **'Miễn phí'**
  String get uiFree;

  /// No description provided for @uiPromotionalDiscount.
  ///
  /// In vi, this message translates to:
  /// **'Giảm giá ưu đãi'**
  String get uiPromotionalDiscount;

  /// No description provided for @uiEstimatedLuggageFee.
  ///
  /// In vi, this message translates to:
  /// **'Phí hành lý tham khảo (tạm tính)'**
  String get uiEstimatedLuggageFee;

  /// No description provided for @uiFareAfterDiscounts.
  ///
  /// In vi, this message translates to:
  /// **'Tiền vé sau ưu đãi'**
  String get uiFareAfterDiscounts;

  /// No description provided for @uiItemFeesArePaidSeparatelyAtTheStation.
  ///
  /// In vi, this message translates to:
  /// **'Cước vật phẩm thanh toán riêng tại bến'**
  String get uiItemFeesArePaidSeparatelyAtTheStation;

  /// No description provided for @uiTotalDue.
  ///
  /// In vi, this message translates to:
  /// **'Tổng tiền cần thanh toán'**
  String get uiTotalDue;

  /// No description provided for @uiCalculatedWhenBookingIsCreated.
  ///
  /// In vi, this message translates to:
  /// **'Xác định khi tạo đơn'**
  String get uiCalculatedWhenBookingIsCreated;

  /// No description provided for @uiFaresAndOffersAreConfirmedBasedOnYour.
  ///
  /// In vi, this message translates to:
  /// **'Giá vé và ưu đãi được hệ thống xác nhận theo ghế, chuyến đi và thông tin liên hệ. Vé chỉ có hiệu lực sau khi xác minh thanh toán.'**
  String get uiFaresAndOffersAreConfirmedBasedOnYour;

  /// No description provided for @uiBookingResultNotConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả tạo đơn chưa xác định'**
  String get uiBookingResultNotConfirmed;

  /// No description provided for @uiTheServerHasNotConfirmedThisBookingDo.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa phản hồi trạng thái tạo đơn. Không gửi lại yêu cầu để tránh trừ tiền nhiều lần. Vui lòng kiểm tra mục \"Vé của tôi\" hoặc liên hệ tổng đài.'**
  String get uiTheServerHasNotConfirmedThisBookingDo;

  /// No description provided for @uiPaymentAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền thanh toán'**
  String get uiPaymentAmount;

  /// No description provided for @uiTripInformation.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin chuyến đi'**
  String get uiTripInformation;

  /// No description provided for @uiSelectPaymentMethod.
  ///
  /// In vi, this message translates to:
  /// **'Chọn phương thức thanh toán'**
  String get uiSelectPaymentMethod;

  /// No description provided for @uiVietqrBankTransfer.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển khoản VietQR'**
  String get uiVietqrBankTransfer;

  /// No description provided for @uiScanTheQrCodeForAutomaticConfirmation24.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR tự động xác nhận 24/7 (Hỗ trợ mọi ngân hàng & ví điện tử)'**
  String get uiScanTheQrCodeForAutomaticConfirmation24;

  /// No description provided for @uiRecommended.
  ///
  /// In vi, this message translates to:
  /// **'Khuyên dùng'**
  String get uiRecommended;

  /// No description provided for @uiMomoWallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví MoMo'**
  String get uiMomoWallet;

  /// No description provided for @uiInstantPaymentWithMomoDemo.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán tức thì qua ứng dụng MoMo (Demo)'**
  String get uiInstantPaymentWithMomoDemo;

  /// No description provided for @uiZalopayWallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví ZaloPay'**
  String get uiZalopayWallet;

  /// No description provided for @uiSecurePaymentWithZalopayOrZaloDemo.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán an toàn với ví ZaloPay hoặc Zalo (Demo)'**
  String get uiSecurePaymentWithZalopayOrZaloDemo;

  /// No description provided for @uiDomesticBankCard.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ ATM nội địa'**
  String get uiDomesticBankCard;

  /// No description provided for @uiInternetBankingWithOver40VietnameseBanksDemo.
  ///
  /// In vi, this message translates to:
  /// **'Internet Banking hơn 40 ngân hàng Việt Nam (Demo)'**
  String get uiInternetBankingWithOver40VietnameseBanksDemo;

  /// No description provided for @uiInternationalCard.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ quốc tế'**
  String get uiInternationalCard;

  /// No description provided for @uiPayWithVisaMastercardOrJcbDemo.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán thẻ Visa, MasterCard, JCB (Demo)'**
  String get uiPayWithVisaMastercardOrJcbDemo;

  /// No description provided for @uiTicketsAreIssuedOnlyAfterPaymentIsConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ xuất vé sau khi hệ thống xác nhận thanh toán'**
  String get uiTicketsAreIssuedOnlyAfterPaymentIsConfirmed;

  /// No description provided for @uiPaymentConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác nhận thanh toán'**
  String get uiPaymentConfirmed;

  /// No description provided for @uiPaymentForThisBookingHasBeenConfirmedYour.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống đã ghi nhận thanh toán thành công cho đơn hàng này. Vé điện tử đang được đồng bộ và xử lý phát hành. Vui lòng nhấn \"Kiểm tra kết quả thanh toán\" ở thanh bên dưới để làm mới trạng thái vé.'**
  String get uiPaymentForThisBookingHasBeenConfirmedYour;

  /// No description provided for @uiPaymentDeadlineExpired.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đặt vé đã hết hạn thanh toán'**
  String get uiPaymentDeadlineExpired;

  /// No description provided for @uiTheSeatHoldAndPaymentDeadlineHaveExpired.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian giữ chỗ và thanh toán của đơn đã kết thúc. Vui lòng không thực hiện chuyển khoản cho đơn này. Nếu đã chuyển tiền sát giờ, vui lòng nhấn \"Kiểm tra kết quả thanh toán\" hoặc liên hệ tổng đài hỗ trợ.'**
  String get uiTheSeatHoldAndPaymentDeadlineHaveExpired;

  /// No description provided for @uiTimeLeftToPay.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian thanh toán còn lại:'**
  String get uiTimeLeftToPay;

  /// No description provided for @uiCopyBookingCode.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép mã đặt vé'**
  String get uiCopyBookingCode;

  /// No description provided for @uiFareAfterDiscountsfb669a.
  ///
  /// In vi, this message translates to:
  /// **'Tiền vé sau ưu đãi:'**
  String get uiFareAfterDiscountsfb669a;

  /// No description provided for @uiTotalBookingPayment.
  ///
  /// In vi, this message translates to:
  /// **'Tổng đơn thanh toán:'**
  String get uiTotalBookingPayment;

  /// No description provided for @uiSaveYourTicketCodeAndContactPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Lưu mã vé và tra cứu bằng số điện thoại liên hệ để kiểm tra đơn sau khi rời màn hình.'**
  String get uiSaveYourTicketCodeAndContactPhoneNumber;

  /// No description provided for @uiVietqrTransferDetails.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin chuyển khoản VietQR'**
  String get uiVietqrTransferDetails;

  /// No description provided for @uiScanTheQrCodeWithYourBankingApp.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR qua app ngân hàng hoặc sao chép thông tin chuyển khoản chính xác bên dưới:'**
  String get uiScanTheQrCodeWithYourBankingApp;

  /// No description provided for @uiCopyTransferReference.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép nội dung chuyển khoản'**
  String get uiCopyTransferReference;

  /// No description provided for @uiCopyAccountNumber.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép số tài khoản'**
  String get uiCopyAccountNumber;

  /// No description provided for @uiCopyAmount.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép số tiền'**
  String get uiCopyAmount;

  /// No description provided for @uiUnableToLoadTheQrCodeUseThe.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được QR. Bạn có thể chuyển khoản theo thông tin và nội dung bên trên.'**
  String get uiUnableToLoadTheQrCodeUseThe;

  /// No description provided for @uiPaymentIsPending.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch thanh toán đang chờ xử lý'**
  String get uiPaymentIsPending;

  /// No description provided for @uiPaymentLink.
  ///
  /// In vi, this message translates to:
  /// **'đường dẫn thanh toán'**
  String get uiPaymentLink;

  /// No description provided for @uiAboutYourETicket.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ý về vé điện tử'**
  String get uiAboutYourETicket;

  /// No description provided for @uiWhenABookingExpires.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ý khi đơn hàng hết hạn'**
  String get uiWhenABookingExpires;

  /// No description provided for @uiAfterMakingATransfer.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn sau khi chuyển tiền'**
  String get uiAfterMakingATransfer;

  /// No description provided for @uiThisBookingCannotBePaidYetOrIts.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hiện tại chưa đủ điều kiện thanh toán hoặc chưa xác minh được trạng thái. '**
  String get uiThisBookingCannotBePaidYetOrIts;

  /// No description provided for @uiDoNotTransferMoreMoneyTapCheckPayment.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng không chuyển thêm tiền. Nhấn \"Kiểm tra kết quả thanh toán\" '**
  String get uiDoNotTransferMoreMoneyTapCheckPayment;

  /// No description provided for @uiToCheckThisBookingOrContactSupportIf.
  ///
  /// In vi, this message translates to:
  /// **'để kiểm tra đơn hiện tại hoặc liên hệ hỗ trợ nếu đã chuyển khoản.'**
  String get uiToCheckThisBookingOrContactSupportIf;

  /// No description provided for @uiSelectYourSeats.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn chỗ'**
  String get uiSelectYourSeats;

  /// No description provided for @uiSelectDropOff.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điểm trả'**
  String get uiSelectDropOff;

  /// No description provided for @uiEnterDetails.
  ///
  /// In vi, this message translates to:
  /// **'Nhập thông tin'**
  String get uiEnterDetails;

  /// No description provided for @uiShippingFeeIsCalculatedWhenBookingIsCreated.
  ///
  /// In vi, this message translates to:
  /// **'Phí gửi hàng được xác định khi tạo đơn'**
  String get uiShippingFeeIsCalculatedWhenBookingIsCreated;

  /// No description provided for @uiVerifyingFare.
  ///
  /// In vi, this message translates to:
  /// **'Đang xác minh giá'**
  String get uiVerifyingFare;

  /// No description provided for @uiCheckCurrentBooking.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra đơn hiện tại'**
  String get uiCheckCurrentBooking;

  /// No description provided for @uiBookPay.
  ///
  /// In vi, this message translates to:
  /// **'Tạo đơn & Thanh toán'**
  String get uiBookPay;

  /// No description provided for @uiItemsWithYourTicket.
  ///
  /// In vi, this message translates to:
  /// **'Gửi hàng kèm vé'**
  String get uiItemsWithYourTicket;

  /// No description provided for @uiEnterLengthWidthAndHeightEachMustBe.
  ///
  /// In vi, this message translates to:
  /// **'Nhập đủ dài, rộng, cao; mỗi chiều phải lớn hơn 0.'**
  String get uiEnterLengthWidthAndHeightEachMustBe;

  /// No description provided for @uiLengthWidthAndHeightMustBeValidNumbers.
  ///
  /// In vi, this message translates to:
  /// **'Kích thước dài, rộng, cao phải là số hợp lệ lớn hơn 0.'**
  String get uiLengthWidthAndHeightMustBeValidNumbers;

  /// No description provided for @uiMaximumDimensionsAre1508080Cm.
  ///
  /// In vi, this message translates to:
  /// **'Kích thước tối đa cho phép là 150 × 80 × 80 cm.'**
  String get uiMaximumDimensionsAre1508080Cm;

  /// No description provided for @uiItems.
  ///
  /// In vi, this message translates to:
  /// **'Hàng'**
  String get uiItems;

  /// No description provided for @uiLightItems.
  ///
  /// In vi, this message translates to:
  /// **'Hàng nhẹ'**
  String get uiLightItems;

  /// No description provided for @uiBulkyItems.
  ///
  /// In vi, this message translates to:
  /// **'Hàng cồng kềnh'**
  String get uiBulkyItems;

  /// No description provided for @uiMotorbike.
  ///
  /// In vi, this message translates to:
  /// **'Xe máy'**
  String get uiMotorbike;

  /// No description provided for @uiBicycle.
  ///
  /// In vi, this message translates to:
  /// **'Xe đạp'**
  String get uiBicycle;

  /// No description provided for @uiBulkyItemsBicycle.
  ///
  /// In vi, this message translates to:
  /// **'Hàng cồng kềnh / Xe đạp'**
  String get uiBulkyItemsBicycle;

  /// No description provided for @uiStandard.
  ///
  /// In vi, this message translates to:
  /// **'Tiêu chuẩn'**
  String get uiStandard;

  /// No description provided for @uiFragile.
  ///
  /// In vi, this message translates to:
  /// **'Dễ vỡ'**
  String get uiFragile;

  /// No description provided for @uiHighValue.
  ///
  /// In vi, this message translates to:
  /// **'Giá trị cao'**
  String get uiHighValue;

  /// No description provided for @uiRegisterParcelsAMotorbikeOrABicycleFor.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký gửi kiện hàng, xe máy hoặc xe đạp đi cùng chuyến xe'**
  String get uiRegisterParcelsAMotorbikeOrABicycleFor;

  /// No description provided for @uiThisBookingHasBeenCreatedOrIsProcessing.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng đã tạo hoặc đang xử lý. Thông tin gửi hàng đã được khóa để đảm bảo đồng bộ.'**
  String get uiThisBookingHasBeenCreatedOrIsProcessing;

  /// No description provided for @uiItemFeesArePaidSeparatelyAtTheStation6c5a15.
  ///
  /// In vi, this message translates to:
  /// **'Cước vật phẩm thanh toán riêng tại bến. Thông tin người nhận được lấy theo thông tin liên hệ đặt vé và sức chứa được máy chủ xác nhận khi tạo đơn.'**
  String get uiItemFeesArePaidSeparatelyAtTheStation6c5a15;

  /// No description provided for @uiUnableToLoadItemOptions.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được tùy chọn gửi hàng.'**
  String get uiUnableToLoadItemOptions;

  /// No description provided for @uiCheckingShippingServiceCapacityAndDropOffCollection.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra dịch vụ gửi hàng, sức chứa và điểm gửi/nhận...'**
  String get uiCheckingShippingServiceCapacityAndDropOffCollection;

  /// No description provided for @uiRemoveItems.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ gửi hàng'**
  String get uiRemoveItems;

  /// No description provided for @uiThisTripDoesNotAcceptItemsForShipping.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến xe không nhận gửi hàng.'**
  String get uiThisTripDoesNotAcceptItemsForShipping;

  /// No description provided for @uiTurnOffItemsWithYourTicketToContinue.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng tắt gửi hàng kèm vé để tiếp tục đặt vé hành khách như bình thường.'**
  String get uiTurnOffItemsWithYourTicketToContinue;

  /// No description provided for @uiThisTripHasNoValidItemDropOff.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến xe chưa cấu hình điểm gửi/nhận hàng hợp lệ.'**
  String get uiThisTripHasNoValidItemDropOff;

  /// No description provided for @uiRemainingItemCapacityOnThisTrip.
  ///
  /// In vi, this message translates to:
  /// **'Sức chứa gửi hàng còn lại trên chuyến'**
  String get uiRemainingItemCapacityOnThisTrip;

  /// No description provided for @uiItemDropOffCollectionPoints.
  ///
  /// In vi, this message translates to:
  /// **'Điểm gửi & nhận hàng trên tuyến'**
  String get uiItemDropOffCollectionPoints;

  /// No description provided for @uiItemDropOffPoint.
  ///
  /// In vi, this message translates to:
  /// **'Điểm gửi hàng *'**
  String get uiItemDropOffPoint;

  /// No description provided for @uiItemCollectionPoint.
  ///
  /// In vi, this message translates to:
  /// **'Điểm nhận hàng *'**
  String get uiItemCollectionPoint;

  /// No description provided for @uiNoValidItemCategoriesAreAvailableForThis.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến xe chưa có danh mục hàng hóa hợp lệ. Không thể thêm kiện hàng.'**
  String get uiNoValidItemCategoriesAreAvailableForThis;

  /// No description provided for @uiAddItem.
  ///
  /// In vi, this message translates to:
  /// **'Thêm kiện hàng'**
  String get uiAddItem;

  /// No description provided for @uiNoItemsAddedTapAddItemToEnter.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có kiện hàng nào. Nhấn \"Thêm kiện hàng\" để khai báo thông tin hàng gửi.'**
  String get uiNoItemsAddedTapAddItemToEnter;

  /// No description provided for @uiEditItem.
  ///
  /// In vi, this message translates to:
  /// **'Sửa kiện hàng'**
  String get uiEditItem;

  /// No description provided for @uiRemoveItem.
  ///
  /// In vi, this message translates to:
  /// **'Xóa kiện hàng'**
  String get uiRemoveItem;

  /// No description provided for @uiAddNewItem.
  ///
  /// In vi, this message translates to:
  /// **'Thêm kiện hàng mới'**
  String get uiAddNewItem;

  /// No description provided for @uiItemCategory.
  ///
  /// In vi, this message translates to:
  /// **'Phân loại kiện hàng'**
  String get uiItemCategory;

  /// No description provided for @uiItemName.
  ///
  /// In vi, this message translates to:
  /// **'Tên kiện hàng *'**
  String get uiItemName;

  /// No description provided for @uiEGHondaVisionMotorbikeSportsBicycle.
  ///
  /// In vi, this message translates to:
  /// **'VD: Xe máy Honda Vision / Xe đạp thể thao'**
  String get uiEGHondaVisionMotorbikeSportsBicycle;

  /// No description provided for @uiEGGiftBoxDocumentsSuitcase.
  ///
  /// In vi, this message translates to:
  /// **'VD: Thùng quà, tài liệu, vali...'**
  String get uiEGGiftBoxDocumentsSuitcase;

  /// No description provided for @uiQuantity.
  ///
  /// In vi, this message translates to:
  /// **'Số lượng *'**
  String get uiQuantity;

  /// No description provided for @uiFixedWeightKg.
  ///
  /// In vi, this message translates to:
  /// **'Khối lượng cố định (kg)'**
  String get uiFixedWeightKg;

  /// No description provided for @uiWeightKg40.
  ///
  /// In vi, this message translates to:
  /// **'Khối lượng (kg, ≤40) *'**
  String get uiWeightKg40;

  /// No description provided for @uiOptionalDimensionsCmMaximum1508080Cm.
  ///
  /// In vi, this message translates to:
  /// **'Kích thước tùy chọn (cm - tối đa 150 × 80 × 80 cm)'**
  String get uiOptionalDimensionsCmMaximum1508080Cm;

  /// No description provided for @uiLength150.
  ///
  /// In vi, this message translates to:
  /// **'Dài (≤150)'**
  String get uiLength150;

  /// No description provided for @uiWidth80.
  ///
  /// In vi, this message translates to:
  /// **'Rộng (≤80)'**
  String get uiWidth80;

  /// No description provided for @uiHeight80.
  ///
  /// In vi, this message translates to:
  /// **'Cao (≤80)'**
  String get uiHeight80;

  /// No description provided for @uiVehicleModelType.
  ///
  /// In vi, this message translates to:
  /// **'Dòng xe / Loại xe'**
  String get uiVehicleModelType;

  /// No description provided for @uiLicencePlate.
  ///
  /// In vi, this message translates to:
  /// **'Biển số xe'**
  String get uiLicencePlate;

  /// No description provided for @uiHandlingService.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ bảo quản'**
  String get uiHandlingService;

  /// No description provided for @uiItemNotesOptional.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú kiện hàng (tùy chọn)'**
  String get uiItemNotesOptional;

  /// No description provided for @uiUpdateItem.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật kiện hàng'**
  String get uiUpdateItem;

  /// No description provided for @uiSaveItem.
  ///
  /// In vi, this message translates to:
  /// **'Lưu kiện hàng'**
  String get uiSaveItem;

  /// No description provided for @uiItemsAccompanyingYourTicket.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin gửi hàng kèm vé'**
  String get uiItemsAccompanyingYourTicket;

  /// No description provided for @uiShipmentCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã vận đơn gửi hàng'**
  String get uiShipmentCode;

  /// No description provided for @uiShippingRoute.
  ///
  /// In vi, this message translates to:
  /// **'Tuyến gửi hàng'**
  String get uiShippingRoute;

  /// No description provided for @uiConfirmedItems.
  ///
  /// In vi, this message translates to:
  /// **'Kiện hàng đã xác nhận:'**
  String get uiConfirmedItems;

  /// No description provided for @uiRegisteredItems.
  ///
  /// In vi, this message translates to:
  /// **'Kiện hàng đăng ký gửi:'**
  String get uiRegisteredItems;

  /// No description provided for @uiAccompaniedLuggage.
  ///
  /// In vi, this message translates to:
  /// **'Hành lý đi kèm'**
  String get uiAccompaniedLuggage;

  /// No description provided for @uiThisBookingSessionHasEnded.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đặt vé đã kết thúc.'**
  String get uiThisBookingSessionHasEnded;

  /// No description provided for @uiDiscardUnsavedDetails.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ phần đang nhập?'**
  String get uiDiscardUnsavedDetails;

  /// No description provided for @uiUnsavedDetailsWillBeDiscardedSavedItemsWill.
  ///
  /// In vi, this message translates to:
  /// **'Mục chưa lưu sẽ bị bỏ. Các kiện đã lưu vẫn được giữ nguyên.'**
  String get uiUnsavedDetailsWillBeDiscardedSavedItemsWill;

  /// No description provided for @uiKeepEditing.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tiếp'**
  String get uiKeepEditing;

  /// No description provided for @uiDiscardUnsavedDetails5d5a16.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ phần đang nhập'**
  String get uiDiscardUnsavedDetails5d5a16;

  /// No description provided for @uiEstimatedFee.
  ///
  /// In vi, this message translates to:
  /// **'Cước phí dự tính'**
  String get uiEstimatedFee;

  /// No description provided for @uiThisEstimateUsesTheOperatorSPackagesAnd.
  ///
  /// In vi, this message translates to:
  /// **'Cước được dự tính theo gói của nhà xe và có thể thay đổi sau khi kiểm tra vật phẩm. Thanh toán tại bến khi giao vật phẩm, không cộng vào tiền vé thanh toán trực tuyến.'**
  String get uiThisEstimateUsesTheOperatorSPackagesAnd;

  /// No description provided for @uiSaveOrDiscardTheCurrentItemBeforeFinishing.
  ///
  /// In vi, this message translates to:
  /// **'Lưu hoặc hủy mục đang nhập trước khi hoàn tất.'**
  String get uiSaveOrDiscardTheCurrentItemBeforeFinishing;

  /// No description provided for @uiLuggageInformation.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin hành lý'**
  String get uiLuggageInformation;

  /// No description provided for @uiCarryOnLuggageIsFreeWithinTheOperator.
  ///
  /// In vi, this message translates to:
  /// **'Hành lý xách tay được miễn phí trong hạn mức nhà xe. Thêm kiện ký gửi hoặc phương tiện để xem cước dự tính. Các lựa chọn được quản lý riêng theo từng chặng.'**
  String get uiCarryOnLuggageIsFreeWithinTheOperator;

  /// No description provided for @uiOperatorCarryOnAllowance.
  ///
  /// In vi, this message translates to:
  /// **'Hạn mức xách tay theo nhà xe'**
  String get uiOperatorCarryOnAllowance;

  /// No description provided for @uiEachPassengerMayBringOneCarryOnItem.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi hành khách được mang một kiện xách tay trong hạn mức. Kiện vượt hạn mức cần kiểm tra điều kiện ký gửi. Hạn mức áp dụng theo chuyến đang chọn.'**
  String get uiEachPassengerMayBringOneCarryOnItem;

  /// No description provided for @uiVehicles.
  ///
  /// In vi, this message translates to:
  /// **'Phương tiện'**
  String get uiVehicles;

  /// No description provided for @uiNeedsReview.
  ///
  /// In vi, this message translates to:
  /// **'Cần kiểm tra lại'**
  String get uiNeedsReview;

  /// No description provided for @uiYourSessionHasChangedOpenBookingAgain.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đã thay đổi. Vui lòng mở lại đặt vé.'**
  String get uiYourSessionHasChangedOpenBookingAgain;

  /// No description provided for @uiEditLuggage.
  ///
  /// In vi, this message translates to:
  /// **'Sửa hành lý'**
  String get uiEditLuggage;

  /// No description provided for @uiAddCheckedLuggage.
  ///
  /// In vi, this message translates to:
  /// **'Thêm hành lý ký gửi'**
  String get uiAddCheckedLuggage;

  /// No description provided for @uiViewLuggage.
  ///
  /// In vi, this message translates to:
  /// **'Xem hành lý'**
  String get uiViewLuggage;

  /// No description provided for @uiEnterAValidCarryOnWeight0Kg.
  ///
  /// In vi, this message translates to:
  /// **'Nhập khối lượng xách tay hợp lệ (> 0 kg).'**
  String get uiEnterAValidCarryOnWeight0Kg;

  /// No description provided for @uiCarryOnQuantityMustBeAtLeast1.
  ///
  /// In vi, this message translates to:
  /// **'Số kiện xách tay phải từ 1 trở lên.'**
  String get uiCarryOnQuantityMustBeAtLeast1;

  /// No description provided for @uiCheckedLuggage.
  ///
  /// In vi, this message translates to:
  /// **'Hành lý ký gửi'**
  String get uiCheckedLuggage;

  /// No description provided for @uiAccompanyingBicycle.
  ///
  /// In vi, this message translates to:
  /// **'Xe đạp đi kèm'**
  String get uiAccompanyingBicycle;

  /// No description provided for @uiEnterAllThreeDimensionsOrLeaveAllThree.
  ///
  /// In vi, this message translates to:
  /// **'Nhập đủ cả 3 chiều Dài, Rộng, Cao (hoặc để trống cả 3).'**
  String get uiEnterAllThreeDimensionsOrLeaveAllThree;

  /// No description provided for @uiLengthWidthAndHeightMustBeValidNumbers8bcef9.
  ///
  /// In vi, this message translates to:
  /// **'Kích thước Dài, Rộng, Cao phải là số hợp lệ lớn hơn 0.'**
  String get uiLengthWidthAndHeightMustBeValidNumbers8bcef9;

  /// No description provided for @uiItemWeightMustBeAValidNumberGreater.
  ///
  /// In vi, this message translates to:
  /// **'Khối lượng hàng phải là số hợp lệ lớn hơn 0.'**
  String get uiItemWeightMustBeAValidNumberGreater;

  /// No description provided for @uiLuggageItem.
  ///
  /// In vi, this message translates to:
  /// **'Kiện hành lý'**
  String get uiLuggageItem;

  /// No description provided for @uiEnterALuggageItemName.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên kiện hành lý.'**
  String get uiEnterALuggageItemName;

  /// No description provided for @uiQuantityMustBeAWholeNumber1.
  ///
  /// In vi, this message translates to:
  /// **'Số lượng phải là số nguyên ≥ 1.'**
  String get uiQuantityMustBeAWholeNumber1;

  /// No description provided for @uiCheckTheLuggageWeightAndDimensions.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng kiểm tra lại khối lượng và kích thước kiện hành lý.'**
  String get uiCheckTheLuggageWeightAndDimensions;

  /// No description provided for @uiTheCarryOnItemHasChangedStartThe.
  ///
  /// In vi, this message translates to:
  /// **'Kiện xách tay đã thay đổi. Vui lòng mở lại thao tác chuyển ký gửi.'**
  String get uiTheCarryOnItemHasChangedStartThe;

  /// No description provided for @uiDismissMessage.
  ///
  /// In vi, this message translates to:
  /// **'Đóng thông báo'**
  String get uiDismissMessage;

  /// No description provided for @uiThisBookingHasBeenCreatedOrIsProcessing81566a.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng đã tạo hoặc đang xử lý. Thông tin hành lý đi kèm đã được khóa để đảm bảo đồng bộ.'**
  String get uiThisBookingHasBeenCreatedOrIsProcessing81566a;

  /// No description provided for @uiYourSignInSessionHasChangedOpenBooking.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập đã thay đổi. Vui lòng mở lại đặt vé để khai báo hành lý.'**
  String get uiYourSignInSessionHasChangedOpenBooking;

  /// No description provided for @uiSelectedNoCheckedLuggagePassengerTicketsOnly.
  ///
  /// In vi, this message translates to:
  /// **'Đang chọn: Không thêm hành lý ký gửi (chỉ đặt vé hành khách).'**
  String get uiSelectedNoCheckedLuggagePassengerTicketsOnly;

  /// No description provided for @uiViewPolicyAddLuggage.
  ///
  /// In vi, this message translates to:
  /// **'Xem chính sách & Khai báo hành lý đi kèm'**
  String get uiViewPolicyAddLuggage;

  /// No description provided for @uiLoadingTheOperatorSLuggagePolicyAndTrip.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải chính sách hành lý của nhà xe và sức chứa trên chuyến...'**
  String get uiLoadingTheOperatorSLuggagePolicyAndTrip;

  /// No description provided for @uiNoCheckedLuggage.
  ///
  /// In vi, this message translates to:
  /// **'Không thêm hành lý ký gửi'**
  String get uiNoCheckedLuggage;

  /// No description provided for @uiUnableToLoadTheLuggagePolicy.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được chính sách hành lý.'**
  String get uiUnableToLoadTheLuggagePolicy;

  /// No description provided for @uiThisLuggagePolicyIsOver5MinutesOld.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách hành lý đã quá hạn 5 phút. Vui lòng tải lại để tiếp tục.'**
  String get uiThisLuggagePolicyIsOver5MinutesOld;

  /// No description provided for @uiRefreshPolicy.
  ///
  /// In vi, this message translates to:
  /// **'Tải lại chính sách'**
  String get uiRefreshPolicy;

  /// No description provided for @ui1FreeCarryOnLuggage.
  ///
  /// In vi, this message translates to:
  /// **'1. Hành lý xách tay miễn phí'**
  String get ui1FreeCarryOnLuggage;

  /// No description provided for @uiCarryOnRules.
  ///
  /// In vi, this message translates to:
  /// **'Quy định xách tay'**
  String get uiCarryOnRules;

  /// No description provided for @uiEachPassengerMayRegisterOneCarryOnItem.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi hành khách được khai báo một kiện xách tay trong hạn mức. Kiện vượt hạn mức có thể chuyển sang ký gửi khi chuyến xe còn nhận.'**
  String get uiEachPassengerMayRegisterOneCarryOnItem;

  /// No description provided for @uiEditCarryOnItem.
  ///
  /// In vi, this message translates to:
  /// **'Sửa kiện xách tay'**
  String get uiEditCarryOnItem;

  /// No description provided for @uiRemoveCarryOnItem.
  ///
  /// In vi, this message translates to:
  /// **'Xóa kiện xách tay'**
  String get uiRemoveCarryOnItem;

  /// No description provided for @uiMoveToCheckedLuggage.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển sang hành lý ký gửi'**
  String get uiMoveToCheckedLuggage;

  /// No description provided for @uiAddCarryOnItem.
  ///
  /// In vi, this message translates to:
  /// **'Khai báo kiện xách tay'**
  String get uiAddCarryOnItem;

  /// No description provided for @uiAddFreeCarryOnItem.
  ///
  /// In vi, this message translates to:
  /// **'Khai báo kiện xách tay miễn phí'**
  String get uiAddFreeCarryOnItem;

  /// No description provided for @uiSaveCarryOnItem.
  ///
  /// In vi, this message translates to:
  /// **'Lưu kiện xách tay'**
  String get uiSaveCarryOnItem;

  /// No description provided for @uiThisTripDoesNotAcceptCheckedLuggage.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến xe không nhận hành lý ký gửi.'**
  String get uiThisTripDoesNotAcceptCheckedLuggage;

  /// No description provided for @uiYouCanStillBringFreeCarryOnLuggage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn vẫn có thể mang hành lý xách tay miễn phí đúng hạn mức hoặc bấm \"Không thêm hành lý ký gửi\" để tiếp tục đặt vé.'**
  String get uiYouCanStillBringFreeCarryOnLuggage;

  /// No description provided for @uiLuggageQuantitiesAndTypesDependOnRemainingCapacity.
  ///
  /// In vi, this message translates to:
  /// **'Số lượng và loại hành lý phụ thuộc sức chứa còn lại của chuyến xe. Hệ thống sẽ kiểm tra khi bạn chọn hành lý.'**
  String get uiLuggageQuantitiesAndTypesDependOnRemainingCapacity;

  /// No description provided for @uiThisTripHasNoValidCheckedLuggageDrop.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến xe chưa cấu hình điểm gửi/nhận hành lý ký gửi hợp lệ.'**
  String get uiThisTripHasNoValidCheckedLuggageDrop;

  /// No description provided for @uiBicycleMotorbike.
  ///
  /// In vi, this message translates to:
  /// **'Xe đạp / Xe máy'**
  String get uiBicycleMotorbike;

  /// No description provided for @uiCheckedLuggageDropOffCollectionPoints.
  ///
  /// In vi, this message translates to:
  /// **'Điểm gửi & nhận hành lý ký gửi trên tuyến'**
  String get uiCheckedLuggageDropOffCollectionPoints;

  /// No description provided for @uiLuggageDropOffPoint.
  ///
  /// In vi, this message translates to:
  /// **'Điểm gửi hành lý *'**
  String get uiLuggageDropOffPoint;

  /// No description provided for @uiLuggageCollectionPoint.
  ///
  /// In vi, this message translates to:
  /// **'Điểm nhận hành lý *'**
  String get uiLuggageCollectionPoint;

  /// No description provided for @uiEditCheckedLuggage.
  ///
  /// In vi, this message translates to:
  /// **'Sửa hành lý ký gửi'**
  String get uiEditCheckedLuggage;

  /// No description provided for @uiRemoveCheckedLuggage.
  ///
  /// In vi, this message translates to:
  /// **'Xóa hành lý ký gửi'**
  String get uiRemoveCheckedLuggage;

  /// No description provided for @uiAddAccompanyingVehicle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm phương tiện gửi kèm'**
  String get uiAddAccompanyingVehicle;

  /// No description provided for @uiAddCheckedLuggageItem.
  ///
  /// In vi, this message translates to:
  /// **'Thêm kiện hành lý ký gửi'**
  String get uiAddCheckedLuggageItem;

  /// No description provided for @uiSelectLuggagePackageSMLXl.
  ///
  /// In vi, this message translates to:
  /// **'Chọn gói hành lý (S / M / L / XL):'**
  String get uiSelectLuggagePackageSMLXl;

  /// No description provided for @uiAccompanyingVehicleType.
  ///
  /// In vi, this message translates to:
  /// **'Loại phương tiện đi kèm:'**
  String get uiAccompanyingVehicleType;

  /// No description provided for @uiMotorbikeCategoryEstimatedFee.
  ///
  /// In vi, this message translates to:
  /// **'Phân nhóm xe máy (Phí tham khảo):'**
  String get uiMotorbikeCategoryEstimatedFee;

  /// No description provided for @uiVehicleName.
  ///
  /// In vi, this message translates to:
  /// **'Tên phương tiện *'**
  String get uiVehicleName;

  /// No description provided for @uiLuggageItemName.
  ///
  /// In vi, this message translates to:
  /// **'Tên kiện hành lý *'**
  String get uiLuggageItemName;

  /// No description provided for @uiEGHondaVisionMotorbikeGiantBicycle.
  ///
  /// In vi, this message translates to:
  /// **'VD: Xe máy Honda Vision / Xe đạp Giant'**
  String get uiEGHondaVisionMotorbikeGiantBicycle;

  /// No description provided for @uiEGSuitcaseGiftBox.
  ///
  /// In vi, this message translates to:
  /// **'VD: Vali hành lý, thùng quà...'**
  String get uiEGSuitcaseGiftBox;

  /// No description provided for @uiSpecifiedWeightKg.
  ///
  /// In vi, this message translates to:
  /// **'Khối lượng quy định (kg)'**
  String get uiSpecifiedWeightKg;

  /// No description provided for @uiWeightKg.
  ///
  /// In vi, this message translates to:
  /// **'Khối lượng (kg) *'**
  String get uiWeightKg;

  /// No description provided for @uiDetailedDimensions.
  ///
  /// In vi, this message translates to:
  /// **'Kích thước chi tiết'**
  String get uiDetailedDimensions;

  /// No description provided for @uiDimensionsAndVolumetricWeight.
  ///
  /// In vi, this message translates to:
  /// **'Kích thước và khối lượng quy đổi'**
  String get uiDimensionsAndVolumetricWeight;

  /// No description provided for @uiEnterActualDimensionsInCmVolumetricWeightLength.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số đo thực tế theo cm. Khối lượng quy đổi = Dài × Rộng × Cao / 5.000, làm tròn một chữ số thập phân. Khối lượng tính cước là số lớn hơn giữa cân nặng và khối lượng quy đổi. Không dùng kích thước tối đa của gói thay cho số đo thực tế.'**
  String get uiEnterActualDimensionsInCmVolumetricWeightLength;

  /// No description provided for @uiLengthCm.
  ///
  /// In vi, this message translates to:
  /// **'Dài (cm)'**
  String get uiLengthCm;

  /// No description provided for @uiWidthCm.
  ///
  /// In vi, this message translates to:
  /// **'Rộng (cm)'**
  String get uiWidthCm;

  /// No description provided for @uiHandlingAndNotes.
  ///
  /// In vi, this message translates to:
  /// **'Bảo quản và ghi chú'**
  String get uiHandlingAndNotes;

  /// No description provided for @uiSelectSuitableHandlingForFragileOrValuableItems.
  ///
  /// In vi, this message translates to:
  /// **'Chọn dịch vụ phù hợp nếu kiện dễ vỡ hoặc có giá trị. Phụ phí hiển thị theo chính sách nhà xe.'**
  String get uiSelectSuitableHandlingForFragileOrValuableItems;

  /// No description provided for @uiNotesOptional.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú (tùy chọn)'**
  String get uiNotesOptional;

  /// No description provided for @uiUpdateCheckedItem.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật mục ký gửi'**
  String get uiUpdateCheckedItem;

  /// No description provided for @uiSaveCheckedItem.
  ///
  /// In vi, this message translates to:
  /// **'Lưu mục ký gửi'**
  String get uiSaveCheckedItem;

  /// No description provided for @uiCheckingPackageEligibility.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra điều kiện gói'**
  String get uiCheckingPackageEligibility;

  /// No description provided for @uiThisFeeIsEstimatedUsingTheOperatorS.
  ///
  /// In vi, this message translates to:
  /// **'Đây là cước dự tính theo gói của nhà xe. Thanh toán tại bến khi giao vật phẩm, không cộng vào tiền vé thanh toán trực tuyến.'**
  String get uiThisFeeIsEstimatedUsingTheOperatorS;

  /// No description provided for @uiFragileItems.
  ///
  /// In vi, this message translates to:
  /// **'Hàng dễ vỡ'**
  String get uiFragileItems;

  /// No description provided for @uiHighValueItems.
  ///
  /// In vi, this message translates to:
  /// **'Hàng giá trị cao'**
  String get uiHighValueItems;

  /// No description provided for @uiManualMotorbike.
  ///
  /// In vi, this message translates to:
  /// **'Xe số'**
  String get uiManualMotorbike;

  /// No description provided for @uiLargeDisplacementMotorbike.
  ///
  /// In vi, this message translates to:
  /// **'Xe phân khối lớn'**
  String get uiLargeDisplacementMotorbike;

  /// No description provided for @uiYourSeatHoldHasExpiredSelectYourSeats.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian giữ ghế đã hết. Vui lòng chọn lại ghế.'**
  String get uiYourSeatHoldHasExpiredSelectYourSeats;

  /// No description provided for @uiEnterAValidNameAndPhoneNumberTo.
  ///
  /// In vi, this message translates to:
  /// **'Nhập họ tên và số điện thoại hợp lệ để tiếp tục'**
  String get uiEnterAValidNameAndPhoneNumberTo;

  /// No description provided for @uiCompleteLuggageDetailsOrSelectNoCheckedLuggage.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất hành lý đi kèm hoặc chọn \"Không thêm hành lý ký gửi\"'**
  String get uiCompleteLuggageDetailsOrSelectNoCheckedLuggage;

  /// No description provided for @uiCompleteItemDetailsOrTurnOffShippingTo.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất thông tin gửi hàng hoặc tắt gửi hàng để tiếp tục'**
  String get uiCompleteItemDetailsOrTurnOffShippingTo;

  /// No description provided for @uiNextReviewBookingPromoCode.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp theo: xem lại đặt vé & mã ưu đãi'**
  String get uiNextReviewBookingPromoCode;

  /// No description provided for @uiCheckPaymentResult.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra kết quả thanh toán'**
  String get uiCheckPaymentResult;

  /// No description provided for @uiPaidf4bf31.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán:'**
  String get uiPaidf4bf31;

  /// No description provided for @uiBookingValue.
  ///
  /// In vi, this message translates to:
  /// **'Giá trị đơn:'**
  String get uiBookingValue;

  /// No description provided for @uiPaymentConfirmedTapCheckToGetYourTickets.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác nhận thanh toán. Nhấn kiểm tra để nhận vé.'**
  String get uiPaymentConfirmedTapCheckToGetYourTickets;

  /// No description provided for @uiTheBookingPaymentDeadlineHasExpired.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đặt vé đã hết hạn thanh toán.'**
  String get uiTheBookingPaymentDeadlineHasExpired;

  /// No description provided for @uiResultUnconfirmedCheckMyTickets.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả chưa xác định. Vui lòng kiểm tra Vé của tôi.'**
  String get uiResultUnconfirmedCheckMyTickets;

  /// No description provided for @uiYourExistingBookingIsPreservedCheckItBefore.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã tạo vẫn được giữ nguyên. Hãy kiểm tra đơn hiện tại trước khi tiếp tục; không tạo đơn thay thế.'**
  String get uiYourExistingBookingIsPreservedCheckItBefore;

  /// No description provided for @uiYourEnteredDetailsAreKeptSeatAvailabilityAnd.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin bạn đã nhập được giữ lại. Trước khi tiếp tục, hệ thống sẽ kiểm tra lại chỗ trống và thời gian giữ ghế.'**
  String get uiYourEnteredDetailsAreKeptSeatAvailabilityAnd;

  /// No description provided for @uiCheckTicketBooking.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra vé/đơn'**
  String get uiCheckTicketBooking;

  /// No description provided for @uiBackToBooking.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại đặt vé'**
  String get uiBackToBooking;

  /// No description provided for @uiContactSupport.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ hỗ trợ'**
  String get uiContactSupport;

  /// No description provided for @uiUnableToLoadTheSeatMapTryAgain.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải sơ đồ ghế. Vui lòng thử lại.'**
  String get uiUnableToLoadTheSeatMapTryAgain;

  /// No description provided for @uiPickUpcdcaa5.
  ///
  /// In vi, this message translates to:
  /// **'Điểm đón'**
  String get uiPickUpcdcaa5;

  /// No description provided for @uiYouWillSelectPickUpDropOffPoints.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ chọn điểm đón/trả ở bước tiếp theo'**
  String get uiYouWillSelectPickUpDropOffPoints;

  /// No description provided for @uiNextSelectDropOff.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp theo: chọn điểm trả'**
  String get uiNextSelectDropOff;

  /// No description provided for @uiNextPassengerDetails.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp theo: thông tin hành khách'**
  String get uiNextPassengerDetails;

  /// No description provided for @uiSelectedSeatDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết ghế đã chọn'**
  String get uiSelectedSeatDetails;

  /// No description provided for @uiTotalNotYetConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác định tổng tiền'**
  String get uiTotalNotYetConfirmed;

  /// No description provided for @uiVehicleDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết xe'**
  String get uiVehicleDetails;

  /// No description provided for @uiSelectSeats.
  ///
  /// In vi, this message translates to:
  /// **'Chọn chỗ'**
  String get uiSelectSeats;

  /// No description provided for @uiDropOffa7cf52.
  ///
  /// In vi, this message translates to:
  /// **'Điểm trả'**
  String get uiDropOffa7cf52;

  /// No description provided for @uiInformation.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin'**
  String get uiInformation;

  /// No description provided for @uiPayForTickets.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán vé'**
  String get uiPayForTickets;

  /// No description provided for @uiCurrentStep.
  ///
  /// In vi, this message translates to:
  /// **'đang chọn'**
  String get uiCurrentStep;

  /// No description provided for @uiCompleted.
  ///
  /// In vi, this message translates to:
  /// **'đã hoàn thành'**
  String get uiCompleted;

  /// No description provided for @uiUpcomingStep.
  ///
  /// In vi, this message translates to:
  /// **'chưa tới'**
  String get uiUpcomingStep;

  /// No description provided for @uiEnterAPromoCodeToContinue.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã khuyến mãi để tiếp tục.'**
  String get uiEnterAPromoCodeToContinue;

  /// No description provided for @uiUnableToVerifyTheCodeTryAgain.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác nhận được mã. Vui lòng thử lại.'**
  String get uiUnableToVerifyTheCodeTryAgain;

  /// No description provided for @uiPromoCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã khuyến mãi'**
  String get uiPromoCode;

  /// No description provided for @uiEnterACodeToCheckOffersForYour.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã để kiểm tra ưu đãi cho chuyến đi của bạn.'**
  String get uiEnterACodeToCheckOffersForYour;

  /// No description provided for @uiEnterPromoCode.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã khuyến mãi'**
  String get uiEnterPromoCode;

  /// No description provided for @uiExampleVexgo30.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: VEXGO30'**
  String get uiExampleVexgo30;

  /// No description provided for @uiChecking.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra…'**
  String get uiChecking;

  /// No description provided for @uiApply.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng'**
  String get uiApply;

  /// No description provided for @uiUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Không khả dụng'**
  String get uiUnavailable;

  /// No description provided for @uiHeld.
  ///
  /// In vi, this message translates to:
  /// **'Đang giữ'**
  String get uiHeld;

  /// No description provided for @uiBooked.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt'**
  String get uiBooked;

  /// No description provided for @uiSelected.
  ///
  /// In vi, this message translates to:
  /// **'Đang chọn'**
  String get uiSelected;

  /// No description provided for @uiAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Trống'**
  String get uiAvailable;

  /// No description provided for @uiLowerDeck.
  ///
  /// In vi, this message translates to:
  /// **'Tầng dưới'**
  String get uiLowerDeck;

  /// No description provided for @uiUpperDeck.
  ///
  /// In vi, this message translates to:
  /// **'Tầng trên'**
  String get uiUpperDeck;

  /// No description provided for @uiDriverSSteeringWheel.
  ///
  /// In vi, this message translates to:
  /// **'Vô lăng tài xế'**
  String get uiDriverSSteeringWheel;

  /// No description provided for @uiFront.
  ///
  /// In vi, this message translates to:
  /// **'Đầu xe'**
  String get uiFront;

  /// No description provided for @uiDoor.
  ///
  /// In vi, this message translates to:
  /// **'Cửa lên xuống'**
  String get uiDoor;

  /// No description provided for @uiNoSeatMapAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có sơ đồ ghế.'**
  String get uiNoSeatMapAvailable;

  /// No description provided for @uiRear.
  ///
  /// In vi, this message translates to:
  /// **'Cuối xe'**
  String get uiRear;

  /// No description provided for @uiNoStopsAreAvailableForThisTripGo.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có điểm dừng cho chuyến xe này. Vui lòng quay lại chọn chuyến khác.'**
  String get uiNoStopsAreAvailableForThisTripGo;

  /// No description provided for @uiThePromoCodeIsInvalidOrExpired.
  ///
  /// In vi, this message translates to:
  /// **'Mã giảm giá không hợp lệ hoặc đã hết hạn!'**
  String get uiThePromoCodeIsInvalidOrExpired;

  /// No description provided for @uiSelectAVexgoPromoCode.
  ///
  /// In vi, this message translates to:
  /// **'Chọn mã giảm giá VexGo'**
  String get uiSelectAVexgoPromoCode;

  /// No description provided for @uiEnterPromoCodeac6007.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã khuyến mãi...'**
  String get uiEnterPromoCodeac6007;

  /// No description provided for @uiRemove.
  ///
  /// In vi, this message translates to:
  /// **'Gỡ bỏ'**
  String get uiRemove;

  /// No description provided for @uiSelected40b56a.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn'**
  String get uiSelected40b56a;

  /// No description provided for @uiUseNow.
  ///
  /// In vi, this message translates to:
  /// **'Dùng ngay'**
  String get uiUseNow;

  /// No description provided for @uiCancellationReason.
  ///
  /// In vi, this message translates to:
  /// **'Lý do hủy'**
  String get uiCancellationReason;

  /// No description provided for @uiOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get uiOther;

  /// No description provided for @uiCheckStatus.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra trạng thái'**
  String get uiCheckStatus;

  /// No description provided for @uiCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get uiCancelled;

  /// No description provided for @uiBookingPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại đặt vé'**
  String get uiBookingPhoneNumber;

  /// No description provided for @uiInvalidPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại không hợp lệ.'**
  String get uiInvalidPhoneNumber;

  /// No description provided for @uiLookUpPaymentReceipt.
  ///
  /// In vi, this message translates to:
  /// **'Tra cứu chứng từ thanh toán'**
  String get uiLookUpPaymentReceipt;

  /// No description provided for @uiSignInToViewAllTickets.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để xem tất cả vé'**
  String get uiSignInToViewAllTickets;

  /// No description provided for @uiEnterTicketCodeVxgOrPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã vé (VXG-...) hoặc SĐT tra cứu...'**
  String get uiEnterTicketCodeVxgOrPhoneNumber;

  /// No description provided for @uiClearSearch.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tìm kiếm'**
  String get uiClearSearch;

  /// No description provided for @uiUpcoming.
  ///
  /// In vi, this message translates to:
  /// **'Sắp đi'**
  String get uiUpcoming;

  /// No description provided for @uiPastTrips.
  ///
  /// In vi, this message translates to:
  /// **'Đã đi'**
  String get uiPastTrips;

  /// No description provided for @uiUnableToLoadTickets.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách vé'**
  String get uiUnableToLoadTickets;

  /// No description provided for @uiAnErrorOccurredWhileLoadingDataTryAgain.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi trong quá trình tải dữ liệu. Vui lòng thử lại.'**
  String get uiAnErrorOccurredWhileLoadingDataTryAgain;

  /// No description provided for @uiNoMatchingTickets.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy vé phù hợp'**
  String get uiNoMatchingTickets;

  /// No description provided for @uiClearSearchFilters.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bộ lọc tìm kiếm'**
  String get uiClearSearchFilters;

  /// No description provided for @uiNoUpcomingTrips.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có chuyến xe nào sắp đi'**
  String get uiNoUpcomingTrips;

  /// No description provided for @uiDiscoverIntercityBusTripsAtGreatFares.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá ngay hàng trăm chuyến xe khách liên tỉnh chất lượng cao với giá ưu đãi!'**
  String get uiDiscoverIntercityBusTripsAtGreatFares;

  /// No description provided for @uiNoPastTripsYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch sử chuyến đi'**
  String get uiNoPastTripsYet;

  /// No description provided for @uiYourCompletedTripsWillAppearHereSoYou.
  ///
  /// In vi, this message translates to:
  /// **'Các chuyến xe bạn đã hoàn thành sẽ hiển thị tại đây để bạn có thể xem lại hoặc đánh giá.'**
  String get uiYourCompletedTripsWillAppearHereSoYou;

  /// No description provided for @uiNoCancelledTickets.
  ///
  /// In vi, this message translates to:
  /// **'Không có vé nào bị hủy'**
  String get uiNoCancelledTickets;

  /// No description provided for @uiCancelledTicketsAppearHereContactSupportToRequest.
  ///
  /// In vi, this message translates to:
  /// **'Các vé đã hủy được hiển thị tại đây. Để yêu cầu hoàn tiền, vui lòng liên hệ hỗ trợ.'**
  String get uiCancelledTicketsAppearHereContactSupportToRequest;

  /// No description provided for @uiFindATrip.
  ///
  /// In vi, this message translates to:
  /// **'Tìm chuyến ngay'**
  String get uiFindATrip;

  /// No description provided for @uiTicketDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết vé xe'**
  String get uiTicketDetails;

  /// No description provided for @uiLoadingTicketDetails.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải thông tin vé...'**
  String get uiLoadingTicketDetails;

  /// No description provided for @uiUnableToLoadTicketDetails.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải thông tin vé.'**
  String get uiUnableToLoadTicketDetails;

  /// No description provided for @uiContactNumberCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép số liên hệ.'**
  String get uiContactNumberCopied;

  /// No description provided for @uiRefreshTicketStatus.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật trạng thái vé'**
  String get uiRefreshTicketStatus;

  /// No description provided for @uiTripContactDetails.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin liên hệ chuyến đi'**
  String get uiTripContactDetails;

  /// No description provided for @uiTheOperatorHasNotProvidedAContactNumber.
  ///
  /// In vi, this message translates to:
  /// **'Nhà xe chưa cung cấp số liên hệ.'**
  String get uiTheOperatorHasNotProvidedAContactNumber;

  /// No description provided for @uiCopyNumber.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép số'**
  String get uiCopyNumber;

  /// No description provided for @uiFindAnotherTrip.
  ///
  /// In vi, this message translates to:
  /// **'Tìm chuyến khác'**
  String get uiFindAnotherTrip;

  /// No description provided for @uiCancelTicket.
  ///
  /// In vi, this message translates to:
  /// **'Hủy vé'**
  String get uiCancelTicket;

  /// No description provided for @uiRateYourTrip.
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá chuyến đi'**
  String get uiRateYourTrip;

  /// No description provided for @uiBookThisTripAgain.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại chuyến xe này'**
  String get uiBookThisTripAgain;

  /// No description provided for @uiThisTicketHasBeenCancelledOnlineRefundsAre.
  ///
  /// In vi, this message translates to:
  /// **'Vé này đã bị hủy. Hệ thống không hoàn tiền online. Vui lòng liên hệ hỗ trợ và cung cấp mã vé để yêu cầu hoàn tiền theo chính sách nhà xe.'**
  String get uiThisTicketHasBeenCancelledOnlineRefundsAre;

  /// No description provided for @uiFindANewTicket.
  ///
  /// In vi, this message translates to:
  /// **'Tìm vé mới'**
  String get uiFindANewTicket;

  /// No description provided for @uiYourSessionHasChangedOpenTicketDetailsAgain.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đã thay đổi. Vui lòng mở lại thông tin vé.'**
  String get uiYourSessionHasChangedOpenTicketDetailsAgain;

  /// No description provided for @uiVexgoOperator.
  ///
  /// In vi, this message translates to:
  /// **'Nhà xe VexGo'**
  String get uiVexgoOperator;

  /// No description provided for @uiQualityBusService.
  ///
  /// In vi, this message translates to:
  /// **'Xe khách chất lượng cao'**
  String get uiQualityBusService;

  /// No description provided for @uiBoardingQrCodeTapToEnlarge.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR lên xe, chạm để phóng to'**
  String get uiBoardingQrCodeTapToEnlarge;

  /// No description provided for @uiTapToEnlargeQrCode.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để phóng to mã QR'**
  String get uiTapToEnlargeQrCode;

  /// No description provided for @uiUseThisCodeWhenBoardingAtYourPick.
  ///
  /// In vi, this message translates to:
  /// **'Dùng mã này khi lên xe tại điểm đón'**
  String get uiUseThisCodeWhenBoardingAtYourPick;

  /// No description provided for @uiSeat.
  ///
  /// In vi, this message translates to:
  /// **'Chỗ ngồi'**
  String get uiSeat;

  /// No description provided for @uiDepartureDate6d003e.
  ///
  /// In vi, this message translates to:
  /// **'Ngày khởi hành'**
  String get uiDepartureDate6d003e;

  /// No description provided for @uiPassenger.
  ///
  /// In vi, this message translates to:
  /// **'Hành khách:'**
  String get uiPassenger;

  /// No description provided for @uiTicketEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email nhận vé:'**
  String get uiTicketEmail;

  /// No description provided for @uiPaymentMethod.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán qua:'**
  String get uiPaymentMethod;

  /// No description provided for @uiTicketFare.
  ///
  /// In vi, this message translates to:
  /// **'Giá vé này:'**
  String get uiTicketFare;

  /// No description provided for @uiEstimatedRefund.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền dự kiến hoàn:'**
  String get uiEstimatedRefund;

  /// No description provided for @uiNoDataAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu'**
  String get uiNoDataAvailable;

  /// No description provided for @uiCancellationReason525ac0.
  ///
  /// In vi, this message translates to:
  /// **'Lý do hủy:'**
  String get uiCancellationReason525ac0;

  /// No description provided for @uiCancelledOnRequest.
  ///
  /// In vi, this message translates to:
  /// **'Hủy theo yêu cầu'**
  String get uiCancelledOnRequest;

  /// No description provided for @uiThisTicketIsCancelledTheQrCodeIs.
  ///
  /// In vi, this message translates to:
  /// **'Vé đã bị hủy. Mã QR không khả dụng.'**
  String get uiThisTicketIsCancelledTheQrCodeIs;

  /// No description provided for @uiThisTripIsCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến đi đã hoàn thành.'**
  String get uiThisTripIsCompleted;

  /// No description provided for @uiPaymentNotYetConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có xác nhận thanh toán'**
  String get uiPaymentNotYetConfirmed;

  /// No description provided for @uiTheQrCodeIsNotAvailableForThis.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR chưa khả dụng cho vé này.'**
  String get uiTheQrCodeIsNotAvailableForThis;

  /// No description provided for @uiUnpaid.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thanh toán'**
  String get uiUnpaid;

  /// No description provided for @uiChangeOfPlans.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi kế hoạch cá nhân'**
  String get uiChangeOfPlans;

  /// No description provided for @uiThePreviousCancellationResultIsUnconfirmedCheckIts.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác minh kết quả hủy trước đó. Vui lòng kiểm tra trạng thái.'**
  String get uiThePreviousCancellationResultIsUnconfirmedCheckIts;

  /// No description provided for @uiNoValidCancellationFeeIsAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Không có thông tin phí hủy hợp lệ.'**
  String get uiNoValidCancellationFeeIsAvailable;

  /// No description provided for @uiUnableToLoadTicketDetailsAndCancellationFees.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải thông tin vé và phí hủy. Vui lòng thử lại.'**
  String get uiUnableToLoadTicketDetailsAndCancellationFees;

  /// No description provided for @uiBookedTheWrongDepartureDateTime.
  ///
  /// In vi, this message translates to:
  /// **'Đặt nhầm ngày/giờ khởi hành'**
  String get uiBookedTheWrongDepartureDateTime;

  /// No description provided for @uiFoundAlternativeTransport.
  ///
  /// In vi, this message translates to:
  /// **'Tìm được phương tiện di chuyển khác'**
  String get uiFoundAlternativeTransport;

  /// No description provided for @uiHealthReasonsUnexpectedCommitments.
  ///
  /// In vi, this message translates to:
  /// **'Lý do sức khỏe / việc bận đột xuất'**
  String get uiHealthReasonsUnexpectedCommitments;

  /// No description provided for @uiLoadingCurrentCancellationFee.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải phí hủy hiện tại...'**
  String get uiLoadingCurrentCancellationFee;

  /// No description provided for @uiCancelBusTicket.
  ///
  /// In vi, this message translates to:
  /// **'Hủy vé xe'**
  String get uiCancelBusTicket;

  /// No description provided for @uiUnableToCancelTicket.
  ///
  /// In vi, this message translates to:
  /// **'Không thể hủy vé'**
  String get uiUnableToCancelTicket;

  /// No description provided for @uiThisTicketIsNotEligibleForOnlineCancellation.
  ///
  /// In vi, this message translates to:
  /// **'Không đủ điều kiện hủy vé trực tuyến'**
  String get uiThisTicketIsNotEligibleForOnlineCancellation;

  /// No description provided for @uiCopy.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get uiCopy;

  /// No description provided for @uiGotItClose.
  ///
  /// In vi, this message translates to:
  /// **'Đã hiểu và Đóng'**
  String get uiGotItClose;

  /// No description provided for @uiTicketAmountPaid.
  ///
  /// In vi, this message translates to:
  /// **'Tiền vé đã thanh toán:'**
  String get uiTicketAmountPaid;

  /// No description provided for @uiTicketValue.
  ///
  /// In vi, this message translates to:
  /// **'Giá trị vé:'**
  String get uiTicketValue;

  /// No description provided for @uiEstimatedRefundAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền dự kiến hoàn lại:'**
  String get uiEstimatedRefundAmount;

  /// No description provided for @uiOnlineRefundsAreNotAvailableAfterCancellingContact.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống không hoàn tiền online. Sau khi hủy vé, vui lòng liên hệ hỗ trợ và cung cấp mã vé để yêu cầu hoàn tiền theo chính sách nhà xe.'**
  String get uiOnlineRefundsAreNotAvailableAfterCancellingContact;

  /// No description provided for @uiSelectCancellationReason.
  ///
  /// In vi, this message translates to:
  /// **'Chọn lý do hủy vé'**
  String get uiSelectCancellationReason;

  /// No description provided for @uiEnterASpecificReason.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lý do cụ thể'**
  String get uiEnterASpecificReason;

  /// No description provided for @uiPleaseDescribeYourReasonForCancelling.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nêu rõ lý do hủy...'**
  String get uiPleaseDescribeYourReasonForCancelling;

  /// No description provided for @uiConfirmCancellation.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận hủy vé'**
  String get uiConfirmCancellation;

  /// No description provided for @uiKeepTicketClose.
  ///
  /// In vi, this message translates to:
  /// **'Giữ vé / Đóng'**
  String get uiKeepTicketClose;

  /// No description provided for @uiCancellationResultIsUnconfirmedCheckStatusOnlyDo.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác minh kết quả hủy. Chỉ kiểm tra trạng thái, không gửi lại yêu cầu.'**
  String get uiCancellationResultIsUnconfirmedCheckStatusOnlyDo;

  /// No description provided for @uiEstimatedRefundff7ba3.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền dự kiến hoàn: '**
  String get uiEstimatedRefundff7ba3;

  /// No description provided for @uiOnlineRefundsAreNotAvailableAfterCancelling.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống không hoàn tiền online. Sau khi hủy vé, '**
  String get uiOnlineRefundsAreNotAvailableAfterCancelling;

  /// No description provided for @uiContactSupportWithYourTicketCode.
  ///
  /// In vi, this message translates to:
  /// **'vui lòng liên hệ hỗ trợ và cung cấp mã vé '**
  String get uiContactSupportWithYourTicketCode;

  /// No description provided for @uiToRequestARefundUnderTheOperatorS.
  ///
  /// In vi, this message translates to:
  /// **'để yêu cầu hoàn tiền theo chính sách nhà xe.'**
  String get uiToRequestARefundUnderTheOperatorS;

  /// No description provided for @uiIAgreeToCancelWithTheFeeShown.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đồng ý hủy vé với mức phí trên.'**
  String get uiIAgreeToCancelWithTheFeeShown;

  /// No description provided for @uiLookUpATicketWithoutSigningIn.
  ///
  /// In vi, this message translates to:
  /// **'Tra cứu vé không cần đăng nhập'**
  String get uiLookUpATicketWithoutSigningIn;

  /// No description provided for @uiEnterYourTicketCodeAndThePhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã vé và số điện thoại đã dùng khi đặt vé.'**
  String get uiEnterYourTicketCodeAndThePhoneNumber;

  /// No description provided for @uiTicketCode3c82be.
  ///
  /// In vi, this message translates to:
  /// **'Mã vé'**
  String get uiTicketCode3c82be;

  /// No description provided for @uiEnterATicketCode.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mã vé.'**
  String get uiEnterATicketCode;

  /// No description provided for @uiLookUpTicket.
  ///
  /// In vi, this message translates to:
  /// **'Tra cứu vé'**
  String get uiLookUpTicket;

  /// No description provided for @uiOnlineRefundsAreNotAvailableAfterCancellingContact311d2f.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống không hoàn tiền online. Để yêu cầu hoàn tiền sau khi hủy vé, vui lòng liên hệ hỗ trợ và cung cấp mã vé. Đăng nhập để chat với nhà xe.'**
  String get uiOnlineRefundsAreNotAvailableAfterCancellingContact311d2f;

  /// No description provided for @uiYourAccountSessionHasChangedOpenTheReview.
  ///
  /// In vi, this message translates to:
  /// **'Phiên tài khoản đã thay đổi. Vui lòng mở lại đánh giá.'**
  String get uiYourAccountSessionHasChangedOpenTheReview;

  /// No description provided for @uiEdited.
  ///
  /// In vi, this message translates to:
  /// **'Đã chỉnh sửa'**
  String get uiEdited;

  /// No description provided for @uiNoWrittenReview.
  ///
  /// In vi, this message translates to:
  /// **'Không có nội dung nhận xét.'**
  String get uiNoWrittenReview;

  /// No description provided for @uiEditReview.
  ///
  /// In vi, this message translates to:
  /// **'Sửa đánh giá'**
  String get uiEditReview;

  /// No description provided for @uiDeleteReview.
  ///
  /// In vi, this message translates to:
  /// **'Xóa đánh giá'**
  String get uiDeleteReview;

  /// No description provided for @uiThe3DayEditingPeriodHasEnded.
  ///
  /// In vi, this message translates to:
  /// **'Đã hết thời hạn chỉnh sửa 3 ngày.'**
  String get uiThe3DayEditingPeriodHasEnded;

  /// No description provided for @uiDeleteThisReviewAndItsReplies.
  ///
  /// In vi, this message translates to:
  /// **'Xóa đánh giá và phản hồi kèm theo?'**
  String get uiDeleteThisReviewAndItsReplies;

  /// No description provided for @uiKeep.
  ///
  /// In vi, this message translates to:
  /// **'Giữ lại'**
  String get uiKeep;

  /// No description provided for @uiConfirmDeletion.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận xóa'**
  String get uiConfirmDeletion;

  /// No description provided for @uiWhatDidYouLikeMost.
  ///
  /// In vi, this message translates to:
  /// **'Điểm bạn hài lòng nhất'**
  String get uiWhatDidYouLikeMost;

  /// No description provided for @uiOnTime.
  ///
  /// In vi, this message translates to:
  /// **'Đúng giờ'**
  String get uiOnTime;

  /// No description provided for @uiCleanVehicle.
  ///
  /// In vi, this message translates to:
  /// **'Xe sạch sẽ'**
  String get uiCleanVehicle;

  /// No description provided for @uiSafeDriving.
  ///
  /// In vi, this message translates to:
  /// **'Lái xe an toàn'**
  String get uiSafeDriving;

  /// No description provided for @uiHelpfulStaff.
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên nhiệt tình'**
  String get uiHelpfulStaff;

  /// No description provided for @uiGoodAmenities.
  ///
  /// In vi, this message translates to:
  /// **'Tiện nghi đầy đủ'**
  String get uiGoodAmenities;

  /// No description provided for @uiConvenientPickUpDropOff.
  ///
  /// In vi, this message translates to:
  /// **'Đón trả thuận tiện'**
  String get uiConvenientPickUpDropOff;

  /// No description provided for @uiDetailedReview.
  ///
  /// In vi, this message translates to:
  /// **'Nhận xét chi tiết'**
  String get uiDetailedReview;

  /// No description provided for @uiShareYourTripExperience.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ trải nghiệm chuyến đi'**
  String get uiShareYourTripExperience;

  /// No description provided for @uiSubmitReview.
  ///
  /// In vi, this message translates to:
  /// **'Gửi đánh giá'**
  String get uiSubmitReview;

  /// No description provided for @uiCancelEditing.
  ///
  /// In vi, this message translates to:
  /// **'Hủy chỉnh sửa'**
  String get uiCancelEditing;

  /// No description provided for @uiRefreshReview.
  ///
  /// In vi, this message translates to:
  /// **'Tải lại đánh giá'**
  String get uiRefreshReview;

  /// No description provided for @uiAboutReviews.
  ///
  /// In vi, this message translates to:
  /// **'Về đánh giá'**
  String get uiAboutReviews;

  /// No description provided for @uiSubmitAReviewWithin7DaysOfDeparture.
  ///
  /// In vi, this message translates to:
  /// **'Gửi đánh giá trong 7 ngày kể từ khi khởi hành. Bạn có thể sửa trong 3 ngày sau khi gửi. Quyền sửa do máy chủ xác nhận. Bạn có thể xóa đánh giá của mình.'**
  String get uiSubmitAReviewWithin7DaysOfDeparture;

  /// No description provided for @uiETicketCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã vé điện tử (E-Ticket)'**
  String get uiETicketCode;

  /// No description provided for @uiTicketCode782acf.
  ///
  /// In vi, this message translates to:
  /// **'Mã vé: '**
  String get uiTicketCode782acf;

  /// No description provided for @uiShowThisCodeToTheAttendantOrDriver.
  ///
  /// In vi, this message translates to:
  /// **'Đưa mã này cho Phụ xe hoặc Tài xế quét soát vé khi lên xe'**
  String get uiShowThisCodeToTheAttendantOrDriver;

  /// No description provided for @uiSeatfd20bf.
  ///
  /// In vi, this message translates to:
  /// **'Ghế'**
  String get uiSeatfd20bf;

  /// No description provided for @uiTotal.
  ///
  /// In vi, this message translates to:
  /// **'Tổng tiền'**
  String get uiTotal;

  /// No description provided for @uiViewTicketQr.
  ///
  /// In vi, this message translates to:
  /// **'Xem vé & QR'**
  String get uiViewTicketQr;

  /// No description provided for @uiViewDetails.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết'**
  String get uiViewDetails;

  /// No description provided for @uiReview.
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá'**
  String get uiReview;

  /// No description provided for @uiViewReview.
  ///
  /// In vi, this message translates to:
  /// **'Xem đánh giá'**
  String get uiViewReview;

  /// No description provided for @uiBookARoundTrip.
  ///
  /// In vi, this message translates to:
  /// **'Đặt vé khứ hồi'**
  String get uiBookARoundTrip;

  /// No description provided for @uiTripDetailsMissing.
  ///
  /// In vi, this message translates to:
  /// **'Thiếu dữ liệu chuyến đi'**
  String get uiTripDetailsMissing;

  /// No description provided for @uiTheSelectedTripPairCouldNotBeFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy thông tin cặp chuyến đã chọn. Vui lòng quay lại tìm chuyến.'**
  String get uiTheSelectedTripPairCouldNotBeFound;

  /// No description provided for @uiBackToSearch.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại tìm kiếm'**
  String get uiBackToSearch;

  /// No description provided for @uiOutbound.
  ///
  /// In vi, this message translates to:
  /// **'Lượt đi'**
  String get uiOutbound;

  /// No description provided for @uiReturn.
  ///
  /// In vi, this message translates to:
  /// **'Lượt về'**
  String get uiReturn;

  /// No description provided for @uiLeavePayment.
  ///
  /// In vi, this message translates to:
  /// **'Rời khỏi trang thanh toán?'**
  String get uiLeavePayment;

  /// No description provided for @uiYourBookingHasBeenRecordedLeavingWillNot.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng của bạn đã được ghi nhận trên hệ thống. Việc rời khỏi đây sẽ không tự động hủy đơn. Bạn có thể tra cứu và thanh toán lại tại mục \"Vé của tôi\".'**
  String get uiYourBookingHasBeenRecordedLeavingWillNot;

  /// No description provided for @uiLeaveRoundTripBooking.
  ///
  /// In vi, this message translates to:
  /// **'Thoát khỏi đặt vé khứ hồi?'**
  String get uiLeaveRoundTripBooking;

  /// No description provided for @uiLeaveThisBookingYourHeldSeatsWillBea1380d.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn rời khỏi tiến trình đặt vé không? Vị trí ghế đang giữ sẽ được giải phóng cho hành khách khác.'**
  String get uiLeaveThisBookingYourHeldSeatsWillBea1380d;

  /// No description provided for @uiNoSeatsSelected.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn ghế'**
  String get uiNoSeatsSelected;

  /// No description provided for @uiSignInSessionChanged.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập đã thay đổi'**
  String get uiSignInSessionChanged;

  /// No description provided for @uiYouHaveSignedOutOrYourSessionHas.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản đã đăng xuất hoặc thay đổi phiên. Vui lòng quay lại tìm kiếm chuyến đi mới.'**
  String get uiYouHaveSignedOutOrYourSessionHas;

  /// No description provided for @uiGoToHome8a211a.
  ///
  /// In vi, this message translates to:
  /// **'Về Trang chủ'**
  String get uiGoToHome8a211a;

  /// No description provided for @uiInvalidSearchDetails.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin tìm kiếm không hợp lệ.'**
  String get uiInvalidSearchDetails;

  /// No description provided for @uiFindRoundTrips.
  ///
  /// In vi, this message translates to:
  /// **'Tìm chuyến khứ hồi'**
  String get uiFindRoundTrips;

  /// No description provided for @uiUnableToFindTrips.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tìm chuyến'**
  String get uiUnableToFindTrips;

  /// No description provided for @uiTheRouteOrDepartureReturnDatesAreInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu tuyến đường hoặc ngày đi/về không hợp lệ.'**
  String get uiTheRouteOrDepartureReturnDatesAreInvalid;

  /// No description provided for @uiOutboundSelected.
  ///
  /// In vi, this message translates to:
  /// **'Lượt đi (Đã chọn)'**
  String get uiOutboundSelected;

  /// No description provided for @uiReturnSelected.
  ///
  /// In vi, this message translates to:
  /// **'Lượt về (Đã chọn)'**
  String get uiReturnSelected;

  /// No description provided for @uiThisOutboundTripDoesNotMatchTheSelected.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến đi không tương thích với chuyến về đã chọn.'**
  String get uiThisOutboundTripDoesNotMatchTheSelected;

  /// No description provided for @uiSelectAnOutboundTripFirstOrCheckThe.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn chuyến đi trước hoặc kiểm tra giờ khởi hành.'**
  String get uiSelectAnOutboundTripFirstOrCheckThe;

  /// No description provided for @uiTheReturnTripMustDepartAfterTheOutbound.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến về phải khởi hành sau khi chuyến đi đến nơi (kể cả chuyến qua đêm).'**
  String get uiTheReturnTripMustDepartAfterTheOutbound;

  /// No description provided for @uiOutbound4e8b02.
  ///
  /// In vi, this message translates to:
  /// **'đi'**
  String get uiOutbound4e8b02;

  /// No description provided for @uiReturn36c588.
  ///
  /// In vi, this message translates to:
  /// **'về'**
  String get uiReturn36c588;

  /// No description provided for @uiNoteRefreshingReloadsBothLegsAndResetsYour.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ý: Tải lại sẽ làm mới cả hai chặng và đặt lại lựa chọn.'**
  String get uiNoteRefreshingReloadsBothLegsAndResetsYour;

  /// No description provided for @uiOutboundeff5da.
  ///
  /// In vi, this message translates to:
  /// **'lượt đi'**
  String get uiOutboundeff5da;

  /// No description provided for @uiReturn8bcd7d.
  ///
  /// In vi, this message translates to:
  /// **'lượt về'**
  String get uiReturn8bcd7d;

  /// No description provided for @uiChangeTrip.
  ///
  /// In vi, this message translates to:
  /// **'Đổi chuyến'**
  String get uiChangeTrip;

  /// No description provided for @uiOutboundNotSelected.
  ///
  /// In vi, this message translates to:
  /// **'Đi: Chưa chọn'**
  String get uiOutboundNotSelected;

  /// No description provided for @uiReturnNotSelected.
  ///
  /// In vi, this message translates to:
  /// **'Về: Chưa chọn'**
  String get uiReturnNotSelected;

  /// No description provided for @uiPassengerDetailsAreKeptFromTheExistingBooking.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin hành khách được giữ theo đơn đã tạo. Bạn có thể đổi ghế và điểm đón/trả của chiều còn lại.'**
  String get uiPassengerDetailsAreKeptFromTheExistingBooking;

  /// No description provided for @uiPassengerDetailsApplyToBothOutboundAndReturn.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin hành khách sẽ được áp dụng chung cho cả Lượt đi và Lượt về.'**
  String get uiPassengerDetailsApplyToBothOutboundAndReturn;

  /// No description provided for @uiContactInformation.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin liên hệ'**
  String get uiContactInformation;

  /// No description provided for @uiTicketEmailOptional.
  ///
  /// In vi, this message translates to:
  /// **'Email nhận vé (tùy chọn)'**
  String get uiTicketEmailOptional;

  /// No description provided for @uiNotesForTheOperatorOptional.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú cho nhà xe (tùy chọn)'**
  String get uiNotesForTheOperatorOptional;

  /// No description provided for @uiEGPickUpAtTheJunctionCarrying.
  ///
  /// In vi, this message translates to:
  /// **'Đón tại ngã tư, có hành lý cồng kềnh...'**
  String get uiEGPickUpAtTheJunctionCarrying;

  /// No description provided for @uiConfirmDetails.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận thông tin'**
  String get uiConfirmDetails;

  /// No description provided for @uiDuplicateBookingCodes.
  ///
  /// In vi, this message translates to:
  /// **'Mã đơn bị trùng lặp'**
  String get uiDuplicateBookingCodes;

  /// No description provided for @uiTheTwoLegsHaveDuplicateBookingOrTransfer.
  ///
  /// In vi, this message translates to:
  /// **'Mã đơn hàng hoặc mã chuyển khoản giữa 2 chiều bị trùng. Để bảo vệ giao dịch, mã QR đã bị khóa. Vui lòng liên hệ tổng đài hỗ trợ.'**
  String get uiTheTwoLegsHaveDuplicateBookingOrTransfer;

  /// No description provided for @uiBookingStatusNeedsVerification.
  ///
  /// In vi, this message translates to:
  /// **'Cần xác minh trạng thái đơn'**
  String get uiBookingStatusNeedsVerification;

  /// No description provided for @uiNoBookingConfirmationWasReceivedDoNotCreate.
  ///
  /// In vi, this message translates to:
  /// **'Không nhận được phản hồi tạo đơn từ máy chủ. Vui lòng không tạo lại đơn mới để tránh trừ tiền 2 lần. Hãy kiểm tra mục Vé của tôi hoặc bấm \"Kiểm tra\" bên dưới.'**
  String get uiNoBookingConfirmationWasReceivedDoNotCreate;

  /// No description provided for @uiOneLegPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán 1 chiều'**
  String get uiOneLegPaid;

  /// No description provided for @uiPaymentForOneLegIsRecordedCheckBoth.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận thanh toán một chặng. Hãy kiểm tra lại cả hai đơn; không chuyển khoản thêm trong lúc chờ đối soát.'**
  String get uiPaymentForOneLegIsRecordedCheckBoth;

  /// No description provided for @uiPayForEachLegSeparately.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán riêng từng chiều'**
  String get uiPayForEachLegSeparately;

  /// No description provided for @uiPayForBothLegsTogether.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán chung hai chiều'**
  String get uiPayForBothLegsTogether;

  /// No description provided for @uiTransferTheExactAmountAndReferenceForEach.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển khoản đúng số tiền và nội dung riêng cho từng chặng.'**
  String get uiTransferTheExactAmountAndReferenceForEach;

  /// No description provided for @uiTransferOnlyAfterBothBookingsAndTheCombined.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chuyển khoản sau khi có đủ hai đơn và mã QR chung. Không chuyển thêm nếu giao dịch đang chờ xác minh.'**
  String get uiTransferOnlyAfterBothBookingsAndTheCombined;

  /// No description provided for @uiCheckBothBookings.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra lại cả hai đơn'**
  String get uiCheckBothBookings;

  /// No description provided for @uiCustomerSupport.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ khách hàng'**
  String get uiCustomerSupport;

  /// No description provided for @uiRoundTripPayment.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán vé khứ hồi'**
  String get uiRoundTripPayment;

  /// No description provided for @uiUnableToLoadTheQrImageUseThe.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được ảnh QR. Dùng thông tin chuyển khoản bên dưới.'**
  String get uiUnableToLoadTheQrImageUseThe;

  /// No description provided for @uiBank.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng'**
  String get uiBank;

  /// No description provided for @uiAccountNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số tài khoản'**
  String get uiAccountNumber;

  /// No description provided for @uiAccountHolder.
  ///
  /// In vi, this message translates to:
  /// **'Chủ tài khoản'**
  String get uiAccountHolder;

  /// No description provided for @uiReference.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung'**
  String get uiReference;

  /// No description provided for @uiReceivingAccountDetailsAreNotConfiguredContactSupport.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có cấu hình tài khoản nhận tiền. Vui lòng liên hệ hỗ trợ.'**
  String get uiReceivingAccountDetailsAreNotConfiguredContactSupport;

  /// No description provided for @uiCheckPaymentForBothLegs.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra thanh toán hai chiều'**
  String get uiCheckPaymentForBothLegs;

  /// No description provided for @uiPaida446a8.
  ///
  /// In vi, this message translates to:
  /// **'ĐÃ THANH TOÁN'**
  String get uiPaida446a8;

  /// No description provided for @uiExpired303872.
  ///
  /// In vi, this message translates to:
  /// **'HẾT HẠN'**
  String get uiExpired303872;

  /// No description provided for @uiAwaitingPayment.
  ///
  /// In vi, this message translates to:
  /// **'CHỜ THANH TOÁN'**
  String get uiAwaitingPayment;

  /// No description provided for @uiNotBooked.
  ///
  /// In vi, this message translates to:
  /// **'CHƯA TẠO ĐƠN'**
  String get uiNotBooked;

  /// No description provided for @uiBookingCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã đơn hàng'**
  String get uiBookingCode;

  /// No description provided for @uiLegTransactionCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã giao dịch chặng'**
  String get uiLegTransactionCode;

  /// No description provided for @uiTransferReference.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung CK'**
  String get uiTransferReference;

  /// No description provided for @uiAmountToTransfer.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền cần chuyển'**
  String get uiAmountToTransfer;

  /// No description provided for @uiEstimatedAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền dự kiến'**
  String get uiEstimatedAmount;

  /// No description provided for @uiETicketsIssuedSuccessfully.
  ///
  /// In vi, this message translates to:
  /// **'Đã xuất vé điện tử thành công.'**
  String get uiETicketsIssuedSuccessfully;

  /// No description provided for @uiPaymentReceivedTicketsAreBeingUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống đã nhận thanh toán, đang cập nhật vé.'**
  String get uiPaymentReceivedTicketsAreBeingUpdated;

  /// No description provided for @uiThePaymentDeadlineHasExpiredIfYouAlready.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng đã quá thời hạn thanh toán. Nếu bạn đã chuyển khoản, hãy bấm nút \"Kiểm tra thanh toán\" dưới đây.'**
  String get uiThePaymentDeadlineHasExpiredIfYouAlready;

  /// No description provided for @uiSyncTickets.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ lại vé'**
  String get uiSyncTickets;

  /// No description provided for @uiCheckPayment.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra thanh toán'**
  String get uiCheckPayment;

  /// No description provided for @uiRetryBookThisLeg.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại / Tạo đơn chiều này'**
  String get uiRetryBookThisLeg;

  /// No description provided for @uiReselectSeatsStopsForThisLeg.
  ///
  /// In vi, this message translates to:
  /// **'Chọn lại ghế / điểm đón trả chiều này'**
  String get uiReselectSeatsStopsForThisLeg;

  /// No description provided for @uiPaymentDeadlineExpiredbda98b.
  ///
  /// In vi, this message translates to:
  /// **'Đã hết hạn thanh toán'**
  String get uiPaymentDeadlineExpiredbda98b;

  /// No description provided for @uiCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép'**
  String get uiCopied;

  /// No description provided for @uiRoundTripBookingSuccessful.
  ///
  /// In vi, this message translates to:
  /// **'Đặt vé khứ hồi thành công!'**
  String get uiRoundTripBookingSuccessful;

  /// No description provided for @uiPaymentIsConfirmedAndETicketsAreIssued.
  ///
  /// In vi, this message translates to:
  /// **'Cả 2 chặng đã được xác nhận thanh toán và xuất vé điện tử.'**
  String get uiPaymentIsConfirmedAndETicketsAreIssued;

  /// No description provided for @uiVerifyingFares.
  ///
  /// In vi, this message translates to:
  /// **'Đang xác minh giá...'**
  String get uiVerifyingFares;

  /// No description provided for @uiLeadPassenger.
  ///
  /// In vi, this message translates to:
  /// **'Hành khách đại diện'**
  String get uiLeadPassenger;

  /// No description provided for @uiCostSummary.
  ///
  /// In vi, this message translates to:
  /// **'Tổng kết chi phí'**
  String get uiCostSummary;

  /// No description provided for @uiTotalPayment0a622e.
  ///
  /// In vi, this message translates to:
  /// **'Tổng tiền thanh toán'**
  String get uiTotalPayment0a622e;

  /// No description provided for @uiEstimatedItemFeesArePaidAtTheStation.
  ///
  /// In vi, this message translates to:
  /// **'Cước vật phẩm dự tính được thanh toán tại bến, không cộng vào tiền vé của hai chiều.'**
  String get uiEstimatedItemFeesArePaidAtTheStation;

  /// No description provided for @uiNoteTheTwoBookingsAreCreatedInSequence.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ý: Hai đơn hàng sẽ được tạo tuần tự và thanh toán riêng từng chiều.'**
  String get uiNoteTheTwoBookingsAreCreatedInSequence;

  /// No description provided for @uiOutboundb6646f.
  ///
  /// In vi, this message translates to:
  /// **'LƯỢT ĐI'**
  String get uiOutboundb6646f;

  /// No description provided for @uiReturnc7af78.
  ///
  /// In vi, this message translates to:
  /// **'LƯỢT VỀ'**
  String get uiReturnc7af78;

  /// No description provided for @uiChangeSeatsStops.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ghế / điểm đón trả'**
  String get uiChangeSeatsStops;

  /// No description provided for @uiRemoveVoucher.
  ///
  /// In vi, this message translates to:
  /// **'Gỡ voucher'**
  String get uiRemoveVoucher;

  /// No description provided for @uiLegFare.
  ///
  /// In vi, this message translates to:
  /// **'Giá vé chặng'**
  String get uiLegFare;

  /// No description provided for @uiSoldOut838424.
  ///
  /// In vi, this message translates to:
  /// **'Hết vé'**
  String get uiSoldOut838424;

  /// No description provided for @uiDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết'**
  String get uiDetails;

  /// No description provided for @uiSoldOutfec774.
  ///
  /// In vi, this message translates to:
  /// **'Hết chỗ'**
  String get uiSoldOutfec774;

  /// No description provided for @uiPickUpTimeAtStop.
  ///
  /// In vi, this message translates to:
  /// **'Giờ đón tại điểm'**
  String get uiPickUpTimeAtStop;

  /// No description provided for @uiDropOffTimeAtStop.
  ///
  /// In vi, this message translates to:
  /// **'Giờ trả tại điểm'**
  String get uiDropOffTimeAtStop;

  /// No description provided for @uiAccompanyingItemsWholeBooking.
  ///
  /// In vi, this message translates to:
  /// **'Vật phẩm đi kèm (toàn đơn)'**
  String get uiAccompanyingItemsWholeBooking;

  /// No description provided for @uiItems73b007.
  ///
  /// In vi, this message translates to:
  /// **'Vật phẩm'**
  String get uiItems73b007;

  /// No description provided for @uiPaymentReceipt.
  ///
  /// In vi, this message translates to:
  /// **'Chứng từ thanh toán'**
  String get uiPaymentReceipt;

  /// No description provided for @uiReceiptLookupIsAvailableOnlyWhenConnectedTo.
  ///
  /// In vi, this message translates to:
  /// **'Tra cứu chứng từ chỉ khả dụng khi kết nối hệ thống thật.'**
  String get uiReceiptLookupIsAvailableOnlyWhenConnectedTo;

  /// No description provided for @uiLookUpBookingReceipt.
  ///
  /// In vi, this message translates to:
  /// **'Tra cứu chứng từ đặt vé'**
  String get uiLookUpBookingReceipt;

  /// No description provided for @uiEnterTheTicketOrBookingCodeAndBooking.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã vé hoặc mã đặt vé và số điện thoại đặt vé. Đơn gắn tài khoản cần đăng nhập đúng tài khoản đã đặt.'**
  String get uiEnterTheTicketOrBookingCodeAndBooking;

  /// No description provided for @uiTicketOrBookingCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã vé hoặc mã đặt vé'**
  String get uiTicketOrBookingCode;

  /// No description provided for @uiEnterATicketOrBookingCode.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mã vé hoặc mã đặt vé.'**
  String get uiEnterATicketOrBookingCode;

  /// No description provided for @uiLookUpReceipt.
  ///
  /// In vi, this message translates to:
  /// **'Tra cứu chứng từ'**
  String get uiLookUpReceipt;

  /// No description provided for @uiYourSessionHasChangedCloseAndReopenReceipt.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đã thay đổi. Vui lòng đóng và mở lại tra cứu chứng từ.'**
  String get uiYourSessionHasChangedCloseAndReopenReceipt;

  /// No description provided for @uiRefreshReceipt.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật chứng từ'**
  String get uiRefreshReceipt;

  /// No description provided for @uiNotProvided05547c.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cung cấp'**
  String get uiNotProvided05547c;

  /// No description provided for @uiBookingCoded4f872.
  ///
  /// In vi, this message translates to:
  /// **'Mã đặt vé'**
  String get uiBookingCoded4f872;

  /// No description provided for @uiTransactionCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã giao dịch'**
  String get uiTransactionCode;

  /// No description provided for @uiBookingDateVietnamTime.
  ///
  /// In vi, this message translates to:
  /// **'Ngày đặt (giờ Việt Nam)'**
  String get uiBookingDateVietnamTime;

  /// No description provided for @uiPassengerbd8a66.
  ///
  /// In vi, this message translates to:
  /// **'Hành khách'**
  String get uiPassengerbd8a66;

  /// No description provided for @uiRoute.
  ///
  /// In vi, this message translates to:
  /// **'Tuyến'**
  String get uiRoute;

  /// No description provided for @uiVehicleType9fc822.
  ///
  /// In vi, this message translates to:
  /// **'Loại xe'**
  String get uiVehicleType9fc822;

  /// No description provided for @uiDepartureVietnamTime.
  ///
  /// In vi, this message translates to:
  /// **'Khởi hành (giờ Việt Nam)'**
  String get uiDepartureVietnamTime;

  /// No description provided for @uiUsed.
  ///
  /// In vi, this message translates to:
  /// **'Đã sử dụng'**
  String get uiUsed;

  /// No description provided for @uiTicketStatusUnverified.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác minh trạng thái vé'**
  String get uiTicketStatusUnverified;

  /// No description provided for @uiFareBeforeDiscounts.
  ///
  /// In vi, this message translates to:
  /// **'Tiền vé trước giảm'**
  String get uiFareBeforeDiscounts;

  /// No description provided for @uiPromoCode5683b7.
  ///
  /// In vi, this message translates to:
  /// **'Mã giảm giá'**
  String get uiPromoCode5683b7;

  /// No description provided for @uiDiscount.
  ///
  /// In vi, this message translates to:
  /// **'Giảm giá'**
  String get uiDiscount;

  /// No description provided for @uiFareAfterDiscounts4a0d51.
  ///
  /// In vi, this message translates to:
  /// **'Tiền vé sau giảm'**
  String get uiFareAfterDiscounts4a0d51;

  /// No description provided for @uiTotalPayment43f8d6.
  ///
  /// In vi, this message translates to:
  /// **'Tổng thanh toán'**
  String get uiTotalPayment43f8d6;

  /// No description provided for @uiPaymentMethodc216d3.
  ///
  /// In vi, this message translates to:
  /// **'Phương thức thanh toán'**
  String get uiPaymentMethodc216d3;

  /// No description provided for @uiThisIsABookingPaymentReceiptNotA.
  ///
  /// In vi, this message translates to:
  /// **'Đây là chứng từ đặt vé/thanh toán, không phải hóa đơn GTGT. Nếu cần hóa đơn GTGT, vui lòng liên hệ nhà xe. Chứng từ này không thay thế mã QR lên xe.'**
  String get uiThisIsABookingPaymentReceiptNotA;

  /// No description provided for @uiViewPaymentReceipt.
  ///
  /// In vi, this message translates to:
  /// **'Xem chứng từ thanh toán'**
  String get uiViewPaymentReceipt;

  /// No description provided for @uiCreatingYourShipmentPleaseWait.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý tạo đơn, vui lòng đợi trong giây lát...'**
  String get uiCreatingYourShipmentPleaseWait;

  /// No description provided for @uiUnverifiedShipmentWarning.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo đơn hàng chưa xác minh'**
  String get uiUnverifiedShipmentWarning;

  /// No description provided for @uiTheServerHasNotConfirmedThisShipmentLeave.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả tạo đơn chưa được máy chủ xác nhận. Bạn có chắc muốn rời khỏi màn hình này?'**
  String get uiTheServerHasNotConfirmedThisShipmentLeave;

  /// No description provided for @uiYourSessionHasChangedDataHasBeenRefreshed.
  ///
  /// In vi, this message translates to:
  /// **'Phiên làm việc đã thay đổi. Dữ liệu đã được làm mới.'**
  String get uiYourSessionHasChangedDataHasBeenRefreshed;

  /// No description provided for @uiCreateShipment.
  ///
  /// In vi, this message translates to:
  /// **'Tạo đơn'**
  String get uiCreateShipment;

  /// No description provided for @uiTrackShipment.
  ///
  /// In vi, this message translates to:
  /// **'Tra cứu'**
  String get uiTrackShipment;

  /// No description provided for @uiMyShipments.
  ///
  /// In vi, this message translates to:
  /// **'Đơn của tôi'**
  String get uiMyShipments;

  /// No description provided for @uiShipmentDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết vận đơn'**
  String get uiShipmentDetails;

  /// No description provided for @uiShipmentCreationResult.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả tạo đơn'**
  String get uiShipmentCreationResult;

  /// No description provided for @uiLookUpShipment.
  ///
  /// In vi, this message translates to:
  /// **'Tra cứu vận đơn'**
  String get uiLookUpShipment;

  /// No description provided for @uiShipmentCancelledContactTheOperatorForHelpRefunding.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy đơn. Vui lòng liên hệ nhà xe để được hỗ trợ hoàn tiền cước đã thanh toán.'**
  String get uiShipmentCancelledContactTheOperatorForHelpRefunding;

  /// No description provided for @uiShipmentCancelledIfYouAlreadyPaidContactThe.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã được hủy. Nếu đã thanh toán, vui lòng liên hệ nhà xe để được hỗ trợ.'**
  String get uiShipmentCancelledIfYouAlreadyPaidContactThe;

  /// No description provided for @uiCheckCancellationStatus.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra trạng thái hủy'**
  String get uiCheckCancellationStatus;

  /// No description provided for @uiCancelShipment.
  ///
  /// In vi, this message translates to:
  /// **'Hủy đơn gửi hàng'**
  String get uiCancelShipment;

  /// No description provided for @uiShippingNoLongerNeeded.
  ///
  /// In vi, this message translates to:
  /// **'Không còn nhu cầu gửi hàng'**
  String get uiShippingNoLongerNeeded;

  /// No description provided for @uiShipmentDetailsChanged.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin đơn đã thay đổi'**
  String get uiShipmentDetailsChanged;

  /// No description provided for @uiCancelThisShipment.
  ///
  /// In vi, this message translates to:
  /// **'Hủy đơn gửi hàng?'**
  String get uiCancelThisShipment;

  /// No description provided for @uiCancellationIsAvailableOnlyBeforeItemsAreAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ hủy khi hàng chưa được tiếp nhận. Nếu đã trả cước, bạn cần liên hệ nhà xe để được hỗ trợ hoàn tiền; không hoàn tiền trực tuyến.'**
  String get uiCancellationIsAvailableOnlyBeforeItemsAreAccepted;

  /// No description provided for @uiIncorrectShipmentDetails.
  ///
  /// In vi, this message translates to:
  /// **'Nhập sai thông tin đơn'**
  String get uiIncorrectShipmentDetails;

  /// No description provided for @uiOtherReasonOptional.
  ///
  /// In vi, this message translates to:
  /// **'Lý do khác (tùy chọn)'**
  String get uiOtherReasonOptional;

  /// No description provided for @uiKeepShipment.
  ///
  /// In vi, this message translates to:
  /// **'Giữ đơn'**
  String get uiKeepShipment;

  /// No description provided for @uiConfirmCancellation1939df.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận hủy'**
  String get uiConfirmCancellation1939df;

  /// No description provided for @uiUnableToLoadProvincesAndCities.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách tỉnh/thành phố.'**
  String get uiUnableToLoadProvincesAndCities;

  /// No description provided for @uiSelectAnOriginAndDestination.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn điểm đi và điểm đến.'**
  String get uiSelectAnOriginAndDestination;

  /// No description provided for @uiOriginAndDestinationMustBeDifferent.
  ///
  /// In vi, this message translates to:
  /// **'Điểm đi và điểm đến không được trùng nhau.'**
  String get uiOriginAndDestinationMustBeDifferent;

  /// No description provided for @uiSelectARouteAndOperatorBeforeCreatingA.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn tuyến và nhà xe trước khi tạo đơn.'**
  String get uiSelectARouteAndOperatorBeforeCreatingA;

  /// No description provided for @uiYourSessionHasChangedCloseAndReopenThis.
  ///
  /// In vi, this message translates to:
  /// **'Phiên làm việc đã thay đổi. Vui lòng đóng và mở lại tính năng.'**
  String get uiYourSessionHasChangedCloseAndReopenThis;

  /// No description provided for @uiLoadingProvincesAndCities.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải danh sách tỉnh/thành phố...'**
  String get uiLoadingProvincesAndCities;

  /// No description provided for @uiNoProvincesOrCitiesAreAvailableYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có danh sách tỉnh/thành phố khả dụng.'**
  String get uiNoProvincesOrCitiesAreAvailableYet;

  /// No description provided for @uiShippingDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày gửi'**
  String get uiShippingDate;

  /// No description provided for @uiFindShippingRoutes.
  ///
  /// In vi, this message translates to:
  /// **'Tìm tuyến gửi hàng'**
  String get uiFindShippingRoutes;

  /// No description provided for @uiNoEstimatedFeeAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có cước tham khảo'**
  String get uiNoEstimatedFeeAvailable;

  /// No description provided for @uiLoadingThisRouteSShippingOptions.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải cấu hình nhận hàng của tuyến...'**
  String get uiLoadingThisRouteSShippingOptions;

  /// No description provided for @ui2DropOffAndCollectionPoints.
  ///
  /// In vi, this message translates to:
  /// **'2. Điểm gửi và điểm nhận hàng'**
  String get ui2DropOffAndCollectionPoints;

  /// No description provided for @uiNoteShippingDropOffCollectionPointsMayDiffer.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ý: Điểm giao nhận hàng độc lập có thể khác điểm đón trả khách.'**
  String get uiNoteShippingDropOffCollectionPointsMayDiffer;

  /// No description provided for @uiSelectDropOffPoint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điểm gửi hàng *'**
  String get uiSelectDropOffPoint;

  /// No description provided for @uiSelectDropOffOfficeStation.
  ///
  /// In vi, this message translates to:
  /// **'Chọn văn phòng/bến gửi hàng'**
  String get uiSelectDropOffOfficeStation;

  /// No description provided for @uiSelectCollectionPoint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điểm nhận hàng *'**
  String get uiSelectCollectionPoint;

  /// No description provided for @uiSelectCollectionOfficeStation.
  ///
  /// In vi, this message translates to:
  /// **'Chọn văn phòng/bến nhận hàng'**
  String get uiSelectCollectionOfficeStation;

  /// No description provided for @ui3SenderRecipientDetails.
  ///
  /// In vi, this message translates to:
  /// **'3. Thông tin người gửi & người nhận'**
  String get ui3SenderRecipientDetails;

  /// No description provided for @uiSender.
  ///
  /// In vi, this message translates to:
  /// **'NGƯỜI GỬI'**
  String get uiSender;

  /// No description provided for @uiSenderSFullName.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên người gửi *'**
  String get uiSenderSFullName;

  /// No description provided for @uiEnterFullName.
  ///
  /// In vi, this message translates to:
  /// **'Nhập đầy đủ họ tên'**
  String get uiEnterFullName;

  /// No description provided for @uiSenderSPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại người gửi *'**
  String get uiSenderSPhoneNumber;

  /// No description provided for @uiSenderSEmailOptional.
  ///
  /// In vi, this message translates to:
  /// **'Email người gửi (tùy chọn)'**
  String get uiSenderSEmailOptional;

  /// No description provided for @uiRecipient.
  ///
  /// In vi, this message translates to:
  /// **'NGƯỜI NHẬN'**
  String get uiRecipient;

  /// No description provided for @uiRecipientSFullName.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên người nhận *'**
  String get uiRecipientSFullName;

  /// No description provided for @uiEnterRecipientSFullName.
  ///
  /// In vi, this message translates to:
  /// **'Nhập đầy đủ họ tên người nhận'**
  String get uiEnterRecipientSFullName;

  /// No description provided for @uiRecipientSPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại người nhận *'**
  String get uiRecipientSPhoneNumber;

  /// No description provided for @uiRecipientSNationalIdOptional12Digits.
  ///
  /// In vi, this message translates to:
  /// **'CCCD người nhận (tùy chọn - 12 số)'**
  String get uiRecipientSNationalIdOptional12Digits;

  /// No description provided for @uiEnter12DigitsIfAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Nhập 12 chữ số nếu có'**
  String get uiEnter12DigitsIfAvailable;

  /// No description provided for @ui4Items.
  ///
  /// In vi, this message translates to:
  /// **'4. Danh sách kiện hàng'**
  String get ui4Items;

  /// No description provided for @uiAddItem2d1b7b.
  ///
  /// In vi, this message translates to:
  /// **'Thêm kiện'**
  String get uiAddItem2d1b7b;

  /// No description provided for @ui5PayerPaymentMethod.
  ///
  /// In vi, this message translates to:
  /// **'5. Người thanh toán & Phương thức'**
  String get ui5PayerPaymentMethod;

  /// No description provided for @uiSenderPaysAtStation.
  ///
  /// In vi, this message translates to:
  /// **'Người gửi trả tại bến'**
  String get uiSenderPaysAtStation;

  /// No description provided for @uiPayCashWhenDroppingOffItems.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán tiền mặt khi gửi hàng'**
  String get uiPayCashWhenDroppingOffItems;

  /// No description provided for @uiRecipientPaysAtStation.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận trả tại bến'**
  String get uiRecipientPaysAtStation;

  /// No description provided for @uiPayCashWhenCollectingItems.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán tiền mặt khi nhận hàng'**
  String get uiPayCashWhenCollectingItems;

  /// No description provided for @ui6GeneralNotesOptional.
  ///
  /// In vi, this message translates to:
  /// **'6. Ghi chú chung (tùy chọn)'**
  String get ui6GeneralNotesOptional;

  /// No description provided for @uiEnterNotesOrHandoverInstructionsForTheOperator.
  ///
  /// In vi, this message translates to:
  /// **'Nhập ghi chú hoặc yêu cầu bàn giao cho nhà xe...'**
  String get uiEnterNotesOrHandoverInstructionsForTheOperator;

  /// No description provided for @uiCalculatingEstimatedFee.
  ///
  /// In vi, this message translates to:
  /// **'Đang tính cước tạm tính...'**
  String get uiCalculatingEstimatedFee;

  /// No description provided for @uiEstimatedFeef58e86.
  ///
  /// In vi, this message translates to:
  /// **'CƯỚC DỰ TÍNH'**
  String get uiEstimatedFeef58e86;

  /// No description provided for @uiGetEstimate.
  ///
  /// In vi, this message translates to:
  /// **'Báo cước'**
  String get uiGetEstimate;

  /// No description provided for @uiCreateShipment905793.
  ///
  /// In vi, this message translates to:
  /// **'Tạo đơn gửi hàng'**
  String get uiCreateShipment905793;

  /// No description provided for @uiItemName237ded.
  ///
  /// In vi, this message translates to:
  /// **'Tên hàng hóa *'**
  String get uiItemName237ded;

  /// No description provided for @uiEGBoxOfFruitDocuments.
  ///
  /// In vi, this message translates to:
  /// **'VD: Thùng trái cây, Tài liệu...'**
  String get uiEGBoxOfFruitDocuments;

  /// No description provided for @uiItemType.
  ///
  /// In vi, this message translates to:
  /// **'Loại hàng hóa *'**
  String get uiItemType;

  /// No description provided for @uiSelectItemType.
  ///
  /// In vi, this message translates to:
  /// **'Chọn loại hàng'**
  String get uiSelectItemType;

  /// No description provided for @uiWeightKgItem.
  ///
  /// In vi, this message translates to:
  /// **'Khối lượng (kg/kiện) *'**
  String get uiWeightKgItem;

  /// No description provided for @uiDimensionsCmOptionalLengthXWidthXHeight.
  ///
  /// In vi, this message translates to:
  /// **'Kích thước (cm - tùy chọn: Dài x Rộng x Cao)'**
  String get uiDimensionsCmOptionalLengthXWidthXHeight;

  /// No description provided for @uiLength.
  ///
  /// In vi, this message translates to:
  /// **'Dài'**
  String get uiLength;

  /// No description provided for @uiWidth.
  ///
  /// In vi, this message translates to:
  /// **'Rộng'**
  String get uiWidth;

  /// No description provided for @uiServiceType.
  ///
  /// In vi, this message translates to:
  /// **'Loại dịch vụ'**
  String get uiServiceType;

  /// No description provided for @uiStandardNormal.
  ///
  /// In vi, this message translates to:
  /// **'Tiêu chuẩn (NORMAL)'**
  String get uiStandardNormal;

  /// No description provided for @uiFragileFragile.
  ///
  /// In vi, this message translates to:
  /// **'Dễ vỡ (FRAGILE)'**
  String get uiFragileFragile;

  /// No description provided for @uiHighValueValuable.
  ///
  /// In vi, this message translates to:
  /// **'Giá trị cao (VALUABLE)'**
  String get uiHighValueValuable;

  /// No description provided for @uiEGLightItemsKeepDry.
  ///
  /// In vi, this message translates to:
  /// **'VD: Hàng nhẹ, cần che mưa...'**
  String get uiEGLightItemsKeepDry;

  /// No description provided for @uiSelectProvinceCity.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tỉnh/thành phố'**
  String get uiSelectProvinceCity;

  /// No description provided for @uiShipmentDetailsNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy chi tiết vận đơn.'**
  String get uiShipmentDetailsNotFound;

  /// No description provided for @uiCreateNewShipment.
  ///
  /// In vi, this message translates to:
  /// **'Tạo đơn mới'**
  String get uiCreateNewShipment;

  /// No description provided for @uiShipmentCode9dec85.
  ///
  /// In vi, this message translates to:
  /// **'MÃ VẬN ĐƠN'**
  String get uiShipmentCode9dec85;

  /// No description provided for @uiCopyShipmentCode.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép mã vận đơn'**
  String get uiCopyShipmentCode;

  /// No description provided for @uiShipmentCode09837d.
  ///
  /// In vi, this message translates to:
  /// **'mã vận đơn'**
  String get uiShipmentCode09837d;

  /// No description provided for @uiBookingCoded6f725.
  ///
  /// In vi, this message translates to:
  /// **'Mã đơn hàng: '**
  String get uiBookingCoded6f725;

  /// No description provided for @uiCopyBookingCodeffae60.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép mã đơn'**
  String get uiCopyBookingCodeffae60;

  /// No description provided for @uiBookingCodeee647d.
  ///
  /// In vi, this message translates to:
  /// **'mã đơn hàng'**
  String get uiBookingCodeee647d;

  /// No description provided for @uiDropOffDeadline.
  ///
  /// In vi, this message translates to:
  /// **'Hạn mang hàng ra bến:'**
  String get uiDropOffDeadline;

  /// No description provided for @uiNoTripAssigned.
  ///
  /// In vi, this message translates to:
  /// **'Chưa phân chuyến'**
  String get uiNoTripAssigned;

  /// No description provided for @uiDropOffPoint.
  ///
  /// In vi, this message translates to:
  /// **'Điểm gửi hàng'**
  String get uiDropOffPoint;

  /// No description provided for @uiCollectionPoint.
  ///
  /// In vi, this message translates to:
  /// **'Điểm nhận hàng'**
  String get uiCollectionPoint;

  /// No description provided for @uiDeliveryInformation.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin giao nhận'**
  String get uiDeliveryInformation;

  /// No description provided for @uiSenderfeefc2.
  ///
  /// In vi, this message translates to:
  /// **'Người gửi:'**
  String get uiSenderfeefc2;

  /// No description provided for @uiRecipient2a6b0f.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận:'**
  String get uiRecipient2a6b0f;

  /// No description provided for @uiEstimatedFee321adb.
  ///
  /// In vi, this message translates to:
  /// **'Cước dự tính'**
  String get uiEstimatedFee321adb;

  /// No description provided for @uiConfirmedFee.
  ///
  /// In vi, this message translates to:
  /// **'Cước phí xác nhận'**
  String get uiConfirmedFee;

  /// No description provided for @uiTheFinalFeeWillBeConfirmedAfterWeighing.
  ///
  /// In vi, this message translates to:
  /// **'Cước phí thực tế sẽ được cân đo và xác nhận tại bến.'**
  String get uiTheFinalFeeWillBeConfirmedAfterWeighing;

  /// No description provided for @uiBaseFee.
  ///
  /// In vi, this message translates to:
  /// **'Cước cơ bản'**
  String get uiBaseFee;

  /// No description provided for @uiServiceSurcharge.
  ///
  /// In vi, this message translates to:
  /// **'Phụ phí dịch vụ'**
  String get uiServiceSurcharge;

  /// No description provided for @uiTotalShippingFee.
  ///
  /// In vi, this message translates to:
  /// **'Tổng cước'**
  String get uiTotalShippingFee;

  /// No description provided for @uiAmountOutstanding.
  ///
  /// In vi, this message translates to:
  /// **'Còn phải thanh toán'**
  String get uiAmountOutstanding;

  /// No description provided for @uiThisShipmentIsCancelledDoNotBringItems.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã hủy; không cần mang hàng ra bến cho đơn này.'**
  String get uiThisShipmentIsCancelledDoNotBringItems;

  /// No description provided for @uiPayAtTheStation.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán tại bến xe'**
  String get uiPayAtTheStation;

  /// No description provided for @uiSender53bc00.
  ///
  /// In vi, this message translates to:
  /// **'Người gửi'**
  String get uiSender53bc00;

  /// No description provided for @uiRecipient449171.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận'**
  String get uiRecipient449171;

  /// No description provided for @uiPaymentConfirmedSuccessfully.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác nhận thanh toán thành công!'**
  String get uiPaymentConfirmedSuccessfully;

  /// No description provided for @uiPaymentReconciliationInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch đang đối soát'**
  String get uiPaymentReconciliationInProgress;

  /// No description provided for @uiThisShipmentPreviouslyUsedOnlinePaymentContactThe.
  ///
  /// In vi, this message translates to:
  /// **'Đơn thanh toán trực tuyến trước đây. Liên hệ nhà xe để kiểm tra trạng thái, không chuyển thêm tiền.'**
  String get uiThisShipmentPreviouslyUsedOnlinePaymentContactThe;

  /// No description provided for @uiCreateAnotherShipment.
  ///
  /// In vi, this message translates to:
  /// **'Tạo đơn gửi hàng khác'**
  String get uiCreateAnotherShipment;

  /// No description provided for @uiViewShipments.
  ///
  /// In vi, this message translates to:
  /// **'Xem danh sách đơn gửi hàng'**
  String get uiViewShipments;

  /// No description provided for @uiEnterTheShipmentCodeAndPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mã vận đơn và số điện thoại.'**
  String get uiEnterTheShipmentCodeAndPhoneNumber;

  /// No description provided for @uiTrackShipmentStatus.
  ///
  /// In vi, this message translates to:
  /// **'Tra cứu trạng thái vận đơn'**
  String get uiTrackShipmentStatus;

  /// No description provided for @uiEnterTheShipmentCodeAndSenderSRecipient.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã vận đơn và số điện thoại người gửi/nhận để theo dõi hành trình kiện hàng.'**
  String get uiEnterTheShipmentCodeAndSenderSRecipient;

  /// No description provided for @uiShipmentCode1eaa4b.
  ///
  /// In vi, this message translates to:
  /// **'Mã vận đơn'**
  String get uiShipmentCode1eaa4b;

  /// No description provided for @uiSenderSOrRecipientSPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại người gửi hoặc người nhận'**
  String get uiSenderSOrRecipientSPhoneNumber;

  /// No description provided for @uiCopyCode.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép mã'**
  String get uiCopyCode;

  /// No description provided for @uiPaymentStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái thanh toán: '**
  String get uiPaymentStatus;

  /// No description provided for @uiDropOffa17ae9.
  ///
  /// In vi, this message translates to:
  /// **'Điểm gửi:'**
  String get uiDropOffa17ae9;

  /// No description provided for @uiCollection.
  ///
  /// In vi, this message translates to:
  /// **'Điểm nhận:'**
  String get uiCollection;

  /// No description provided for @uiShippingTimeline.
  ///
  /// In vi, this message translates to:
  /// **'Lịch trình vận chuyển'**
  String get uiShippingTimeline;

  /// No description provided for @uiSearchByShipmentCode.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm theo mã vận đơn...'**
  String get uiSearchByShipmentCode;

  /// No description provided for @uiCreated.
  ///
  /// In vi, this message translates to:
  /// **'Mới tạo'**
  String get uiCreated;

  /// No description provided for @uiAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Đã tiếp nhận'**
  String get uiAccepted;

  /// No description provided for @uiInTransit.
  ///
  /// In vi, this message translates to:
  /// **'Đang vận chuyển'**
  String get uiInTransit;

  /// No description provided for @uiDelivered.
  ///
  /// In vi, this message translates to:
  /// **'Đã giao'**
  String get uiDelivered;

  /// No description provided for @uiNoShipmentsYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có đơn gửi hàng nào'**
  String get uiNoShipmentsYet;

  /// No description provided for @uiYouHaveNoShipmentsYetOrNoneMatch.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa tạo đơn gửi hàng nào hoặc không có đơn phù hợp bộ lọc.'**
  String get uiYouHaveNoShipmentsYetOrNoneMatch;

  /// No description provided for @uiPreviousPage.
  ///
  /// In vi, this message translates to:
  /// **'Trang trước'**
  String get uiPreviousPage;

  /// No description provided for @uiTheDisplayedFeeIsAnEstimateTheExact.
  ///
  /// In vi, this message translates to:
  /// **'Cước hiển thị chỉ để tham khảo. Cước phí chính xác do máy chủ xác nhận khi tạo đơn.'**
  String get uiTheDisplayedFeeIsAnEstimateTheExact;

  /// No description provided for @uiUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác định'**
  String get uiUnknown;

  /// No description provided for @uiReconciling.
  ///
  /// In vi, this message translates to:
  /// **'Đang đối soát'**
  String get uiReconciling;

  /// No description provided for @uiAwaitingPaymentac4098.
  ///
  /// In vi, this message translates to:
  /// **'Chờ thanh toán'**
  String get uiAwaitingPaymentac4098;

  /// No description provided for @uiPayAtStation.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán tại bến'**
  String get uiPayAtStation;

  /// No description provided for @uiShipmentResultNotYetVerified.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể xác minh kết quả tạo đơn'**
  String get uiShipmentResultNotYetVerified;

  /// No description provided for @uiANetworkIssueOccurredOrTheResponseIs.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống gặp sự cố mạng hoặc phản hồi chưa được xác nhận. Vui lòng không tạo lại đơn ngay lập tức để tránh phát sinh đơn trùng lặp.'**
  String get uiANetworkIssueOccurredOrTheResponseIs;

  /// No description provided for @uiProvisionalShipmentDetails.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin vận đơn ghi nhận tạm thời:'**
  String get uiProvisionalShipmentDetails;

  /// No description provided for @uiShipmentCode9f610f.
  ///
  /// In vi, this message translates to:
  /// **'Mã vận đơn: '**
  String get uiShipmentCode9f610f;

  /// No description provided for @uiShipmentCodeCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã vận đơn'**
  String get uiShipmentCodeCopied;

  /// No description provided for @uiCheckExistingShipment.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra đơn đã tạo'**
  String get uiCheckExistingShipment;

  /// No description provided for @uiLookUpThisShipment.
  ///
  /// In vi, this message translates to:
  /// **'Tra cứu vận đơn này'**
  String get uiLookUpThisShipment;

  /// No description provided for @uiCheckShipmentCreationResult.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra lại kết quả tạo đơn'**
  String get uiCheckShipmentCreationResult;

  /// No description provided for @uiResubmitTheSameDetailsAndTransactionCodeTo.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại cùng thông tin và mã giao dịch để kiểm tra đơn đã tạo trên máy chủ.'**
  String get uiResubmitTheSameDetailsAndTransactionCodeTo;

  /// No description provided for @uiForUrgentHelpContactVexgoSupportOrTake.
  ///
  /// In vi, this message translates to:
  /// **'Nếu cần hỗ trợ khẩn cấp, vui lòng liên hệ tổng đài VexGo hoặc chụp lại màn hình này.'**
  String get uiForUrgentHelpContactVexgoSupportOrTake;

  /// No description provided for @uiUnableToLoadTripDetailsFromTheServer.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được thông tin chuyến xe từ máy chủ. Vui lòng thử lại sau.'**
  String get uiUnableToLoadTripDetailsFromTheServer;

  /// No description provided for @uiThisTripIsNoLongerAvailableOrLive.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến xe không còn khả dụng hoặc chưa tải được dữ liệu thực tế.'**
  String get uiThisTripIsNoLongerAvailableOrLive;

  /// No description provided for @uiTheServerDidNotProvideAValidDeparture.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến xe không có thông tin ngày khởi hành hợp lệ từ máy chủ.'**
  String get uiTheServerDidNotProvideAValidDeparture;

  /// No description provided for @uiViewSavedResponses.
  ///
  /// In vi, this message translates to:
  /// **'Xem phản hồi đã lưu'**
  String get uiViewSavedResponses;

  /// No description provided for @uiNewConversation.
  ///
  /// In vi, this message translates to:
  /// **'Hội thoại mới'**
  String get uiNewConversation;

  /// No description provided for @uiChatWithSupport.
  ///
  /// In vi, this message translates to:
  /// **'Chat với nhân viên'**
  String get uiChatWithSupport;

  /// No description provided for @uiClearOperatorFilter.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ lọc nhà xe'**
  String get uiClearOperatorFilter;

  /// No description provided for @uiStartANewConversation.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu hội thoại mới?'**
  String get uiStartANewConversation;

  /// No description provided for @uiThisStartsANewConversationInTheApp.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác này mở một phiên trò chuyện mới trên ứng dụng và không xóa các yêu cầu đã gửi lên máy chủ trước đó.'**
  String get uiThisStartsANewConversationInTheApp;

  /// No description provided for @uiStartNewSession.
  ///
  /// In vi, this message translates to:
  /// **'Tạo phiên mới'**
  String get uiStartNewSession;

  /// No description provided for @uiStartNewKeepDraft.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mới & Giữ nháp'**
  String get uiStartNewKeepDraft;

  /// No description provided for @uiQuestionForTheAiAssistant.
  ///
  /// In vi, this message translates to:
  /// **'Câu hỏi cho Trợ lý AI'**
  String get uiQuestionForTheAiAssistant;

  /// No description provided for @uiAskAboutPoliciesBusTrips.
  ///
  /// In vi, this message translates to:
  /// **'Nhập câu hỏi về chính sách, chuyến xe…'**
  String get uiAskAboutPoliciesBusTrips;

  /// No description provided for @uiSendQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Gửi câu hỏi'**
  String get uiSendQuestion;

  /// No description provided for @uiTicketPoliciesLuggageAndTripSuggestions.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi đáp chính sách vé, hành lý và gợi ý chuyến xe'**
  String get uiTicketPoliciesLuggageAndTripSuggestions;

  /// No description provided for @uiYou.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get uiYou;

  /// No description provided for @uiInternalPolicyDocumentNotAWebLink.
  ///
  /// In vi, this message translates to:
  /// **'Tài liệu quy định nội bộ (không phải đường dẫn web):'**
  String get uiInternalPolicyDocumentNotAWebLink;

  /// No description provided for @uiFaresAndAvailableSeatsBelowAreSuggestionsLive.
  ///
  /// In vi, this message translates to:
  /// **'Giá và số chỗ trống dưới đây là thông tin gợi ý; hệ thống sẽ tải lại chuyến xe từ máy chủ khi bạn chọn.'**
  String get uiFaresAndAvailableSeatsBelowAreSuggestionsLive;

  /// No description provided for @uiPriceUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giá'**
  String get uiPriceUnavailable;

  /// No description provided for @uiCheckingTrip.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra chuyến…'**
  String get uiCheckingTrip;

  /// No description provided for @uiViewSelectTrip.
  ///
  /// In vi, this message translates to:
  /// **'Xem & chọn chuyến'**
  String get uiViewSelectTrip;

  /// No description provided for @uiConsiderSpeakingToSupport.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý trao đổi trực tiếp với nhân viên hỗ trợ'**
  String get uiConsiderSpeakingToSupport;

  /// No description provided for @uiThisIsASuggestionOnlyYouHaveNot.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống chỉ gợi ý chuyển tiếp và chưa tự động kết nối hay gửi nội dung cho nhân viên khi bạn chưa bấm nút bên dưới.'**
  String get uiThisIsASuggestionOnlyYouHaveNot;

  /// No description provided for @uiSuggestedFollowUpQuestions.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý hỏi tiếp:'**
  String get uiSuggestedFollowUpQuestions;

  /// No description provided for @uiYouSending.
  ///
  /// In vi, this message translates to:
  /// **'Bạn • Đang gửi…'**
  String get uiYouSending;

  /// No description provided for @uiTheAiAssistantIsReplying.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý AI đang trả lời…'**
  String get uiTheAiAssistantIsReplying;

  /// No description provided for @uiItIsUnclearWhetherYourQuestionWasProcessed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác định được câu hỏi đã xử lý hay chưa. Giữ lại bản nháp; không gửi lại tự động.'**
  String get uiItIsUnclearWhetherYourQuestionWasProcessed;

  /// No description provided for @uiYouCanCheckSavedResponsesForThisSession.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể kiểm tra các phản hồi đã lưu của phiên hiện tại trước, hoặc chủ động bắt đầu hội thoại mới. Lưu ý: câu hỏi vừa gửi có thể đã được máy chủ tiếp nhận.'**
  String get uiYouCanCheckSavedResponsesForThisSession;

  /// No description provided for @uiTheFirstResponseWasInterruptedBeforeASession.
  ///
  /// In vi, this message translates to:
  /// **'Do phản hồi đầu tiên bị gián đoạn trước khi nhận mã phiên nên chưa thể đối chiếu lịch sử trên máy chủ. Bạn có thể bắt đầu hội thoại mới và giữ lại câu hỏi nháp.'**
  String get uiTheFirstResponseWasInterruptedBeforeASession;

  /// No description provided for @uiCheckSavedResponses.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra phản hồi đã lưu'**
  String get uiCheckSavedResponses;

  /// No description provided for @uiNewConversationKeepDraft.
  ///
  /// In vi, this message translates to:
  /// **'Hội thoại mới (Giữ nháp)'**
  String get uiNewConversationKeepDraft;

  /// No description provided for @uiNewConversationClearDraft.
  ///
  /// In vi, this message translates to:
  /// **'Hội thoại mới (Xóa nháp)'**
  String get uiNewConversationClearDraft;

  /// No description provided for @uiServerResponseRecordReadOnly.
  ///
  /// In vi, this message translates to:
  /// **'Bản ghi phản hồi từ máy chủ (Chỉ đọc)'**
  String get uiServerResponseRecordReadOnly;

  /// No description provided for @uiRefreshSavedResponses.
  ///
  /// In vi, this message translates to:
  /// **'Tải lại phản hồi đã lưu'**
  String get uiRefreshSavedResponses;

  /// No description provided for @uiReadOnlyServerRecordOfThisSessionS.
  ///
  /// In vi, this message translates to:
  /// **'Bản ghi chỉ đọc từ máy chủ (hiển thị các tin nhắn đã lưu của phiên này); không tự thay thế hội thoại trên máy hoặc tự mở khóa câu hỏi đang gián đoạn.'**
  String get uiReadOnlyServerRecordOfThisSessionS;

  /// No description provided for @uiLoadingResponseHistory.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải lịch sử phản hồi…'**
  String get uiLoadingResponseHistory;

  /// No description provided for @uiNoResponsesAreSavedInThisSessionYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có phản hồi nào được lưu trong phiên này.'**
  String get uiNoResponsesAreSavedInThisSessionYet;

  /// No description provided for @uiUser.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get uiUser;

  /// No description provided for @uiPolicies.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách'**
  String get uiPolicies;

  /// No description provided for @uiLuggage.
  ///
  /// In vi, this message translates to:
  /// **'Hành lý'**
  String get uiLuggage;

  /// No description provided for @uiBusTrips.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến xe'**
  String get uiBusTrips;

  /// No description provided for @uiCancellationRefunds.
  ///
  /// In vi, this message translates to:
  /// **'Hủy & hoàn tiền'**
  String get uiCancellationRefunds;

  /// No description provided for @uiSuggestions.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý'**
  String get uiSuggestions;

  /// No description provided for @uiFrequentlyAskedQuestions.
  ///
  /// In vi, this message translates to:
  /// **'Câu hỏi thường gặp'**
  String get uiFrequentlyAskedQuestions;

  /// No description provided for @uiLoadingSuggestedQuestions.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải câu hỏi gợi ý…'**
  String get uiLoadingSuggestedQuestions;

  /// No description provided for @uiNoSuggestedQuestionsAreAvailableYetEnterYour.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có câu hỏi gợi ý sẵn. Bạn có thể nhập trực tiếp câu hỏi bên dưới.'**
  String get uiNoSuggestedQuestionsAreAvailableYetEnterYour;

  /// No description provided for @uiRefreshSuggestedQuestions.
  ///
  /// In vi, this message translates to:
  /// **'Tải lại câu hỏi gợi ý'**
  String get uiRefreshSuggestedQuestions;

  /// No description provided for @uiHelloIMTheVexgoAiAssistant.
  ///
  /// In vi, this message translates to:
  /// **'Xin chào! Tôi là Trợ lý AI VexGo'**
  String get uiHelloIMTheVexgoAiAssistant;

  /// No description provided for @uiICanHelpWithTicketPoliciesAccompaniedLuggage.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ giải đáp chính sách vé, hành lý đi kèm, gợi ý chuyến xe và hướng dẫn quy trình đặt vé.'**
  String get uiICanHelpWithTicketPoliciesAccompaniedLuggage;

  /// No description provided for @uiTheAiAssistantProvidesInformationOnlyItDoes.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý AI chỉ cung cấp thông tin tham khảo và không tự động đặt vé, thanh toán, hủy vé hay thay đổi vận đơn.'**
  String get uiTheAiAssistantProvidesInformationOnlyItDoes;

  /// No description provided for @uiInsertQuestionIntoTheMessageField.
  ///
  /// In vi, this message translates to:
  /// **'Chèn câu hỏi vào ô nhập'**
  String get uiInsertQuestionIntoTheMessageField;

  /// No description provided for @uiChatRequiresAnOnlineServerConnection.
  ///
  /// In vi, this message translates to:
  /// **'Chat cần kết nối máy chủ ở chế độ trực tuyến.'**
  String get uiChatRequiresAnOnlineServerConnection;

  /// No description provided for @uiSignInToChatWithTheOperator.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để trò chuyện với nhà xe.'**
  String get uiSignInToChatWithTheOperator;

  /// No description provided for @uiSelectOperator.
  ///
  /// In vi, this message translates to:
  /// **'Chọn nhà xe'**
  String get uiSelectOperator;

  /// No description provided for @uiEndConversation.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc hội thoại'**
  String get uiEndConversation;

  /// No description provided for @uiReconnectingLiveChatYouCanStillSendAnd.
  ///
  /// In vi, this message translates to:
  /// **'Realtime đang kết nối lại. Bạn vẫn có thể gửi và tải lại tin nhắn.'**
  String get uiReconnectingLiveChatYouCanStillSendAnd;

  /// No description provided for @uiSupportIsTyping.
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên đang nhập…'**
  String get uiSupportIsTyping;

  /// No description provided for @uiThisConversationHasEndedOrMessagesCannotBe.
  ///
  /// In vi, this message translates to:
  /// **'Hội thoại đã kết thúc hoặc chưa thể gửi tin. Mở hội thoại mới để được hỗ trợ.'**
  String get uiThisConversationHasEndedOrMessagesCannotBe;

  /// No description provided for @uiEndThisConversationYouCanStartANew.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc hội thoại này? Bạn có thể mở hội thoại mới sau đó.'**
  String get uiEndThisConversationYouCanStartANew;

  /// No description provided for @uiKeepConversation.
  ///
  /// In vi, this message translates to:
  /// **'Giữ hội thoại'**
  String get uiKeepConversation;

  /// No description provided for @uiEnd.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc'**
  String get uiEnd;

  /// No description provided for @uiUnableToLoadOperatorsTryAgain.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được nhà xe. Thử lại'**
  String get uiUnableToLoadOperatorsTryAgain;

  /// No description provided for @uiNoOperatorsAreAvailableToContactYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nhà xe để liên hệ.'**
  String get uiNoOperatorsAreAvailableToContactYet;

  /// No description provided for @uiOpenOrContinueConversation.
  ///
  /// In vi, this message translates to:
  /// **'Mở hoặc tiếp tục hội thoại'**
  String get uiOpenOrContinueConversation;

  /// No description provided for @uiYouHaveNoConversationsYetSelectNewConversation.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có hội thoại nào. Chọn “Hội thoại mới” để liên hệ nhà xe.'**
  String get uiYouHaveNoConversationsYetSelectNewConversation;

  /// No description provided for @uiLoadMoreConversations.
  ///
  /// In vi, this message translates to:
  /// **'Tải thêm hội thoại'**
  String get uiLoadMoreConversations;

  /// No description provided for @uiLoadEarlierMessages.
  ///
  /// In vi, this message translates to:
  /// **'Tải tin nhắn trước'**
  String get uiLoadEarlierMessages;

  /// No description provided for @uiNoMessagesYetSayHelloToStart.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tin nhắn. Gửi lời chào để bắt đầu.'**
  String get uiNoMessagesYetSayHelloToStart;

  /// No description provided for @uiStartConversation.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu hội thoại'**
  String get uiStartConversation;

  /// No description provided for @uiMessageTheOperator.
  ///
  /// In vi, this message translates to:
  /// **'Nhắn tin cho nhà xe…'**
  String get uiMessageTheOperator;

  /// No description provided for @uiSendMessage.
  ///
  /// In vi, this message translates to:
  /// **'Gửi tin nhắn'**
  String get uiSendMessage;

  /// No description provided for @uiSending.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi…'**
  String get uiSending;

  /// No description provided for @uiSendingNotConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác nhận gửi'**
  String get uiSendingNotConfirmed;

  /// No description provided for @uiRead.
  ///
  /// In vi, this message translates to:
  /// **'Đã đọc'**
  String get uiRead;

  /// No description provided for @uiSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi'**
  String get uiSent;

  /// No description provided for @uiSupportAgent.
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên hỗ trợ'**
  String get uiSupportAgent;

  /// No description provided for @uiTrySendingAgain.
  ///
  /// In vi, this message translates to:
  /// **'Thử gửi lại'**
  String get uiTrySendingAgain;

  /// No description provided for @uiAboutVexgo532a39.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu VexGo'**
  String get uiAboutVexgo532a39;

  /// No description provided for @uiUserGuide.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn sử dụng'**
  String get uiUserGuide;

  /// No description provided for @uiWithYouOnEveryJourney.
  ///
  /// In vi, this message translates to:
  /// **'Đồng hành cùng hành trình của bạn'**
  String get uiWithYouOnEveryJourney;

  /// No description provided for @uiVexgoIsAnOnlineBusBookingAppThat.
  ///
  /// In vi, this message translates to:
  /// **'VexGo là ứng dụng đặt vé xe khách trực tuyến, giúp bạn tìm chuyến, chọn chỗ và theo dõi vé trên điện thoại.'**
  String get uiVexgoIsAnOnlineBusBookingAppThat;

  /// No description provided for @uiWhatCanYouDoWithVexgo.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể làm gì với VexGo?'**
  String get uiWhatCanYouDoWithVexgo;

  /// No description provided for @uiFaresSchedulesAndServiceConditionsAreShownFor.
  ///
  /// In vi, this message translates to:
  /// **'Giá vé, lịch chạy và điều kiện phục vụ được hiển thị theo từng chuyến. Bạn nên kiểm tra thông tin trước khi xác nhận đặt vé.'**
  String get uiFaresSchedulesAndServiceConditionsAreShownFor;

  /// No description provided for @ui1FindATrip.
  ///
  /// In vi, this message translates to:
  /// **'1. Tìm chuyến'**
  String get ui1FindATrip;

  /// No description provided for @uiSelectYourOriginDestinationAndDepartureDateOn.
  ///
  /// In vi, this message translates to:
  /// **'Chọn nơi đi, nơi đến và ngày khởi hành trên Trang chủ. Nếu đi khứ hồi, bật Khứ hồi và chọn ngày về. Mở kết quả để xem giờ chạy, giá và thông tin xe.'**
  String get uiSelectYourOriginDestinationAndDepartureDateOn;

  /// No description provided for @ui2SelectSeatsAndStops.
  ///
  /// In vi, this message translates to:
  /// **'2. Chọn ghế và điểm đón/trả'**
  String get ui2SelectSeatsAndStops;

  /// No description provided for @uiSelectAvailableSeatsOnTheTripSSeat.
  ///
  /// In vi, this message translates to:
  /// **'Chọn chỗ còn trống trên sơ đồ của chuyến. Với xe hai tầng, kiểm tra cả tầng dưới và tầng trên. Sau đó chọn điểm đón và điểm trả phù hợp. Hoàn tất đặt vé trong thời gian giữ chỗ hiển thị trên màn hình.'**
  String get uiSelectAvailableSeatsOnTheTripSSeat;

  /// No description provided for @ui3CheckPassengerDetailsAndOffers.
  ///
  /// In vi, this message translates to:
  /// **'3. Kiểm tra hành khách và ưu đãi'**
  String get ui3CheckPassengerDetailsAndOffers;

  /// No description provided for @uiEnterContactDetailsToReceiveYourTicketCheck.
  ///
  /// In vi, this message translates to:
  /// **'Điền thông tin liên hệ để nhận vé. Kiểm tra lại chuyến, ghế và các điểm đón/trả. Nếu có mã ưu đãi, nhập mã và chờ hệ thống kiểm tra điều kiện, sau đó xem tổng tiền đã cập nhật.'**
  String get uiEnterContactDetailsToReceiveYourTicketCheck;

  /// No description provided for @ui4PayAndReceiveTickets.
  ///
  /// In vi, this message translates to:
  /// **'4. Thanh toán và nhận vé'**
  String get ui4PayAndReceiveTickets;

  /// No description provided for @uiUseTheBankDetailsAmountAndTransferReference.
  ///
  /// In vi, this message translates to:
  /// **'Làm theo thông tin ngân hàng, số tiền và nội dung chuyển khoản trên màn hình thanh toán. Chờ hệ thống xác nhận, sau đó kiểm tra vé đã phát hành. Nếu hết thời gian giữ chỗ, kiểm tra trạng thái đơn trước khi đặt lại hoặc liên hệ hỗ trợ khi cần.'**
  String get uiUseTheBankDetailsAmountAndTransferReference;

  /// No description provided for @ui5LookUpTicketsAndReceipts.
  ///
  /// In vi, this message translates to:
  /// **'5. Tra cứu vé và chứng từ'**
  String get ui5LookUpTicketsAndReceipts;

  /// No description provided for @uiOpenMyTicketsForTicketsLinkedToYour.
  ///
  /// In vi, this message translates to:
  /// **'Mở Vé của tôi để xem các vé gắn với tài khoản. Khi đặt vé không đăng nhập, dùng thông tin tra cứu được cung cấp sau đặt vé. Từ Chi tiết vé, mở chứng từ đặt vé/thanh toán để xem thông tin đơn. Với khứ hồi, kiểm tra trạng thái vé của cả lượt đi và lượt về.'**
  String get uiOpenMyTicketsForTicketsLinkedToYour;

  /// No description provided for @ui6CancellationAndSupport.
  ///
  /// In vi, this message translates to:
  /// **'6. Hủy vé và hỗ trợ'**
  String get ui6CancellationAndSupport;

  /// No description provided for @uiOpenTicketDetailsAndCancelIfEligibleReview.
  ///
  /// In vi, this message translates to:
  /// **'Mở Chi tiết vé và chọn hủy nếu vé còn cho phép. Xem điều kiện, phí và số tiền hoàn được hệ thống hiển thị trước khi xác nhận. Hệ thống không hoàn tiền online. Sau khi hủy vé, liên hệ hỗ trợ và cung cấp mã vé để yêu cầu hoàn tiền theo chính sách nhà xe. Bạn có thể mở Chat với nhà xe trong Tài khoản để trao đổi.'**
  String get uiOpenTicketDetailsAndCancelIfEligibleReview;

  /// No description provided for @uiFromFindingTripsToReceivingTicketsAndManaging.
  ///
  /// In vi, this message translates to:
  /// **'Từ tìm chuyến đến nhận vé và quản lý hành trình. Chọn mục bạn cần xem.'**
  String get uiFromFindingTripsToReceivingTicketsAndManaging;

  /// No description provided for @uiBookWithVexgo.
  ///
  /// In vi, this message translates to:
  /// **'Đặt vé cùng VexGo'**
  String get uiBookWithVexgo;

  /// No description provided for @ui1FindTheRightTrip.
  ///
  /// In vi, this message translates to:
  /// **'1. Tìm chuyến phù hợp'**
  String get ui1FindTheRightTrip;

  /// No description provided for @ui2SelectSeatsAndJourneyDetails.
  ///
  /// In vi, this message translates to:
  /// **'2. Chọn ghế và thông tin hành trình'**
  String get ui2SelectSeatsAndJourneyDetails;

  /// No description provided for @ui3PayAndReceiveTickets.
  ///
  /// In vi, this message translates to:
  /// **'3. Thanh toán và nhận vé'**
  String get ui3PayAndReceiveTickets;

  /// No description provided for @uiViewBookingGuide.
  ///
  /// In vi, this message translates to:
  /// **'Xem hướng dẫn đặt vé'**
  String get uiViewBookingGuide;

  /// No description provided for @uiFindOneWayOrRoundTripsSelectSeats.
  ///
  /// In vi, this message translates to:
  /// **'• Tìm chuyến một chiều hoặc khứ hồi.\n\n• Chọn ghế và điểm đón/trả theo chuyến.\n\n• Xem giá, nhập mã ưu đãi và thanh toán theo hướng dẫn.\n\n• Tra cứu vé và chứng từ đặt vé/thanh toán.\n\n• Theo dõi thông báo và trao đổi qua chat hỗ trợ.'**
  String get uiFindOneWayOrRoundTripsSelectSeats;

  /// No description provided for @uiShipmentIdentificationQrCodeForVerificationAtThe.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR nhận diện vận đơn tại bến\n(Quét để đối chiếu tại quầy, không phải mã thanh toán chuyển khoản)'**
  String get uiShipmentIdentificationQrCodeForVerificationAtThe;

  /// No description provided for @ui1PaymentForThisBookingIsConfirmed2.
  ///
  /// In vi, this message translates to:
  /// **'1. Đơn hàng đã được xác nhận thanh toán thành công.\n\n2. Nếu danh sách vé chưa hiển thị hoặc đang đồng bộ, vui lòng nhấn nút \"Kiểm tra kết quả thanh toán\" ở thanh bên dưới.\n\n3. Bạn cũng có thể tra cứu lại vé bất kỳ lúc nào trong mục \"Vé của tôi\" bằng số điện thoại đặt vé.'**
  String get ui1PaymentForThisBookingIsConfirmed2;

  /// No description provided for @ui1DoNotTransferMoneyForThisBooking.
  ///
  /// In vi, this message translates to:
  /// **'1. Vui lòng không thực hiện chuyển khoản cho đơn hàng này.\n\n2. Nếu bạn đã chuyển khoản trước khi đơn hết hạn, nhấn \"Kiểm tra kết quả thanh toán\" để hệ thống đối soát.\n\n3. Trường hợp cần trợ giúp hoặc đã trừ tiền nhưng chưa có vé, vui lòng liên hệ tổng đài VexGo để được hỗ trợ.'**
  String get ui1DoNotTransferMoneyForThisBooking;

  /// No description provided for @ui1OpenYourBankingAppAndTransferThe.
  ///
  /// In vi, this message translates to:
  /// **'1. Mở ứng dụng ngân hàng và chuyển khoản đúng số tiền cùng nội dung chuyển khoản.\n\n2. Nhấn nút \"Kiểm tra kết quả thanh toán\" ở thanh bên dưới.\n\n3. Vé được hiển thị sau khi hệ thống xác nhận thanh toán và đồng bộ đầy đủ.'**
  String get ui1OpenYourBankingAppAndTransferThe;

  /// No description provided for @uiFilteringByOperator.
  ///
  /// In vi, this message translates to:
  /// **'Đang lọc theo nhà xe #{p0}'**
  String uiFilteringByOperator(Object p0);

  /// No description provided for @uiOverThe2000CharacterLimit2000Shorten.
  ///
  /// In vi, this message translates to:
  /// **'Vượt giới hạn 2.000 ký tự ({p0}/2000). Vui lòng rút gọn câu hỏi.'**
  String uiOverThe2000CharacterLimit2000Shorten(Object p0);

  /// No description provided for @ui2000Characters.
  ///
  /// In vi, this message translates to:
  /// **'{p0}/2000 ký tự'**
  String ui2000Characters(Object p0);

  /// No description provided for @uiInternalSources.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn tham khảo nội bộ ({p0})'**
  String uiInternalSources(Object p0);

  /// No description provided for @uiSources.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn tham khảo ({p0})'**
  String uiSources(Object p0);

  /// No description provided for @uiSuggestedTrips.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến xe gợi ý ({p0})'**
  String uiSuggestedTrips(Object p0);

  /// No description provided for @uiCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã: {p0}'**
  String uiCode(Object p0);

  /// No description provided for @uiDepartureDate0f7f31.
  ///
  /// In vi, this message translates to:
  /// **'Ngày đi: {p0}'**
  String uiDepartureDate0f7f31(Object p0);

  /// No description provided for @uiTime.
  ///
  /// In vi, this message translates to:
  /// **'Giờ: {p0} - {p1}'**
  String uiTime(Object p0, Object p1);

  /// No description provided for @uiDepartureTime527188.
  ///
  /// In vi, this message translates to:
  /// **'Giờ khởi hành: {p0}'**
  String uiDepartureTime527188(Object p0);

  /// No description provided for @uiVehicleType54222d.
  ///
  /// In vi, this message translates to:
  /// **'Loại xe: {p0}'**
  String uiVehicleType54222d(Object p0);

  /// No description provided for @uiEstimatedAvailableSeats.
  ///
  /// In vi, this message translates to:
  /// **'Chỗ trống tham khảo: {p0}'**
  String uiEstimatedAvailableSeats(Object p0);

  /// No description provided for @uiSource.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn: {p0}'**
  String uiSource(Object p0);

  /// No description provided for @uiPassengerCountChangedCheckTheLuggageAllowanceFor.
  ///
  /// In vi, this message translates to:
  /// **'Số ghế đã thay đổi ({p0} → {p1} hành khách). Vui lòng kiểm tra lại hạn mức hành lý theo số hành khách mới.'**
  String uiPassengerCountChangedCheckTheLuggageAllowanceFor(
    Object p0,
    Object p1,
  );

  /// No description provided for @uiTickets.
  ///
  /// In vi, this message translates to:
  /// **'{p0} vé'**
  String uiTickets(Object p0);

  /// No description provided for @uiSeat25a5f5.
  ///
  /// In vi, this message translates to:
  /// **'Ghế {p0}'**
  String uiSeat25a5f5(Object p0);

  /// No description provided for @uiSelectUpToSeatsPerBooking.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tối đa {p0} chỗ cho mỗi lượt đặt.'**
  String uiSelectUpToSeatsPerBooking(Object p0);

  /// No description provided for @uiSelectPickUpIn.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điểm đón tại {p0}'**
  String uiSelectPickUpIn(Object p0);

  /// No description provided for @uiSelectDropOffIn.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điểm trả tại {p0}'**
  String uiSelectDropOffIn(Object p0);

  /// No description provided for @uiSeats9c637d.
  ///
  /// In vi, this message translates to:
  /// **'Ghế: {p0}'**
  String uiSeats9c637d(Object p0);

  /// No description provided for @uiPickUpfb4009.
  ///
  /// In vi, this message translates to:
  /// **'Đón: {p0}'**
  String uiPickUpfb4009(Object p0);

  /// No description provided for @uiDropOff52eaac.
  ///
  /// In vi, this message translates to:
  /// **'Trả: {p0}'**
  String uiDropOff52eaac(Object p0);

  /// No description provided for @uiRequired.
  ///
  /// In vi, this message translates to:
  /// **'{p0}, bắt buộc'**
  String uiRequired(Object p0);

  /// No description provided for @uiSeats4f4448.
  ///
  /// In vi, this message translates to:
  /// **'{p0} chỗ'**
  String uiSeats4f4448(Object p0);

  /// No description provided for @uiSeatLocations.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí chỗ ngồi: {p0}'**
  String uiSeatLocations(Object p0);

  /// No description provided for @uiCheckingCode.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra mã: {p0}'**
  String uiCheckingCode(Object p0);

  /// No description provided for @uiCodeNotConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Mã chưa được xác nhận: {p0}'**
  String uiCodeNotConfirmed(Object p0);

  /// No description provided for @uiAppliedCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã đã áp dụng: {p0}'**
  String uiAppliedCode(Object p0);

  /// No description provided for @uiYouSave.
  ///
  /// In vi, this message translates to:
  /// **'Tiết kiệm được {p0}'**
  String uiYouSave(Object p0);

  /// No description provided for @uiFareSeats.
  ///
  /// In vi, this message translates to:
  /// **'Giá vé ({p0} chỗ)'**
  String uiFareSeats(Object p0);

  /// No description provided for @uiNotAddedToBooking.
  ///
  /// In vi, this message translates to:
  /// **'{p0} (chưa cộng vào đơn)'**
  String uiNotAddedToBooking(Object p0);

  /// No description provided for @uiCopied6cef06.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép {p0}'**
  String uiCopied6cef06(Object p0);

  /// No description provided for @uiSeatHoldTimeRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian giữ chỗ còn lại: {p0}'**
  String uiSeatHoldTimeRemaining(Object p0);

  /// No description provided for @uiFareAfterDiscountsItemFeesPaidSeparatelyAt.
  ///
  /// In vi, this message translates to:
  /// **'Tiền vé sau ưu đãi: {p0} • Cước vật phẩm thanh toán riêng tại bến'**
  String uiFareAfterDiscountsItemFeesPaidSeparatelyAt(Object p0);

  /// No description provided for @uiTickets94511a.
  ///
  /// In vi, this message translates to:
  /// **'{p0} Vé'**
  String uiTickets94511a(Object p0);

  /// No description provided for @uiPickUp67b5a7.
  ///
  /// In vi, this message translates to:
  /// **'Điểm đón: {p0}'**
  String uiPickUp67b5a7(Object p0);

  /// No description provided for @uiDropOff782e84.
  ///
  /// In vi, this message translates to:
  /// **'Điểm trả: {p0}'**
  String uiDropOff782e84(Object p0);

  /// No description provided for @uiBooking.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đặt chỗ: #{p0}'**
  String uiBooking(Object p0);

  /// No description provided for @uiBookingCode8ca81b.
  ///
  /// In vi, this message translates to:
  /// **'Mã đặt vé: {p0}'**
  String uiBookingCode8ca81b(Object p0);

  /// No description provided for @uiBookingCodeb74fc3.
  ///
  /// In vi, this message translates to:
  /// **'mã đặt vé: {p0}'**
  String uiBookingCodeb74fc3(Object p0);

  /// No description provided for @uiTicketCode628257.
  ///
  /// In vi, this message translates to:
  /// **'Mã vé: {p0}'**
  String uiTicketCode628257(Object p0);

  /// No description provided for @uiTicketCode5fb7de.
  ///
  /// In vi, this message translates to:
  /// **'mã vé: {p0}'**
  String uiTicketCode5fb7de(Object p0);

  /// No description provided for @uiTransferReference1c34c4.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung chuyển khoản: {p0}'**
  String uiTransferReference1c34c4(Object p0);

  /// No description provided for @uiTransferReferencecedf32.
  ///
  /// In vi, this message translates to:
  /// **'nội dung chuyển khoản: {p0}'**
  String uiTransferReferencecedf32(Object p0);

  /// No description provided for @uiBankb96a80.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng: {p0}'**
  String uiBankb96a80(Object p0);

  /// No description provided for @uiAccountNumberaa169c.
  ///
  /// In vi, this message translates to:
  /// **'Số tài khoản: {p0}'**
  String uiAccountNumberaa169c(Object p0);

  /// No description provided for @uiAccountNumbera056e0.
  ///
  /// In vi, this message translates to:
  /// **'số tài khoản: {p0}'**
  String uiAccountNumbera056e0(Object p0);

  /// No description provided for @uiAccountHolderd62428.
  ///
  /// In vi, this message translates to:
  /// **'Chủ tài khoản: {p0}'**
  String uiAccountHolderd62428(Object p0);

  /// No description provided for @uiAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền: {p0}'**
  String uiAmount(Object p0);

  /// No description provided for @uiAmount4651de.
  ///
  /// In vi, this message translates to:
  /// **'số tiền: {p0}'**
  String uiAmount4651de(Object p0);

  /// No description provided for @uiTransactionCode3e5784.
  ///
  /// In vi, this message translates to:
  /// **'Mã giao dịch: #{p0}'**
  String uiTransactionCode3e5784(Object p0);

  /// No description provided for @uiSeatsCount.
  ///
  /// In vi, this message translates to:
  /// **'Ghế: {p0} ({p1} chỗ)'**
  String uiSeatsCount(Object p0, Object p1);

  /// No description provided for @uiPay.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán {p0}'**
  String uiPay(Object p0);

  /// No description provided for @uiNoSuitableCategoryForIsAvailableOnThis.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến xe không có danh mục phù hợp cho nhóm {p0}.'**
  String uiNoSuitableCategoryForIsAvailableOnThis(Object p0);

  /// No description provided for @uiQuantityExceedsRemainingCapacitySpacesFor.
  ///
  /// In vi, this message translates to:
  /// **'Số lượng vượt quá sức chứa còn lại ({p0} chỗ cho {p1}).'**
  String uiQuantityExceedsRemainingCapacitySpacesFor(Object p0, Object p1);

  /// No description provided for @uiSpacesLeft.
  ///
  /// In vi, this message translates to:
  /// **'{p0}: còn {p1} chỗ'**
  String uiSpacesLeft(Object p0, Object p1);

  /// No description provided for @uiItems583419.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách kiện hàng ({p0})'**
  String uiItems583419(Object p0);

  /// No description provided for @uiCategory.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục #{p0}'**
  String uiCategory(Object p0);

  /// No description provided for @uiSpecifiedWeightKgVehicle.
  ///
  /// In vi, this message translates to:
  /// **'Khối lượng quy định: {p0} kg/xe'**
  String uiSpecifiedWeightKgVehicle(Object p0);

  /// No description provided for @uiWeightKgDimensionsCmVolumetricKg.
  ///
  /// In vi, this message translates to:
  /// **'Khối lượng: {p0} kg • Kích thước: {p1}×{p2}×{p3} cm (Quy đổi: {p4} kg)'**
  String uiWeightKgDimensionsCmVolumetricKg(
    Object p0,
    Object p1,
    Object p2,
    Object p3,
    Object p4,
  );

  /// No description provided for @uiWeightKg2d5bda.
  ///
  /// In vi, this message translates to:
  /// **'Khối lượng: {p0} kg'**
  String uiWeightKg2d5bda(Object p0);

  /// No description provided for @uiVehicleModel.
  ///
  /// In vi, this message translates to:
  /// **'Dòng xe: {p0}'**
  String uiVehicleModel(Object p0);

  /// No description provided for @uiLicencePlate799484.
  ///
  /// In vi, this message translates to:
  /// **'Biển số: {p0}'**
  String uiLicencePlate799484(Object p0);

  /// No description provided for @uiNotes.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú: {p0}'**
  String uiNotes(Object p0);

  /// No description provided for @uiEditItem7033d5.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa kiện hàng #{p0}'**
  String uiEditItem7033d5(Object p0);

  /// No description provided for @uiNoItemCategoryForIsAvailableOnThis.
  ///
  /// In vi, this message translates to:
  /// **'Không có danh mục hàng cho nhóm {p0} trên chuyến này.'**
  String uiNoItemCategoryForIsAvailableOnThis(Object p0);

  /// No description provided for @uiItemCategoryfbfebd.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục hàng ({p0})'**
  String uiItemCategoryfbfebd(Object p0);

  /// No description provided for @uiLuggage030449.
  ///
  /// In vi, this message translates to:
  /// **'Hành lý · {p0}'**
  String uiLuggage030449(Object p0);

  /// No description provided for @uiFreeCarryOnKgPassenger.
  ///
  /// In vi, this message translates to:
  /// **'Xách tay miễn phí ≤ {p0} kg/khách'**
  String uiFreeCarryOnKgPassenger(Object p0);

  /// No description provided for @uiCarryOnItemsKgItem.
  ///
  /// In vi, this message translates to:
  /// **'Xách tay · {p0} kiện · {p1} kg/kiện'**
  String uiCarryOnItemsKgItem(Object p0, Object p1);

  /// No description provided for @uiPackage.
  ///
  /// In vi, this message translates to:
  /// **'Gói {p0}'**
  String uiPackage(Object p0);

  /// No description provided for @uiKgItem.
  ///
  /// In vi, this message translates to:
  /// **'{p0} kg/kiện'**
  String uiKgItem(Object p0);

  /// No description provided for @uiCarryOnExceedsTheFreeAllowanceKgItem.
  ///
  /// In vi, this message translates to:
  /// **'Hành lý xách tay vượt hạn mức miễn phí ({p0} kg/kiện); hãy chuyển sang hành lý ký gửi.'**
  String uiCarryOnExceedsTheFreeAllowanceKgItem(Object p0);

  /// No description provided for @uiEachPassengerMayRegisterOneFreeCarryOn.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi hành khách được khai báo tối đa một kiện xách tay miễn phí (tối đa {p0} kiện). Hãy chuyển kiện vượt sang hành lý ký gửi.'**
  String uiEachPassengerMayRegisterOneFreeCarryOn(Object p0);

  /// No description provided for @uiPassengers.
  ///
  /// In vi, this message translates to:
  /// **'{p0} hành khách'**
  String uiPassengers(Object p0);

  /// No description provided for @uiYourSelectedLuggageCheckedCarryOnIsKept.
  ///
  /// In vi, this message translates to:
  /// **'Hành lý đã chọn ({p0} mục ký gửi, {p1} mục xách tay) vẫn được giữ nguyên. Hãy thử tải lại chính sách hoặc chọn \"Không thêm hành lý ký gửi\" nếu chỉ muốn đặt vé.'**
  String uiYourSelectedLuggageCheckedCarryOnIsKept(Object p0, Object p1);

  /// No description provided for @uiCarryOnFreeKgPassenger.
  ///
  /// In vi, this message translates to:
  /// **'Xách tay · miễn phí ≤ {p0} kg/khách'**
  String uiCarryOnFreeKgPassenger(Object p0);

  /// No description provided for @uiFreeKgItemMaximumItems.
  ///
  /// In vi, this message translates to:
  /// **'Miễn phí ≤ {p0} kg/kiện • Tối đa {p1} kiện'**
  String uiFreeKgItemMaximumItems(Object p0, Object p1);

  /// No description provided for @uiCarryOnKgItems.
  ///
  /// In vi, this message translates to:
  /// **'Kiện xách tay #{p0}: {p1} kg × {p2} kiện'**
  String uiCarryOnKgItems(Object p0, Object p1, Object p2);

  /// No description provided for @uiExceedsTheFreeAllowanceKgItemMoveTo.
  ///
  /// In vi, this message translates to:
  /// **'Vượt hạn mức miễn phí ({p0} kg/kiện). Hãy chuyển sang hành lý ký gửi.'**
  String uiExceedsTheFreeAllowanceKgItemMoveTo(Object p0);

  /// No description provided for @uiCarryOnCountExceedsPassengerCountMoveExtra.
  ///
  /// In vi, this message translates to:
  /// **'Tổng số kiện xách tay ({p0}) vượt quá số hành khách ({p1}). Hãy chuyển sang hành lý ký gửi.'**
  String uiCarryOnCountExceedsPassengerCountMoveExtra(Object p0, Object p1);

  /// No description provided for @uiEditCarryOnItem98d081.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa kiện xách tay #{p0}'**
  String uiEditCarryOnItem98d081(Object p0);

  /// No description provided for @uiWeightKga695f2.
  ///
  /// In vi, this message translates to:
  /// **'Khối lượng (kg, ≤{p0}) *'**
  String uiWeightKga695f2(Object p0);

  /// No description provided for @uiItemCount.
  ///
  /// In vi, this message translates to:
  /// **'Số kiện (≤{p0}) *'**
  String uiItemCount(Object p0);

  /// No description provided for @uiCheckedLuggage8cf512.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách hành lý ký gửi ({p0})'**
  String uiCheckedLuggage8cf512(Object p0);

  /// No description provided for @uiMotorbike10c633.
  ///
  /// In vi, this message translates to:
  /// **'Xe máy ({p0})'**
  String uiMotorbike10c633(Object p0);

  /// No description provided for @uiEstimated.
  ///
  /// In vi, this message translates to:
  /// **'Dự tính {p0}'**
  String uiEstimated(Object p0);

  /// No description provided for @uiWeightKgDimensionsCmChargeableKg.
  ///
  /// In vi, this message translates to:
  /// **'Khối lượng: {p0} kg • Kích thước: {p1}×{p2}×{p3} cm (Hiệu dụng: {p4} kg)'**
  String uiWeightKgDimensionsCmChargeableKg(
    Object p0,
    Object p1,
    Object p2,
    Object p3,
    Object p4,
  );

  /// No description provided for @uiEditCheckedItem.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa mục ký gửi #{p0}'**
  String uiEditCheckedItem(Object p0);

  /// No description provided for @uiPackageKg.
  ///
  /// In vi, this message translates to:
  /// **'Gói {p0} · ≤ {p1} kg'**
  String uiPackageKg(Object p0, Object p1);

  /// No description provided for @uiBicycle8324c2.
  ///
  /// In vi, this message translates to:
  /// **'Xe đạp ({p0})'**
  String uiBicycle8324c2(Object p0);

  /// No description provided for @uiTicket.
  ///
  /// In vi, this message translates to:
  /// **'Vé {p0}'**
  String uiTicket(Object p0);

  /// No description provided for @uiBooking36090d.
  ///
  /// In vi, this message translates to:
  /// **'Đơn #{p0}'**
  String uiBooking36090d(Object p0);

  /// No description provided for @uiDiscounted.
  ///
  /// In vi, this message translates to:
  /// **'Đã giảm {p0}'**
  String uiDiscounted(Object p0);

  /// No description provided for @uiSelectedSeatsdead0d.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn {p0} chỗ: {p1}'**
  String uiSelectedSeatsdead0d(Object p0, Object p1);

  /// No description provided for @ui.
  ///
  /// In vi, this message translates to:
  /// **'{p0} ⌃'**
  String ui(Object p0);

  /// No description provided for @uiSeatDeck.
  ///
  /// In vi, this message translates to:
  /// **'Ghế {p0} • Tầng {p1}'**
  String uiSeatDeck(Object p0, Object p1);

  /// No description provided for @uiEstimate.
  ///
  /// In vi, this message translates to:
  /// **'Tạm tính: {p0}'**
  String uiEstimate(Object p0);

  /// No description provided for @uiStep.
  ///
  /// In vi, this message translates to:
  /// **'Bước {p0}/{p1}: {p2}, {p3}'**
  String uiStep(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @uiStepd0a756.
  ///
  /// In vi, this message translates to:
  /// **'Bước {p0}/{p1}'**
  String uiStepd0a756(Object p0, Object p1);

  /// No description provided for @uiSeatHoldExpiring.
  ///
  /// In vi, this message translates to:
  /// **'Sắp hết hạn giữ ghế{p0}: '**
  String uiSeatHoldExpiring(Object p0);

  /// No description provided for @uiSeatsHeld.
  ///
  /// In vi, this message translates to:
  /// **'Ghế đang được giữ{p0}: '**
  String uiSeatsHeld(Object p0);

  /// No description provided for @uiSeat45469b.
  ///
  /// In vi, this message translates to:
  /// **'Ghế {p0}, {p1}{p2}'**
  String uiSeat45469b(Object p0, Object p1, Object p2);

  /// No description provided for @uiAvailableStops.
  ///
  /// In vi, this message translates to:
  /// **'Có {p0} điểm để lựa chọn'**
  String uiAvailableStops(Object p0);

  /// No description provided for @uiTheBookingDoesNotMeetTheMinimumOf.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng chưa đạt mức tối thiểu {p0}'**
  String uiTheBookingDoesNotMeetTheMinimumOf(Object p0);

  /// No description provided for @uiApplied.
  ///
  /// In vi, this message translates to:
  /// **'Đang áp dụng: {p0}'**
  String uiApplied(Object p0);

  /// No description provided for @uiAnAdditionalIsRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần thêm {p0}'**
  String uiAnAdditionalIsRequired(Object p0);

  /// No description provided for @uiFormer.
  ///
  /// In vi, this message translates to:
  /// **'{p0} (cũ)'**
  String uiFormer(Object p0);

  /// No description provided for @uiFormerLocationName.
  ///
  /// In vi, this message translates to:
  /// **'{p0} (địa danh cũ)'**
  String uiFormerLocationName(Object p0);

  /// No description provided for @uiStationsStops.
  ///
  /// In vi, this message translates to:
  /// **'{p0} • {p1} bến xe/điểm đón'**
  String uiStationsStops(Object p0, Object p1);

  /// No description provided for @uiViewAllOffers.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả {p0} ưu đãi'**
  String uiViewAllOffers(Object p0);

  /// No description provided for @uiSaveCode.
  ///
  /// In vi, this message translates to:
  /// **'Giảm {p0} · Mã {p1}'**
  String uiSaveCode(Object p0, Object p1);

  /// No description provided for @uiMinimumFare.
  ///
  /// In vi, this message translates to:
  /// **'Tiền vé tối thiểu: {p0}'**
  String uiMinimumFare(Object p0);

  /// No description provided for @uiMaximumDiscount.
  ///
  /// In vi, this message translates to:
  /// **'Giảm tối đa: {p0}'**
  String uiMaximumDiscount(Object p0);

  /// No description provided for @uiValid.
  ///
  /// In vi, this message translates to:
  /// **'Hiệu lực: {p0} – {p1}'**
  String uiValid(Object p0, Object p1);

  /// No description provided for @uiCopyCode30ae06.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép mã {p0}'**
  String uiCopyCode30ae06(Object p0);

  /// No description provided for @uiPolicy.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách: {p0}'**
  String uiPolicy(Object p0);

  /// No description provided for @uiDistance.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng cách: {p0}'**
  String uiDistance(Object p0);

  /// No description provided for @uiNoTicketsMatchCheckTheTicketCodePhone.
  ///
  /// In vi, this message translates to:
  /// **'Không có vé nào khớp với từ khóa \"{p0}\". Vui lòng kiểm tra lại mã vé, số điện thoại hoặc lộ trình.'**
  String uiNoTicketsMatchCheckTheTicketCodePhone(Object p0);

  /// No description provided for @uiContactForTrip.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ chuyến đi {p0}'**
  String uiContactForTrip(Object p0);

  /// No description provided for @uiReviewed5View.
  ///
  /// In vi, this message translates to:
  /// **'Đã đánh giá • {p0}/5 — Xem'**
  String uiReviewed5View(Object p0);

  /// No description provided for @ui56e768.
  ///
  /// In vi, this message translates to:
  /// **'{p0} ➔ {p1}'**
  String ui56e768(Object p0, Object p1);

  /// No description provided for @uiSeatscfb411.
  ///
  /// In vi, this message translates to:
  /// **'Chỗ ngồi: {p0}'**
  String uiSeatscfb411(Object p0);

  /// No description provided for @uiThisTripDepartsAtOnContactTheOperator.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến xe khởi hành lúc {p0} ngày {p1}. Quý khách vui lòng liên hệ nhà xe nếu cần trợ giúp.'**
  String uiThisTripDepartsAtOnContactTheOperator(Object p0, Object p1);

  /// No description provided for @uiContactPhone.
  ///
  /// In vi, this message translates to:
  /// **'SĐT liên hệ: {p0}'**
  String uiContactPhone(Object p0);

  /// No description provided for @uiCancellationFee.
  ///
  /// In vi, this message translates to:
  /// **'Phí hủy theo quy định ({p0}%):'**
  String uiCancellationFee(Object p0);

  /// No description provided for @uiIAgreeToCancelAndAcceptTheCancellation.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đồng ý hủy vé và chấp nhận mức khấu trừ phí hủy {p0}% ({p1}) nêu trên.'**
  String uiIAgreeToCancelAndAcceptTheCancellation(Object p0, Object p1);

  /// No description provided for @uiCancellationFee942acf.
  ///
  /// In vi, this message translates to:
  /// **'Phí hủy ({p0}%): '**
  String uiCancellationFee942acf(Object p0);

  /// No description provided for @uiReplyFrom.
  ///
  /// In vi, this message translates to:
  /// **'Phản hồi từ {p0}'**
  String uiReplyFrom(Object p0);

  /// No description provided for @uiPickUp4845a7.
  ///
  /// In vi, this message translates to:
  /// **'Đón: {p0} ({p1})'**
  String uiPickUp4845a7(Object p0, Object p1);

  /// No description provided for @uiReason.
  ///
  /// In vi, this message translates to:
  /// **'Lý do: {p0}'**
  String uiReason(Object p0);

  /// No description provided for @uiEstimatedRefund26c8c6.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến hoàn: {p0}'**
  String uiEstimatedRefund26c8c6(Object p0);

  /// No description provided for @ui0Reviewed.
  ///
  /// In vi, this message translates to:
  /// **'{p0}.0 (Đã đánh giá)'**
  String ui0Reviewed(Object p0);

  /// No description provided for @uiHide.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn {p0}'**
  String uiHide(Object p0);

  /// No description provided for @uiShow.
  ///
  /// In vi, this message translates to:
  /// **'Hiện {p0}'**
  String uiShow(Object p0);

  /// No description provided for @uiEnterThe6DigitVerificationCodeFor.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã OTP gồm 6 chữ số cho {p0}.'**
  String uiEnterThe6DigitVerificationCodeFor(Object p0);

  /// No description provided for @uiResendCodeInSeconds.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã sau {p0} giây'**
  String uiResendCodeInSeconds(Object p0);

  /// No description provided for @uiPoints746cfa.
  ///
  /// In vi, this message translates to:
  /// **'{p0} điểm'**
  String uiPoints746cfa(Object p0);

  /// No description provided for @uiA6DigitVerificationCodeWasSentTo.
  ///
  /// In vi, this message translates to:
  /// **'Mã xác thực gồm 6 chữ số đã được gửi đến số điện thoại {p0}'**
  String uiA6DigitVerificationCodeWasSentTo(Object p0);

  /// No description provided for @uiTier.
  ///
  /// In vi, this message translates to:
  /// **'HẠNG {p0}'**
  String uiTier(Object p0);

  /// No description provided for @uiPointsNeededForTheNextTier.
  ///
  /// In vi, this message translates to:
  /// **'Cần thêm {p0} điểm để lên hạng tiếp theo'**
  String uiPointsNeededForTheNextTier(Object p0);

  /// No description provided for @uiTierba8164.
  ///
  /// In vi, this message translates to:
  /// **'Hạng {p0}'**
  String uiTierba8164(Object p0);

  /// No description provided for @uiPointsRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần: {p0} điểm'**
  String uiPointsRequired(Object p0);

  /// No description provided for @uiPoints05f590.
  ///
  /// In vi, this message translates to:
  /// **'{p0}{p1} điểm'**
  String uiPoints05f590(Object p0, Object p1);

  /// No description provided for @uiArriveBy.
  ///
  /// In vi, this message translates to:
  /// **'Có mặt trước: {p0}'**
  String uiArriveBy(Object p0);

  /// No description provided for @uiArriveMinutesBeforePickUp.
  ///
  /// In vi, this message translates to:
  /// **'Có mặt trước giờ đón {p0} phút'**
  String uiArriveMinutesBeforePickUp(Object p0);

  /// No description provided for @uiStopSurcharge.
  ///
  /// In vi, this message translates to:
  /// **'Phụ phí tại điểm: {p0}'**
  String uiStopSurcharge(Object p0);

  /// No description provided for @uiStopContact.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ điểm: {p0}'**
  String uiStopContact(Object p0);

  /// No description provided for @uiShuttle.
  ///
  /// In vi, this message translates to:
  /// **'Trung chuyển: {p0}'**
  String uiShuttle(Object p0);

  /// No description provided for @uiShuttleAddress.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ trung chuyển: {p0}'**
  String uiShuttleAddress(Object p0);

  /// No description provided for @uiType.
  ///
  /// In vi, this message translates to:
  /// **'Loại: {p0}'**
  String uiType(Object p0);

  /// No description provided for @uiDeclaredWeightKg.
  ///
  /// In vi, this message translates to:
  /// **'Khối lượng khai báo: {p0} kg'**
  String uiDeclaredWeightKg(Object p0);

  /// No description provided for @uiTicketsInBooking.
  ///
  /// In vi, this message translates to:
  /// **'Vé trong đơn ({p0})'**
  String uiTicketsInBooking(Object p0);

  /// No description provided for @uiSeatba07d4.
  ///
  /// In vi, this message translates to:
  /// **'Ghế {p0} • {p1}'**
  String uiSeatba07d4(Object p0, Object p1);

  /// No description provided for @uiSeatCountForChangedPassengersCheckTheLuggage.
  ///
  /// In vi, this message translates to:
  /// **'Số ghế {p0} đã thay đổi ({p1} → {p2} hành khách). Vui lòng kiểm tra lại hạn mức hành lý theo số hành khách mới.'**
  String uiSeatCountForChangedPassengersCheckTheLuggage(
    Object p0,
    Object p1,
    Object p2,
  );

  /// No description provided for @uiCompletedb1ec0b.
  ///
  /// In vi, this message translates to:
  /// **'Đã xong {p0}'**
  String uiCompletedb1ec0b(Object p0);

  /// No description provided for @uiSelectSeatsAndStopsForToContinue.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn chỗ ngồi và điểm đón/trả cho {p0} để tiếp tục tiến trình.'**
  String uiSelectSeatsAndStopsForToContinue(Object p0);

  /// No description provided for @uiSwitchTo.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển sang {p0}'**
  String uiSwitchTo(Object p0);

  /// No description provided for @uiSelectPickUp.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điểm đón ({p0})'**
  String uiSelectPickUp(Object p0);

  /// No description provided for @uiSelectDropOff9938e9.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điểm trả ({p0})'**
  String uiSelectDropOff9938e9(Object p0);

  /// No description provided for @uiSelected3e13f1.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn: {p0}'**
  String uiSelected3e13f1(Object p0);

  /// No description provided for @ui742d76.
  ///
  /// In vi, this message translates to:
  /// **'{p0} ⇄ {p1}'**
  String ui742d76(Object p0, Object p1);

  /// No description provided for @uiTickets11c2bb.
  ///
  /// In vi, this message translates to:
  /// **'{p0} - {p1} • {p2} vé'**
  String uiTickets11c2bb(Object p0, Object p1, Object p2);

  /// No description provided for @uiOutbound39fb6f.
  ///
  /// In vi, this message translates to:
  /// **'Lượt đi: {p0} → {p1}'**
  String uiOutbound39fb6f(Object p0, Object p1);

  /// No description provided for @uiReturn0b24ba.
  ///
  /// In vi, this message translates to:
  /// **'Lượt về: {p0} → {p1}'**
  String uiReturn0b24ba(Object p0, Object p1);

  /// No description provided for @uiSearchingForTrips3befb9.
  ///
  /// In vi, this message translates to:
  /// **'Đang tìm kiếm chuyến {p0}...'**
  String uiSearchingForTrips3befb9(Object p0);

  /// No description provided for @uiNoTripsFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy chuyến {p0}'**
  String uiNoTripsFound(Object p0);

  /// No description provided for @uiNoTripsDepartOnOrThereAreNot.
  ///
  /// In vi, this message translates to:
  /// **'Không có chuyến nào khởi hành vào ngày {p0} hoặc đã hết chỗ cho {p1} vé.'**
  String uiNoTripsDepartOnOrThereAreNot(Object p0, Object p1);

  /// No description provided for @uiSelected01ccfb.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn {p0}:'**
  String uiSelected01ccfb(Object p0);

  /// No description provided for @uiOutbound8a89c9.
  ///
  /// In vi, this message translates to:
  /// **'Đi: {p0} ({p1})'**
  String uiOutbound8a89c9(Object p0, Object p1);

  /// No description provided for @uiReturn824be9.
  ///
  /// In vi, this message translates to:
  /// **'Về: {p0} ({p1})'**
  String uiReturn824be9(Object p0, Object p1);

  /// No description provided for @uiPaymentForIsCompletePayForToComplete.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã thanh toán thành công cho {p0}. Vui lòng hoàn tất thanh toán cho {p1} để hoàn thành chuyến khứ hồi.'**
  String uiPaymentForIsCompletePayForToComplete(Object p0, Object p1);

  /// No description provided for @ui1OutboundPayment.
  ///
  /// In vi, this message translates to:
  /// **'1. Thanh toán Lượt đi: {p0} → {p1}'**
  String ui1OutboundPayment(Object p0, Object p1);

  /// No description provided for @ui2ReturnPayment.
  ///
  /// In vi, this message translates to:
  /// **'2. Thanh toán Lượt về: {p0} → {p1}'**
  String ui2ReturnPayment(Object p0, Object p1);

  /// No description provided for @uiSelectedSeats09ff88.
  ///
  /// In vi, this message translates to:
  /// **'Ghế đã chọn: {p0}'**
  String uiSelectedSeats09ff88(Object p0);

  /// No description provided for @uiExpiresIn.
  ///
  /// In vi, this message translates to:
  /// **'Hết hạn sau: {p0}:{p1}'**
  String uiExpiresIn(Object p0, Object p1);

  /// No description provided for @uiCopy4ecb8d.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép {p0}'**
  String uiCopy4ecb8d(Object p0);

  /// No description provided for @uiOutboundTickets.
  ///
  /// In vi, this message translates to:
  /// **'Lượt đi ({p0} vé)'**
  String uiOutboundTickets(Object p0);

  /// No description provided for @uiReturnTickets.
  ///
  /// In vi, this message translates to:
  /// **'Lượt về ({p0} vé)'**
  String uiReturnTickets(Object p0);

  /// No description provided for @uiPickUp4156d4.
  ///
  /// In vi, this message translates to:
  /// **'Đón: {p0} - {p1}'**
  String uiPickUp4156d4(Object p0, Object p1);

  /// No description provided for @uiDropOff05415d.
  ///
  /// In vi, this message translates to:
  /// **'Trả: {p0} - {p1}'**
  String uiDropOff05415d(Object p0, Object p1);

  /// No description provided for @uiPromoCodef90eb2.
  ///
  /// In vi, this message translates to:
  /// **'Mã giảm giá {p0}'**
  String uiPromoCodef90eb2(Object p0);

  /// No description provided for @uiSeatsLeft.
  ///
  /// In vi, this message translates to:
  /// **'Còn {p0} chỗ'**
  String uiSeatsLeft(Object p0);

  /// No description provided for @uiTickets719a21.
  ///
  /// In vi, this message translates to:
  /// **'{p0} • {p1} vé'**
  String uiTickets719a21(Object p0, Object p1);

  /// No description provided for @uiTripsFound.
  ///
  /// In vi, this message translates to:
  /// **'Tìm thấy {p0} chuyến xe'**
  String uiTripsFound(Object p0);

  /// No description provided for @uiClearFilters.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bộ lọc ({p0})'**
  String uiClearFilters(Object p0);

  /// No description provided for @uiClearFiltersa8df77.
  ///
  /// In vi, this message translates to:
  /// **'Xóa lọc ({p0})'**
  String uiClearFiltersa8df77(Object p0);

  /// No description provided for @uiFare.
  ///
  /// In vi, this message translates to:
  /// **'{p0}, giá {p1}'**
  String uiFare(Object p0, Object p1);

  /// No description provided for @uiOpenFiltersFiltersSelected.
  ///
  /// In vi, this message translates to:
  /// **'Mở bộ lọc, có {p0} bộ lọc đang chọn'**
  String uiOpenFiltersFiltersSelected(Object p0);

  /// No description provided for @uiSortBy58dd7b.
  ///
  /// In vi, this message translates to:
  /// **'Sắp xếp theo: {p0}'**
  String uiSortBy58dd7b(Object p0);

  /// No description provided for @uiTicketSeatsLeft.
  ///
  /// In vi, this message translates to:
  /// **'/vé · Còn {p0} chỗ'**
  String uiTicketSeatsLeft(Object p0);

  /// No description provided for @uiPickUpb65f22.
  ///
  /// In vi, this message translates to:
  /// **'Điểm đón • {p0}'**
  String uiPickUpb65f22(Object p0);

  /// No description provided for @uiDropOff37f63f.
  ///
  /// In vi, this message translates to:
  /// **'Điểm trả • {p0}'**
  String uiDropOff37f63f(Object p0);

  /// No description provided for @uiShipmentCodeee9663.
  ///
  /// In vi, this message translates to:
  /// **'Mã vận đơn: {p0}'**
  String uiShipmentCodeee9663(Object p0);

  /// No description provided for @uiSelectRouteAndOperatorOperatorsFound.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tuyến và nhà xe ({p0} nhà xe tìm thấy):'**
  String uiSelectRouteAndOperatorOperatorsFound(Object p0);

  /// No description provided for @uiFeesFrom.
  ///
  /// In vi, this message translates to:
  /// **'Cước từ {p0}'**
  String uiFeesFrom(Object p0);

  /// No description provided for @uiEstimatedFeeTheFinalFeeIsConfirmedAfter.
  ///
  /// In vi, this message translates to:
  /// **'Cước dự tính: {p0}. Cước được chốt sau cân đo tại bến.'**
  String uiEstimatedFeeTheFinalFeeIsConfirmedAfter(Object p0);

  /// No description provided for @uiItem.
  ///
  /// In vi, this message translates to:
  /// **'Kiện #{p0}'**
  String uiItem(Object p0);

  /// No description provided for @uiCopiedd3e09c.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép {p0}: {p1}'**
  String uiCopiedd3e09c(Object p0, Object p1);

  /// No description provided for @uiCreatedb409e6.
  ///
  /// In vi, this message translates to:
  /// **'Ngày tạo đơn: {p0}'**
  String uiCreatedb409e6(Object p0);

  /// No description provided for @uiExpectedShippingDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày dự kiến gửi: {p0}'**
  String uiExpectedShippingDate(Object p0);

  /// No description provided for @uiRoute97d69f.
  ///
  /// In vi, this message translates to:
  /// **'Tuyến: {p0} → {p1}'**
  String uiRoute97d69f(Object p0, Object p1);

  /// No description provided for @uiDeparture.
  ///
  /// In vi, this message translates to:
  /// **'Khởi hành: {p0}'**
  String uiDeparture(Object p0);

  /// No description provided for @uiItemsCount.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách kiện hàng ({p0} kiện)'**
  String uiItemsCount(Object p0);

  /// No description provided for @uiTypeWeightKgItem.
  ///
  /// In vi, this message translates to:
  /// **'Loại: {p0} • Khối lượng: {p1} kg/kiện'**
  String uiTypeWeightKgItem(Object p0, Object p1);

  /// No description provided for @uiDimensions.
  ///
  /// In vi, this message translates to:
  /// **'Kích thước: {p0}'**
  String uiDimensions(Object p0);

  /// No description provided for @uiConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác nhận: {p0}'**
  String uiConfirmed(Object p0);

  /// No description provided for @uiPaysAtTheStationCounterWhenDroppingOff.
  ///
  /// In vi, this message translates to:
  /// **'{p0} thanh toán trực tiếp tại quầy bến xe khi gửi hoặc nhận hàng.'**
  String uiPaysAtTheStationCounterWhenDroppingOff(Object p0);

  /// No description provided for @uiDropOffDeadlinecb255c.
  ///
  /// In vi, this message translates to:
  /// **'Hạn mang hàng ra bến: {p0}'**
  String uiDropOffDeadlinecb255c(Object p0);

  /// No description provided for @uiItemCountdd0fa2.
  ///
  /// In vi, this message translates to:
  /// **'Số kiện: {p0}'**
  String uiItemCountdd0fa2(Object p0);

  /// No description provided for @uiFee.
  ///
  /// In vi, this message translates to:
  /// **'Cước: {p0}'**
  String uiFee(Object p0);

  /// No description provided for @uiOperator.
  ///
  /// In vi, this message translates to:
  /// **'Nhà xe: {p0}'**
  String uiOperator(Object p0);

  /// No description provided for @uiRecipient3b3790.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận: {p0}'**
  String uiRecipient3b3790(Object p0);

  /// No description provided for @uiItems930257.
  ///
  /// In vi, this message translates to:
  /// **'{p0} kiện'**
  String uiItems930257(Object p0);

  /// No description provided for @uiType81d219.
  ///
  /// In vi, this message translates to:
  /// **'Loại {p0}'**
  String uiType81d219(Object p0);

  /// No description provided for @uiRouteFeeEstimatesRates.
  ///
  /// In vi, this message translates to:
  /// **'Bảng cước tham khảo theo tuyến ({p0} mức)'**
  String uiRouteFeeEstimatesRates(Object p0);

  /// No description provided for @uiKg.
  ///
  /// In vi, this message translates to:
  /// **'≥ {p0} kg'**
  String uiKg(Object p0);

  /// No description provided for @uiImage.
  ///
  /// In vi, this message translates to:
  /// **'[Hình ảnh] {p0}'**
  String uiImage(Object p0);

  /// No description provided for @ui1FindTheRightTrip2SelectSeats.
  ///
  /// In vi, this message translates to:
  /// **'1. Tìm chuyến phù hợp\n2. Chọn ghế và thông tin hành trình\n3. Thanh toán và nhận vé'**
  String get ui1FindTheRightTrip2SelectSeats;

  /// No description provided for @uiCancelledOnRequest1422c3.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy theo yêu cầu'**
  String get uiCancelledOnRequest1422c3;

  /// No description provided for @uiOperatore2807c.
  ///
  /// In vi, this message translates to:
  /// **'nhà xe'**
  String get uiOperatore2807c;

  /// No description provided for @uiEarliestDeparture.
  ///
  /// In vi, this message translates to:
  /// **'Giờ đi sớm nhất'**
  String get uiEarliestDeparture;

  /// No description provided for @uiLatestDeparture.
  ///
  /// In vi, this message translates to:
  /// **'Giờ đi muộn nhất'**
  String get uiLatestDeparture;

  /// No description provided for @uiLowestFareFirst.
  ///
  /// In vi, this message translates to:
  /// **'Giá tăng dần'**
  String get uiLowestFareFirst;

  /// No description provided for @uiHighestFareFirst.
  ///
  /// In vi, this message translates to:
  /// **'Giá giảm dần'**
  String get uiHighestFareFirst;

  /// No description provided for @uiHighestRated.
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá cao nhất'**
  String get uiHighestRated;

  /// No description provided for @uiEarlyMorning00000600.
  ///
  /// In vi, this message translates to:
  /// **'Sáng sớm (00:00 - 06:00)'**
  String get uiEarlyMorning00000600;

  /// No description provided for @uiMorning06001200130f30.
  ///
  /// In vi, this message translates to:
  /// **'Buổi sáng (06:00 - 12:00)'**
  String get uiMorning06001200130f30;

  /// No description provided for @uiAfternoon12001800.
  ///
  /// In vi, this message translates to:
  /// **'Buổi chiều (12:00 - 18:00)'**
  String get uiAfternoon12001800;

  /// No description provided for @uiEvening18002400922d53.
  ///
  /// In vi, this message translates to:
  /// **'Buổi tối (18:00 - 24:00)'**
  String get uiEvening18002400922d53;

  /// No description provided for @uiWaitingForSupport.
  ///
  /// In vi, this message translates to:
  /// **'Chờ tiếp nhận'**
  String get uiWaitingForSupport;

  /// No description provided for @uiInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đang hỗ trợ'**
  String get uiInProgress;

  /// No description provided for @uiEnded.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết thúc'**
  String get uiEnded;

  /// No description provided for @uiUnsupportedStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái chưa hỗ trợ'**
  String get uiUnsupportedStatus;

  /// No description provided for @uiBusStation.
  ///
  /// In vi, this message translates to:
  /// **'Bến xe'**
  String get uiBusStation;

  /// No description provided for @uiOffice.
  ///
  /// In vi, this message translates to:
  /// **'Văn phòng'**
  String get uiOffice;

  /// No description provided for @uiShuttleTransfer.
  ///
  /// In vi, this message translates to:
  /// **'Trung chuyển'**
  String get uiShuttleTransfer;

  /// No description provided for @uiPickUpDropOffPoint.
  ///
  /// In vi, this message translates to:
  /// **'Điểm đón/trả'**
  String get uiPickUpDropOffPoint;

  /// No description provided for @uiThisTicketWasAlreadyCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Vé đã được hủy trước đó.'**
  String get uiThisTicketWasAlreadyCancelled;

  /// No description provided for @uiDepartureTimeIsUnavailableSoCancellationEligibilityCannot.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác định được giờ khởi hành để xét điều kiện hủy.'**
  String get uiDepartureTimeIsUnavailableSoCancellationEligibilityCannot;

  /// No description provided for @uiThisTripHasDepartedOnlineCancellationIsUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến xe đã khởi hành, không thể hủy trực tuyến.'**
  String get uiThisTripHasDepartedOnlineCancellationIsUnavailable;

  /// No description provided for @uiTheOnlineCancellationDeadlineHasPassed.
  ///
  /// In vi, this message translates to:
  /// **'Đã qua thời hạn hủy trực tuyến của chuyến xe.'**
  String get uiTheOnlineCancellationDeadlineHasPassed;

  /// No description provided for @uiThisBookingHasAnActiveAccompanyingShipmentContact.
  ///
  /// In vi, this message translates to:
  /// **'Đơn có hàng gửi kèm còn hiệu lực. Vui lòng liên hệ nhà xe.'**
  String get uiThisBookingHasAnActiveAccompanyingShipmentContact;

  /// No description provided for @uiThisTicketIsNotEligibleForOnlineCancellation370dc5.
  ///
  /// In vi, this message translates to:
  /// **'Vé hiện không đủ điều kiện hủy trực tuyến. Vui lòng liên hệ nhà xe.'**
  String get uiThisTicketIsNotEligibleForOnlineCancellation370dc5;

  /// No description provided for @uiVexgoOnlineBusBooking.
  ///
  /// In vi, this message translates to:
  /// **'VexGo - Đặt vé xe khách trực tuyến'**
  String get uiVexgoOnlineBusBooking;

  /// No description provided for @uiYouHaveANewTicketUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có cập nhật mới về vé.'**
  String get uiYouHaveANewTicketUpdate;

  /// No description provided for @uiLanguageChangedForThisSessionUnableToSave.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi ngôn ngữ cho phiên này. Chưa lưu được lựa chọn.'**
  String get uiLanguageChangedForThisSessionUnableToSave;

  /// No description provided for @ui1PaymentForThisBookingIsConfirmed2ff0c49.
  ///
  /// In vi, this message translates to:
  /// **'1. Đơn hàng đã được xác nhận thanh toán thành công.\n2. Nếu danh sách vé chưa hiển thị hoặc đang đồng bộ, vui lòng nhấn nút \"Kiểm tra kết quả thanh toán\" ở thanh bên dưới.\n3. Bạn cũng có thể tra cứu lại vé bất kỳ lúc nào trong mục \"Vé của tôi\" bằng số điện thoại đặt vé.'**
  String get ui1PaymentForThisBookingIsConfirmed2ff0c49;

  /// No description provided for @ui1DoNotTransferMoneyForThisBooking4ec818.
  ///
  /// In vi, this message translates to:
  /// **'1. Vui lòng không thực hiện chuyển khoản cho đơn hàng này.\n2. Nếu bạn đã chuyển khoản trước khi đơn hết hạn, nhấn \"Kiểm tra kết quả thanh toán\" để hệ thống đối soát.\n3. Trường hợp cần trợ giúp hoặc đã trừ tiền nhưng chưa có vé, vui lòng liên hệ tổng đài VexGo để được hỗ trợ.'**
  String get ui1DoNotTransferMoneyForThisBooking4ec818;

  /// No description provided for @ui1OpenYourBankingAppAndTransferThea659be.
  ///
  /// In vi, this message translates to:
  /// **'1. Mở ứng dụng ngân hàng và chuyển khoản đúng số tiền cùng nội dung chuyển khoản.\n2. Nhấn nút \"Kiểm tra kết quả thanh toán\" ở thanh bên dưới.\n3. Vé được hiển thị sau khi hệ thống xác nhận thanh toán và đồng bộ đầy đủ.'**
  String get ui1OpenYourBankingAppAndTransferThea659be;

  /// No description provided for @uiUnableToLoadSuggestionsYouCanStillEnter.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được câu hỏi gợi ý. Bạn vẫn có thể nhập câu hỏi.'**
  String get uiUnableToLoadSuggestionsYouCanStillEnter;

  /// No description provided for @uiEnterAQuestionBetween1And2000.
  ///
  /// In vi, this message translates to:
  /// **'Nhập câu hỏi từ 1 đến 2.000 ký tự.'**
  String get uiEnterAQuestionBetween1And2000;

  /// No description provided for @uiYourSessionHasExpiredSignInAgain.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'**
  String get uiYourSessionHasExpiredSignInAgain;

  /// No description provided for @uiYouAreSendingTooQuicklyWaitAndTry.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang gửi quá nhanh. Vui lòng chờ rồi thử lại.'**
  String get uiYouAreSendingTooQuicklyWaitAndTry;

  /// No description provided for @uiUnableToSendYourQuestionCheckAndTry.
  ///
  /// In vi, this message translates to:
  /// **'Chưa gửi được câu hỏi. Vui lòng kiểm tra và thử lại.'**
  String get uiUnableToSendYourQuestionCheckAndTry;

  /// No description provided for @uiNoHistoryWasFoundForThisSession.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tìm thấy lịch sử phiên này.'**
  String get uiNoHistoryWasFoundForThisSession;

  /// No description provided for @uiUnableToLoadHistoryYourLocalConversationIs.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được lịch sử. Hội thoại trên máy vẫn được giữ.'**
  String get uiUnableToLoadHistoryYourLocalConversationIs;

  /// No description provided for @uiInvalidRoundTripPaymentCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã thanh toán khứ hồi không hợp lệ.'**
  String get uiInvalidRoundTripPaymentCode;

  /// No description provided for @uiTheTripsHaveIncorrectRoutesDatesOrOverlapping.
  ///
  /// In vi, this message translates to:
  /// **'Hai chuyến không đúng tuyến/ngày hoặc thời gian bị chồng lấn.'**
  String get uiTheTripsHaveIncorrectRoutesDatesOrOverlapping;

  /// No description provided for @uiRoundTripsRequireAnApiConnectionDemoTickets.
  ///
  /// In vi, this message translates to:
  /// **'Khứ hồi yêu cầu repository API, không tạo vé demo.'**
  String get uiRoundTripsRequireAnApiConnectionDemoTickets;

  /// No description provided for @uiCheckTheExistingLegBeforeContinuingWithThe.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra lại chặng đã tạo trước khi tiếp tục chặng còn lại.'**
  String get uiCheckTheExistingLegBeforeContinuingWithThe;

  /// No description provided for @uiCompleteSeatsStopsPassengerDetailsAndQuotesFor.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất ghế, đón/trả, hành khách và báo giá của cả hai chiều.'**
  String get uiCompleteSeatsStopsPassengerDetailsAndQuotesFor;

  /// No description provided for @uiTheLegDetailsDoNotMatchNoBooking.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin hai chặng không khớp. Không gửi yêu cầu tạo đơn.'**
  String get uiTheLegDetailsDoNotMatchNoBooking;

  /// No description provided for @uiInvalidRoundTripPair.
  ///
  /// In vi, this message translates to:
  /// **'Cặp chuyến khứ hồi không hợp lệ.'**
  String get uiInvalidRoundTripPair;

  /// No description provided for @uiInvalidRouteTravelDatesOrTicketCount.
  ///
  /// In vi, this message translates to:
  /// **'Tuyến, ngày đi/về hoặc số vé không hợp lệ.'**
  String get uiInvalidRouteTravelDatesOrTicketCount;

  /// No description provided for @uiUnableToVerifyServerDataCheckYourConnection.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xác minh dữ liệu từ máy chủ. Vui lòng kiểm tra kết nối và thử tải lại.'**
  String get uiUnableToVerifyServerDataCheckYourConnection;

  /// No description provided for @uiThisRouteDoesNotHaveEnoughDropOff.
  ///
  /// In vi, this message translates to:
  /// **'Tuyến chưa có đủ điểm gửi và nhận.'**
  String get uiThisRouteDoesNotHaveEnoughDropOff;

  /// No description provided for @uiCheckTheRouteShippingDateAndItemDetails.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra tuyến, ngày gửi và thông tin kiện hàng.'**
  String get uiCheckTheRouteShippingDateAndItemDetails;

  /// No description provided for @uiEnterShippingDetails.
  ///
  /// In vi, this message translates to:
  /// **'Nhập thông tin gửi hàng.'**
  String get uiEnterShippingDetails;

  /// No description provided for @uiLoadShippingOptionsForTheCorrectRoute.
  ///
  /// In vi, this message translates to:
  /// **'Cần tải cấu hình nhận hàng của đúng tuyến.'**
  String get uiLoadShippingOptionsForTheCorrectRoute;

  /// No description provided for @uiTheDropOffPointIsNotOnThe.
  ///
  /// In vi, this message translates to:
  /// **'Điểm gửi không thuộc tuyến đã chọn.'**
  String get uiTheDropOffPointIsNotOnThe;

  /// No description provided for @uiTheCollectionPointIsNotOnTheSelected.
  ///
  /// In vi, this message translates to:
  /// **'Điểm nhận không thuộc tuyến đã chọn.'**
  String get uiTheCollectionPointIsNotOnTheSelected;

  /// No description provided for @uiThisItemTypeIsNoLongerValid.
  ///
  /// In vi, this message translates to:
  /// **'Loại hàng không còn hợp lệ.'**
  String get uiThisItemTypeIsNoLongerValid;

  /// No description provided for @uiTheShippingDateHasChangedSearchRoutesAgain.
  ///
  /// In vi, this message translates to:
  /// **'Ngày gửi đã thay đổi; tìm lại tuyến.'**
  String get uiTheShippingDateHasChangedSearchRoutesAgain;

  /// No description provided for @uiRequestANewQuoteForTheCurrentDetails.
  ///
  /// In vi, this message translates to:
  /// **'Cần báo giá lại cho thông tin hiện tại.'**
  String get uiRequestANewQuoteForTheCurrentDetails;

  /// No description provided for @uiShipmentCreationIsUnconfirmedDoNotCreateIt.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác minh kết quả tạo đơn. Không tạo lại; hãy tra cứu vận đơn hoặc liên hệ hỗ trợ.'**
  String get uiShipmentCreationIsUnconfirmedDoNotCreateIt;

  /// No description provided for @uiTheReturnedStatusBelongsToAnotherShipment.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái trả về thuộc đơn khác.'**
  String get uiTheReturnedStatusBelongsToAnotherShipment;

  /// No description provided for @uiCancellationReasonMustBeAtMost255Characters.
  ///
  /// In vi, this message translates to:
  /// **'Lý do hủy tối đa 255 ký tự.'**
  String get uiCancellationReasonMustBeAtMost255Characters;

  /// No description provided for @uiCancellationIsUnconfirmedCheckStatusDoNotResubmit.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác minh kết quả hủy. Hãy kiểm tra trạng thái; không gửi lại yêu cầu.'**
  String get uiCancellationIsUnconfirmedCheckStatusDoNotResubmit;

  /// No description provided for @uiUnableToLoadConversationsTryAgain.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được hội thoại. Vui lòng thử lại.'**
  String get uiUnableToLoadConversationsTryAgain;

  /// No description provided for @uiUnableToOpenAConversationWithTheOperator.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được hội thoại với nhà xe.'**
  String get uiUnableToOpenAConversationWithTheOperator;

  /// No description provided for @uiUnableToLoadMessagesPullToRetry.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được tin nhắn. Kéo để thử lại.'**
  String get uiUnableToLoadMessagesPullToRetry;

  /// No description provided for @uiTheConfirmedMessageDoesNotMatch.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn xác nhận không khớp.'**
  String get uiTheConfirmedMessageDoesNotMatch;

  /// No description provided for @uiUnableToEndTheConversationRefreshAndTry.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể kết thúc hội thoại. Vui lòng tải lại.'**
  String get uiUnableToEndTheConversationRefreshAndTry;

  /// No description provided for @uiLiveChatWasInterruptedUsingTheApiTo.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối chat bị gián đoạn. Đang dùng API để đồng bộ.'**
  String get uiLiveChatWasInterruptedUsingTheApiTo;

  /// No description provided for @uiChatDataIsInvalidRefreshAndTryAgain.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu chat chưa hợp lệ. Vui lòng tải lại.'**
  String get uiChatDataIsInvalidRefreshAndTryAgain;

  /// No description provided for @uiTripNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy chuyến xe.'**
  String get uiTripNotFound;

  /// No description provided for @uiUnableToLoadTripDetailsTryAgain.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải chi tiết chuyến xe. Vui lòng thử lại.'**
  String get uiUnableToLoadTripDetailsTryAgain;

  /// No description provided for @uiThisBookingBelongsToAnotherAccountSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Đơn này thuộc tài khoản khác. Vui lòng đăng nhập đúng tài khoản đặt vé.'**
  String get uiThisBookingBelongsToAnotherAccountSignIn;

  /// No description provided for @uiReceiptNotFoundOrTheCodePhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy chứng từ hoặc mã/số điện thoại không khớp.'**
  String get uiReceiptNotFoundOrTheCodePhoneNumber;

  /// No description provided for @uiUnableToConnectToTheServerTryAgain.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối máy chủ. Vui lòng thử lại.'**
  String get uiUnableToConnectToTheServerTryAgain;

  /// No description provided for @uiUnableToLoadAValidReceiptCheckYour.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải chứng từ hợp lệ. Vui lòng kiểm tra thông tin và thử lại.'**
  String get uiUnableToLoadAValidReceiptCheckYour;

  /// No description provided for @uiAccountCreatedSuccessfully.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký tài khoản thành công!'**
  String get uiAccountCreatedSuccessfully;

  /// No description provided for @uiProfileUpdatedSuccessfully.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật thông tin cá nhân thành công!'**
  String get uiProfileUpdatedSuccessfully;

  /// No description provided for @uiEnterYourCurrentPasswordAndADifferentNew.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu cũ và mật khẩu mới khác, dài 8–72 byte UTF-8.'**
  String get uiEnterYourCurrentPasswordAndADifferentNew;

  /// No description provided for @uiSwitchedToVietnamese.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi sang Tiếng Việt'**
  String get uiSwitchedToVietnamese;

  /// No description provided for @uiSignInToEnablePushNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng đăng nhập để bật thông báo đẩy.'**
  String get uiSignInToEnablePushNotifications;

  /// No description provided for @uiPushNotificationsDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Đã tắt thông báo đẩy'**
  String get uiPushNotificationsDisabled;

  /// No description provided for @uiPushNotificationsEnabled.
  ///
  /// In vi, this message translates to:
  /// **'Đã bật thông báo đẩy'**
  String get uiPushNotificationsEnabled;

  /// No description provided for @uiUnableToEnableNotificationsCheckNotificationPermissionAnd.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể bật thông báo. Kiểm tra quyền thông báo và cấu hình bản cài.'**
  String get uiUnableToEnableNotificationsCheckNotificationPermissionAnd;

  /// No description provided for @uiThePreviousCancellationIsUnconfirmedCheckStatusOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác minh kết quả hủy trước đó. Chỉ kiểm tra trạng thái, không gửi lại yêu cầu.'**
  String get uiThePreviousCancellationIsUnconfirmedCheckStatusOnly;

  /// No description provided for @uiTheFeeOrCancellationReasonIsInvalidRefresh.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin phí hoặc lý do hủy chưa hợp lệ. Vui lòng tải lại và xác nhận.'**
  String get uiTheFeeOrCancellationReasonIsInvalidRefresh;

  /// No description provided for @uiConfirmingTicketCancellation.
  ///
  /// In vi, this message translates to:
  /// **'Đang xác nhận yêu cầu hủy vé...'**
  String get uiConfirmingTicketCancellation;

  /// No description provided for @uiUnableToVerifyTheTicketToCancel.
  ///
  /// In vi, this message translates to:
  /// **'Không xác minh được vé cần hủy.'**
  String get uiUnableToVerifyTheTicketToCancel;

  /// No description provided for @uiCancellationFeesOrTicketDetailsHaveChangedReview.
  ///
  /// In vi, this message translates to:
  /// **'Phí hủy hoặc thông tin vé đã thay đổi. Vui lòng xem và đồng ý lại.'**
  String get uiCancellationFeesOrTicketDetailsHaveChangedReview;

  /// No description provided for @uiTheCancellationResponseDoesNotMatchThisTicket.
  ///
  /// In vi, this message translates to:
  /// **'Phản hồi hủy không khớp vé.'**
  String get uiTheCancellationResponseDoesNotMatchThisTicket;

  /// No description provided for @uiTicketCancellationConfirmedContactSupportWithYourTicket.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác nhận vé bị hủy. Vui lòng liên hệ hỗ trợ và cung cấp mã vé để yêu cầu hoàn tiền; hệ thống không hoàn tiền online.'**
  String get uiTicketCancellationConfirmedContactSupportWithYourTicket;

  /// No description provided for @uiTicketCancellationIsUnconfirmedCheckStatusDoNot.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác minh kết quả hủy vé. Vui lòng kiểm tra trạng thái; không gửi lại yêu cầu.'**
  String get uiTicketCancellationIsUnconfirmedCheckStatusDoNot;

  /// No description provided for @uiTheCancellationFeeHasChangedReviewAndAgree.
  ///
  /// In vi, this message translates to:
  /// **'Phí hủy đã thay đổi. Vui lòng xem và đồng ý lại mức phí mới.'**
  String get uiTheCancellationFeeHasChangedReviewAndAgree;

  /// No description provided for @uiUnableToCancelTheTicketRefreshItsDetails.
  ///
  /// In vi, this message translates to:
  /// **'Không thể hủy vé. Vui lòng tải lại thông tin và xác nhận mức phí.'**
  String get uiUnableToCancelTheTicketRefreshItsDetails;

  /// No description provided for @uiCheckingTicketStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra trạng thái vé...'**
  String get uiCheckingTicketStatus;

  /// No description provided for @uiTicketCancellationIsUnconfirmedCheckAgainLaterDo.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác minh kết quả hủy vé. Vui lòng kiểm tra lại sau; không gửi lại yêu cầu.'**
  String get uiTicketCancellationIsUnconfirmedCheckAgainLaterDo;

  /// No description provided for @uiTheTicketToCancelWasNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy thông tin vé cần hủy.'**
  String get uiTheTicketToCancelWasNotFound;

  /// No description provided for @uiCancellationIsUnavailableBecauseDepartureIsWithin12.
  ///
  /// In vi, this message translates to:
  /// **'Không thể hủy vé vì chuyến xe khởi hành trong vòng dưới 12 giờ (dưới 3 giờ theo quy định tối thiểu nhà xe)! Vui lòng liên hệ tổng đài để được trợ giúp.'**
  String get uiCancellationIsUnavailableBecauseDepartureIsWithin12;

  /// No description provided for @uiUnableToIdentifyTheTripForReviewManagement.
  ///
  /// In vi, this message translates to:
  /// **'Không xác định được chuyến xe để quản lý đánh giá.'**
  String get uiUnableToIdentifyTheTripForReviewManagement;

  /// No description provided for @uiThereAreMultipleReviewsForThisTripThe.
  ///
  /// In vi, this message translates to:
  /// **'Có nhiều đánh giá cho chuyến này; chưa xác định được đánh giá cần thay đổi.'**
  String get uiThereAreMultipleReviewsForThisTripThe;

  /// No description provided for @uiReviewRefreshed.
  ///
  /// In vi, this message translates to:
  /// **'Đã tải lại đánh giá.'**
  String get uiReviewRefreshed;

  /// No description provided for @uiThisReviewNoLongerExistsRefreshTheDetails.
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá không còn tồn tại. Hãy tải lại thông tin.'**
  String get uiThisReviewNoLongerExistsRefreshTheDetails;

  /// No description provided for @uiNoProvincesOrCitiesAreAvailableYetd92974.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tỉnh/thành phố khả dụng.'**
  String get uiNoProvincesOrCitiesAreAvailableYetd92974;

  /// No description provided for @uiItemsWithTicketsRequireALiveApiAnd.
  ///
  /// In vi, this message translates to:
  /// **'Gửi hàng kèm vé yêu cầu API thật và mã chuyến hợp lệ.'**
  String get uiItemsWithTicketsRequireALiveApiAnd;

  /// No description provided for @uiTheDropOffCollectionPointDoesNotBelong.
  ///
  /// In vi, this message translates to:
  /// **'Điểm gửi/nhận không thuộc chuyến hiện tại.'**
  String get uiTheDropOffCollectionPointDoesNotBelong;

  /// No description provided for @uiUnableToVerifyShippingServiceRefreshOrTurn.
  ///
  /// In vi, this message translates to:
  /// **'Không xác minh được dịch vụ gửi hàng. Thử tải lại hoặc tắt gửi hàng để chỉ đặt vé.'**
  String get uiUnableToVerifyShippingServiceRefreshOrTurn;

  /// No description provided for @uiBookingDetailsHaveChangedUpdateTheFare.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin đặt vé đã thay đổi. Vui lòng cập nhật giá.'**
  String get uiBookingDetailsHaveChangedUpdateTheFare;

  /// No description provided for @uiTheServerHasNotVerifiedThisPromoCode.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa xác thực mã khuyến mãi cho thông tin liên hệ hiện tại.'**
  String get uiTheServerHasNotVerifiedThisPromoCode;

  /// No description provided for @uiTheFareOrPromoCodeIsUnverifiedUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác minh được giá vé hoặc mã khuyến mãi. Vui lòng cập nhật giá.'**
  String get uiTheFareOrPromoCodeIsUnverifiedUpdate;

  /// No description provided for @uiYourSeatHoldHasExpiredSelectSeatsAgain.
  ///
  /// In vi, this message translates to:
  /// **'Hết thời gian giữ ghế. Vui lòng chọn lại chỗ ngồi.'**
  String get uiYourSeatHoldHasExpiredSelectSeatsAgain;

  /// No description provided for @uiInvalidTripDetails.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin chuyến đi không hợp lệ.'**
  String get uiInvalidTripDetails;

  /// No description provided for @uiInvalidSeatList.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách ghế không hợp lệ.'**
  String get uiInvalidSeatList;

  /// No description provided for @uiYourSeatHoldHasExpiredSelectSeatsAgain95d9a4.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian giữ chỗ đã hết hạn. Vui lòng chọn lại ghế.'**
  String get uiYourSeatHoldHasExpiredSelectSeatsAgain95d9a4;

  /// No description provided for @uiUnableToHoldThisSeatTryAgain.
  ///
  /// In vi, this message translates to:
  /// **'Không thể giữ chỗ ngồi này. Vui lòng thử lại.'**
  String get uiUnableToHoldThisSeatTryAgain;

  /// No description provided for @uiSeatReleaseCouldNotBeConfirmedTryAgain.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác nhận được việc giải phóng ghế. Vui lòng thử lại.'**
  String get uiSeatReleaseCouldNotBeConfirmedTryAgain;

  /// No description provided for @uiUnableToReleaseSeatsDueToAConnection.
  ///
  /// In vi, this message translates to:
  /// **'Không thể giải phóng ghế do lỗi kết nối. Vui lòng thử lại.'**
  String get uiUnableToReleaseSeatsDueToAConnection;

  /// No description provided for @uiBookingResultIsUnconfirmedDoNotResubmitCheck.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả tạo đơn chưa xác định. Không gửi lại yêu cầu; vui lòng kiểm tra Vé của tôi hoặc liên hệ hỗ trợ.'**
  String get uiBookingResultIsUnconfirmedDoNotResubmitCheck;

  /// No description provided for @uiCompletePassengerDetailsAndHoldSeatsBeforePaying.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng hoàn tất thông tin hành khách và giữ chỗ trước khi thanh toán.'**
  String get uiCompletePassengerDetailsAndHoldSeatsBeforePaying;

  /// No description provided for @uiShippingIsUnavailableInDemoMode.
  ///
  /// In vi, this message translates to:
  /// **'Gửi hàng chưa hỗ trợ Demo Mode.'**
  String get uiShippingIsUnavailableInDemoMode;

  /// No description provided for @uiTheVietqrReceivingAccountIsNotConfiguredContact.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có cấu hình tài khoản nhận VietQR. Vui lòng liên hệ hỗ trợ.'**
  String get uiTheVietqrReceivingAccountIsNotConfiguredContact;

  /// No description provided for @uiTheServerDidNotReturnAValidBooking.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ không trả mã đơn hợp lệ.'**
  String get uiTheServerDidNotReturnAValidBooking;

  /// No description provided for @uiTheServerHasNotConfirmedTheRoundTrip.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa xác nhận mã thanh toán khứ hồi. Giữ đơn hiện tại để kiểm tra.'**
  String get uiTheServerHasNotConfirmedTheRoundTrip;

  /// No description provided for @uiSeparateStationFeesAndItemDetailsAreUnconfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa xác nhận cước riêng tại bến và thông tin vật phẩm. Giữ đơn hiện tại để kiểm tra.'**
  String get uiSeparateStationFeesAndItemDetailsAreUnconfirmed;

  /// No description provided for @uiPaymentBookingDetailsDoNotMatch.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin đơn thanh toán không khớp.'**
  String get uiPaymentBookingDetailsDoNotMatch;

  /// No description provided for @uiTransferTheExactAmountWithTheBookingReference.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển khoản đúng số tiền và nội dung mã đơn. Hệ thống sẽ xác minh thanh toán; nhấn kiểm tra lại sau khi chuyển khoản.'**
  String get uiTransferTheExactAmountWithTheBookingReference;

  /// No description provided for @uiTicketsCannotBeIssuedYetOrThisBooking.
  ///
  /// In vi, this message translates to:
  /// **'Đơn chưa đủ điều kiện xuất vé, đã hết hạn hoặc bị hủy. Vui lòng liên hệ hỗ trợ nếu đã chuyển tiền.'**
  String get uiTicketsCannotBeIssuedYetOrThisBooking;

  /// No description provided for @uiTheServerReturnedInvalidPaymentDetails.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ trả thông tin thanh toán không hợp lệ.'**
  String get uiTheServerReturnedInvalidPaymentDetails;

  /// No description provided for @uiTheServerSupportsTestPaymentsOnlyLivePayment.
  ///
  /// In vi, this message translates to:
  /// **'BLOCKED_BY_BACKEND: Máy chủ chỉ hỗ trợ cổng thanh toán thử nghiệm, chưa hỗ trợ thanh toán thực tế.'**
  String get uiTheServerSupportsTestPaymentsOnlyLivePayment;

  /// No description provided for @uiThePaymentResultDoesNotMatchThisBooking.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả thanh toán không khớp với đơn hiện tại.'**
  String get uiThePaymentResultDoesNotMatchThisBooking;

  /// No description provided for @uiPaymentIsPendingCompleteItWithThePayment.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán đang chờ xử lý. Hoàn tất tại cổng thanh toán rồi kiểm tra lại.'**
  String get uiPaymentIsPendingCompleteItWithThePayment;

  /// No description provided for @uiPaymentFailedTheCurrentBookingAndTransactionAre.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán không thành công. Đơn và giao dịch hiện tại được giữ để kiểm tra, không tạo lại đơn.'**
  String get uiPaymentFailedTheCurrentBookingAndTransactionAre;

  /// No description provided for @uiThePaymentProviderIsUnavailableOnTheServer.
  ///
  /// In vi, this message translates to:
  /// **'BLOCKED_BY_BACKEND: Cổng thanh toán chưa khả dụng trên máy chủ. Đơn hiện tại được giữ để kiểm tra.'**
  String get uiThePaymentProviderIsUnavailableOnTheServer;

  /// No description provided for @uiAConnectionErrorLeftTheBookingResultUnconfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả tạo đơn chưa xác định do lỗi kết nối. Không gửi lại yêu cầu; kiểm tra Vé của tôi hoặc liên hệ hỗ trợ.'**
  String get uiAConnectionErrorLeftTheBookingResultUnconfirmed;

  /// No description provided for @uiPaymentOrTicketsAreUnverifiedCheckTheCurrent.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác minh được thanh toán hoặc vé. Vui lòng kiểm tra lại đơn hiện tại.'**
  String get uiPaymentOrTicketsAreUnverifiedCheckTheCurrent;

  /// No description provided for @uiSelectSeats2828b0.
  ///
  /// In vi, this message translates to:
  /// **'Chọn chỗ ngồi'**
  String get uiSelectSeats2828b0;

  /// No description provided for @uiCheckExistingBookings.
  ///
  /// In vi, this message translates to:
  /// **'Cần kiểm tra các đơn trước'**
  String get uiCheckExistingBookings;

  /// No description provided for @uiTooManyRequests.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang thao tác quá nhanh'**
  String get uiTooManyRequests;

  /// No description provided for @uiThisPhoneNumberOrAccountHasMultipleUnpaid.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại hoặc tài khoản đang có nhiều đơn chưa thanh toán hoặc lượt giữ chỗ hết hạn. Vui lòng kiểm tra các đơn trước hoặc quay lại sau 30 phút theo hướng dẫn của hệ thống.'**
  String get uiThisPhoneNumberOrAccountHasMultipleUnpaid;

  /// No description provided for @uiRequestsAreTemporarilyLimitedWaitAWhileAnd.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống đang tạm giới hạn số lần thao tác. Vui lòng chờ một lúc rồi thử lại.'**
  String get uiRequestsAreTemporarilyLimitedWaitAWhileAnd;

  /// No description provided for @uiInvalidTripPassengerCountOrPolicyValidityPeriod.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến/số hành khách/thời hạn chính sách không hợp lệ.'**
  String get uiInvalidTripPassengerCountOrPolicyValidityPeriod;

  /// No description provided for @uiYourSessionHasChangedOpenLuggageAgain.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đã thay đổi. Vui lòng mở lại hành lý.'**
  String get uiYourSessionHasChangedOpenLuggageAgain;

  /// No description provided for @uiLuggageBelongsToADifferentTrip.
  ///
  /// In vi, this message translates to:
  /// **'Sai chuyến hành lý.'**
  String get uiLuggageBelongsToADifferentTrip;

  /// No description provided for @uiUnableToLoadTheLuggagePolicyRetryOr.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được chính sách hành lý. Thử lại hoặc bỏ qua để chỉ đặt vé.'**
  String get uiUnableToLoadTheLuggagePolicyRetryOr;

  /// No description provided for @uiYourLuggageSessionHasChanged.
  ///
  /// In vi, this message translates to:
  /// **'Phiên hành lý đã thay đổi.'**
  String get uiYourLuggageSessionHasChanged;

  /// No description provided for @uiLoadingLuggagePolicy.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải chính sách hành lý.'**
  String get uiLoadingLuggagePolicy;

  /// No description provided for @uiTheLuggagePolicyIsOutdatedRefreshIt.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách hành lý đã cũ. Vui lòng tải lại.'**
  String get uiTheLuggagePolicyIsOutdatedRefreshIt;

  /// No description provided for @uiLuggageDoesNotMatchTheCurrentTripPassenger.
  ///
  /// In vi, this message translates to:
  /// **'Hành lý không thuộc chuyến/số khách hiện tại.'**
  String get uiLuggageDoesNotMatchTheCurrentTripPassenger;

  /// No description provided for @uiEnterAValidVietnamesePhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số điện thoại Việt Nam hợp lệ.'**
  String get uiEnterAValidVietnamesePhoneNumber;

  /// No description provided for @uiPasswordMustBe8To72Utf8.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải dài từ 8 đến 72 byte UTF-8.'**
  String get uiPasswordMustBe8To72Utf8;

  /// No description provided for @uiTheVerificationCodeMustHave6Digits.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP phải gồm 6 chữ số.'**
  String get uiTheVerificationCodeMustHave6Digits;

  /// No description provided for @uiUnableToConnectToTheServerCheckYour.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.'**
  String get uiUnableToConnectToTheServerCheckYour;

  /// No description provided for @uiDone.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get uiDone;

  /// No description provided for @uiDurationHoursMinutes.
  ///
  /// In vi, this message translates to:
  /// **'{hours} giờ {minutes} phút'**
  String uiDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @uiDurationHours.
  ///
  /// In vi, this message translates to:
  /// **'{hours} giờ'**
  String uiDurationHours(int hours);

  /// No description provided for @uiDurationMinutes.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút'**
  String uiDurationMinutes(int minutes);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
