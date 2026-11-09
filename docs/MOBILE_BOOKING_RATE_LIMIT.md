# Mobile: xử lý giới hạn đặt vé HTTP 429

Ngày 06/11/2026. Flutter `feature/mobile-accompanied-luggage`, base `8765e1e915fbac1fe840ce6fdbfd943bb67fb7f9` + working tree. Contract Backend đối chiếu `0159558a6040dad9245796252d4b3ec66362c2dc`.

## Contract đã kiểm tra

`SeatHoldsService.assertNoSpamUnpaidBookings` có thể trả HTTP 429 với mã `TOO_MANY_UNPAID_BOOKINGS` ở bước giữ ghế và tạo booking. Trong cửa sổ 30 phút, nó kiểm tra số đơn chưa thanh toán/đã hủy chưa có thanh toán thành công, hoặc lượt giữ chỗ hết hạn của tài khoản; từ 3 lượt trở lên có thể bị chặn. Đây là lỗi nghiệp vụ riêng với HTTP 429 do throttler giới hạn tần suất.

Response nghiệp vụ hiện chỉ có status/code/message; không có thời điểm mở khóa hoặc Retry-After riêng. Mobile không tự dựng countdown/thời điểm mở khóa tuyệt đối, không hứa rằng xử lý một đơn sẽ lập tức hết chặn.

## Hành vi mới

- Phân loại bằng HTTP status và mã lỗi, không đoán theo nội dung tiếng Việt.
- Với `TOO_MANY_UNPAID_BOOKINGS`: màn hướng dẫn kiểm tra các đơn trước và hướng dẫn quay lại sau 30 phút theo Backend.
- Với 429 khác: thông báo tạm giới hạn số lần thao tác, không gán sai lý do nhiều đơn chưa trả tiền.
- Có hành động **Kiểm tra vé/đơn**, **Quay lại đặt vé**, **Liên hệ hỗ trợ**. Mở trang khác bằng push để giữ phiên đặt vé khi quay lại; quyền truy cập trang đích vẫn do flow hiện có quyết định, khách vãng lai không được cấp quyền xem đơn của tài khoản khác.
- Notice nằm trong state và giữ nguyên qua các cập nhật thông thường. Nút chính/Next/Confirm không gửi lại trong khi notice còn hiệu lực; không có timer tự retry, polling để lách giới hạn hoặc tự sinh số điện thoại/tài khoản khác.
- **Quay lại đặt vé** chỉ đóng notice và trả về bản nháp, không gọi API tạo đơn/giữ ghế/thanh toán. Khách phải chủ động thao tác bước tiếp theo; Backend vẫn quyết định còn bị giới hạn hay không.
- Thông tin hành khách/điểm đón trả/khuyến mãi/vật phẩm được giữ trong state; chọn ghế được giữ sau lỗi giữ chỗ 429. Nếu hold đã có hết hạn trong lúc chờ, timer cũ vẫn xử lý đúng: giải phóng/chọn lại ghế nhưng giữ thông tin hành khách.
- HTTP 429 trước khi có booking ID là phản hồi từ chối xác định, không đặt cờ `bookingOutcomeUnknown`. Mất response/timeout vẫn đi theo luồng chưa xác định cũ, không cho tạo lại.
- Khi có booking/payment ID rồi mà bước kiểm tra nhận 429, giữ nguyên ID, không quay lại tạo booking hoặc payment mới.
- Khứ hồi: chặng đầu đã tạo không bị xóa/tạo lại khi chặng sau nhận 429. Chặn submit tiếp cho đến khi khách chủ động quay lại; sau đó tái sử dụng booking/comboCode cũ và chỉ tạo chặng còn thiếu nếu giữ ghế vẫn hợp lệ. QR chung vẫn yêu cầu cả hai đơn được xác minh.
- Màn khứ hồi giữ PopScope/cảnh báo rời luồng như trước. Notice không làm mất bảo vệ đổi phiên hoặc đơn đã có.

## Các file chính

- `booking_rate_limit.dart`: notice có kiểu, phân biệt mã nghiệp vụ với throttler.
- `booking_flow_state.dart`, `booking_flow_event.dart`, `booking_flow_bloc.dart`: nhận 429 tại hold/create/check, giữ bản nháp, guard gửi lặp và hành động resume không gọi API.
- `round_trip_checkout_cubit.dart`: guard hai chiều, giữ chặng thành công và resume bằng coordinator barrier.
- `booking_rate_limit_view.dart`, `booking_flow_screen.dart`, `round_trip_booking_screen.dart`: hướng dẫn có cuộn, nút >=48dp, điều hướng kiểm tra đơn và hỗ trợ.

## Kiểm chứng

- **478/478** hồi quy HTTP fixture/BLoC/widget qua, bao gồm **13** ca rate-limit mới: hold/create 429, generic vs business code, giữ liên hệ/ghế, hết hold lúc notice mở, bấm lặp, response muộn sau invalidate, giữ ID khi kiểm tra thanh toán bị 429, khứ hồi tạo được một chặng, điều hướng kiểm tra đơn rồi quay lại, màn hẹp/landscape text scale 2x.
- **13/13** ca mới chạy riêng cũng qua. `flutter analyze --no-pub` sạch sau chỉnh sửa.
- Không tạo hàng loạt booking trên DB để cố kích hoạt chặn thật; chưa kiểm thử HTTP 429 trên Backend thật hoặc Android. Kết quả trên là HTTP fixture, không phải E2E.
- Không sửa Backend, schema, DB hay chính sách 30 phút; không gửi email/push hoặc thực hiện chuyển khoản.
- Log ở workspace `mobile-qa-evidence/booking-rate-limit-20261106/`: `regression-tests.log`, `new-tests.log`, `analyze.log`, `build.log`.

APK debug đã build thành công, cập nhật file preview/manifest, chữ ký và `COPY_LUGGAGE.ps1 -CheckOnly` hợp lệ. SHA-256 hiện hành ở `luggage-preview-20261106/MANIFEST.json`. ADB chưa nhận thiết bị nên chưa chép/cài Android.

APK preview tiếp tục dùng API4012/DB3313 và shortcut **VexGo - Hanh ly moi**. APK/launcher báo cáo dự phòng đã đối chiếu hash giữ nguyên. Thay đổi chưa commit/push/PR.
