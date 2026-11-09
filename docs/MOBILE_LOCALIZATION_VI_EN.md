# Mobile Việt–Anh

Triển khai ngày 08–09/11/2026. Branch `feature/mobile-vi-en`, worktree `vexgo_localization_worktree`.

## Phạm vi và cách dùng

Tài khoản → Ngôn ngữ → Tiếng Việt / English. Đổi ngay trong app và lưu lựa chọn cho thiết bị. Lần đầu hoặc preference không hỗ trợ dùng tiếng Việt. Lựa chọn độc lập với tài khoản, không bị logout làm mất. Nếu lưu preference thất bại, giữ ngôn ngữ cho phiên hiện tại và báo cho người dùng.

Giao diện được chuyển sang ARB ở các nhóm Trang chủ/tìm chuyến, tài khoản/đăng nhập/OTP/quên mật khẩu, đặt vé/chọn ghế/đón trả/hành khách/mã ưu đãi/thanh toán/thành công, khứ hồi/hành lý, Vé của tôi/chi tiết/hủy/đánh giá/chứng từ, gửi hàng và chat hỗ trợ/AI. Các nhãn trạng thái do client ánh xạ cũng dịch ở presentation, không đổi enum/payload gửi API.

Tên người/nhà xe/địa điểm/địa chỉ, nội dung chat, câu trả lời và gợi ý do AI/Backend gửi, chính sách/tiện ích và thông báo/email từ Backend giữ nguyên. Không tự dịch các nội dung đó và không gửi dữ liệu sang dịch vụ dịch bên ngoài. Các lỗi Backend chưa có bản dịch trong catalog được giữ nguyên, không thay bằng thông báo thành công hoặc thông tin suy đoán.

Ngày vẫn rõ dạng ngày/tháng/năm, tên thứ thay theo ngôn ngữ. Chuyến/điểm đón giữ cách tính giờ hiện có. Tiền luôn VND; tiếng Việt dùng 260.000 đ, tiếng Anh dùng VND 260,000. Không đổi tỷ giá, đơn vị API, hạn giữ ghế hay số tiền thanh toán. Trình chọn ngày và nút chuẩn Material dùng delegate chính thức.

## Nguồn và cấu trúc

- `lib/l10n/app_vi.arb`, `app_en.arb`: nguồn bản dịch, bao gồm placeholder cho dữ liệu runtime. Không nối câu bằng cách dịch dữ liệu người dùng.
- `l10n.yaml`, `pubspec.yaml`: Flutter gen-l10n, flutter_localizations từ SDK. Flutter3.38.7 đang pin intl0.20.2; hạ từ0.20.3 theo SDK, không nâng Flutter/các package khác.
- `lib/l10n/app_localizations*.dart`: code sinh từ `flutter gen-l10n`, không sửa tay.
- `lib/core/localization/locale_controller.dart`: locale thiết bị và SharedPreferences `vexgo.ui.locale.v1`. Serialize ghi preference để lần chọn cuối cùng thắng; không lưu credential. Khởi tạo trong main trước runApp.
- `MaterialApp.router` lắng nghe locale nhưng dùng router/provider hiện có, không gán key theo locale. Không khởi tạo lại AuthBloc, HomeBloc, booking flow hoặc TextEditingController để đổi ngôn ngữ.
- Widget lấy `context.l10n`; helper không có context dùng `LocaleController.strings`. Test widget cô lập chưa cài delegate vẫn mặc định vi. Ưu tiên context ở mã UI mới để đăng ký phụ thuộc locale.
- `client_labels.dart` là adapter render-only cho nhãn/lỗi client cũ lưu dạng string. Sinh bằng `python tool/generate_client_labels.py` từ ARB. Không dùng cho tên nhà xe/địa chỉ/nội dung chat hay quy chế Backend. Không dùng bản dịch để so sánh trạng thái/enum hoặc làm giá trị lựa chọn gửi API.

Thêm/sửa bản dịch: cập nhật cả hai ARB cùng key và placeholder, chạy `flutter gen-l10n`, `python tool/generate_client_labels.py`, rồi `dart format lib/l10n lib/core/localization/client_labels.dart`. Dùng key có nghĩa, không sửa file generated trực tiếp.

## Tương thích và thay đổi bố cục

- Tab Đơn của tôi dùng index thay cho so sánh tiêu đề tiếng Việt. Bộ lọc, enum và lý do hủy giữ giá trị ban đầu; chỉ nhãn hiển thị dịch.
- Điều kiện đọc lỗi hết hạn giữ nguyên theo message source trước đây, không so sánh với bản dịch.
- Thông tin vùng dưới tên thành phố trong search form để màn320dp/chữ2x không bị chip tràn. Tên thành phố không bị dịch.
- Không đọc Localizations trong initState; các giá trị cảnh báo khởi tạo dùng locale controller.

## Checkout nền và giới hạn

Worktree được tạo từ commit `86a909f` rồi sao chép nguyên các sửa local đang có ở nhánh hành lý. Đây là snapshot tích hợp còn chứa các thay đổi nền chưa commit của hành lý/khứ hồi/gửi hàng/đánh giá/chứng từ. Không coi toàn bộ `git diff HEAD` là diff riêng của localization, không gom commit tất cả khi chưa đối chiếu. Worktree gốc được giữ nguyên.

Evidence và diff riêng so với snapshot nguồn: `mobile-qa-evidence/localization-20261108/changed-files.json`, `localization-only.patch`. Không thay code Backend, migration, DB, API đang chạy, APK/shortcut báo cáo hoặc gói hành lý dự phòng. Đã chốt snapshot nền tại `643b53d` trên nhánh `feature/mobile-backend-sync-luggage-ai`. PR Việt–Anh target nhánh nền này để reviewer chỉ thấy localization; sau khi PR nền và các PR cha được merge, retarget sang develop và kiểm tra diff/CI. Không merge các PR không đúng thứ tự.

## Kiểm chứng

Các kết quả cuối được ghi tại `mobile-qa-evidence/localization-20261108/`: `localization-final-v2.log` (10/10 test localization), `analyze-release.log` (analyze sạch), `regression-final.log` (981/981 test Flutter qua). Các log lần đầu có lỗi và đã được giữ để đối chiếu, không dùng làm kết quả chốt.

Test mới kiểm tra chọn/lưu/khôi phục preference, chọn nhanh nhiều lần, fallback ngôn ngữ lạ, parity key/placeholder ARB, VND và weekday, delegate Material, giữ nguyên controller/tên người/payload hành khách, giữ HomeBloc/city/date khi đổi locale và chuyển route, UI320dp với chữ2x và landscape. Không gọi dịch vụ Backend/LLM thật trong các test này. Docker không cần cho phần này.

Android thật và thanh toán/chat E2E với ngôn ngữ Anh chưa thực hiện. Cần cài APK mới và kiểm tra trên thiết bị trước nghiệm thu mobile. Việc các bộ test fixture qua không thay thế kết quả máy thật.

Tài liệu cơ chế Flutter: https://docs.flutter.dev/ui/internationalization . Đã đối chiếu với SDK local3.38.7 khi cấu hình gen-l10n.

## APK xem thử

Debug APK đã build thành công (assembleDebug159,1s), chữ ký apksigner verify qua. Tệp: `mobile-qa-evidence/localization-20261108/app-debug-vi-en.apk`. SHA256 `f1ca4e83c29ef5993edb3062a9634390465308ef7ac2a153c066dc56b5119292`; bản chép khớp build output. API QA vẫn127.0.0.1:4012/api/v1, Real Mode và tài khoản VietQR sandbox từ public-defines của gói hành lý. Không kèm secret Backend.

Build ghi lỗi cache incremental Kotlin do Pub cache ở ổC và worktree ở ổD, sau đó cơ chế fallback của compiler đã hoàn tất và lệnh trả thành công. Không sửa Gradle/source để tắt kiểm tra hoặc đổi phiên bản. Chưa cài APK mới lên điện thoại; không coi build thành công là device E2E.
