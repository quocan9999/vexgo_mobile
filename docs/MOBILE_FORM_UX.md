# Giao diện Mobile: form, font, header và tài khoản

## Nhánh và phụ thuộc

Nhánh `fix/mobile-promotion-password-ux` dựa trên `feature/payment-confirmation-notifications` tại `d9169ab` (PR #17). Review phần giao diện trên base này; sau khi PR #17 merge cần retarget sang `develop` và kiểm tra lại diff.

## Thay đổi

- Mã ưu đãi ở luồng đặt vé thật dùng bottom sheet, không tự mở bàn phím. Kiểm tra qua BookingFlowBloc/API quote hiện có; khóa gửi trùng, giữ nội dung và lỗi khi mã bị từ chối, chỉ đóng khi quote chấp nhận đúng mã. Thu hồi sheet khi đổi phiên, kể cả khi có overlay khác phía trên.
- Màn xác nhận giữ kích thước header/countdown/dock khi bàn phím của sheet mở.
- Đổi mật khẩu chuyển từ dialog sang màn riêng có vùng cuộn, Next/Done và nút lưu phía trên bàn phím. Giữ validator, API/event, kiểm tra chủ sở hữu phiên và xử lý logout/đổi tài khoản.
- Dùng chung Plus Jakarta Sans qua `AppTypography.fontFamily`, khớp font chính Customer Web. Dùng font asset hiện có; không tải font runtime. Countdown giữ tabular figures.
- Vé của tôi, Thông báo, Tài khoản và mọi trạng thái Chi tiết vé dùng header đỏ chung. Tab root không có back; Chi tiết vé giữ back và refresh. Action đổi sang icon có tooltip ở màn hẹp/chữ lớn.
- Bộ lọc Vé của tôi/Thông báo dùng TabBar phẳng có gạch chân, hỗ trợ cuộn khi thiếu chỗ và đồng bộ khi BLoC reset. Nội dung thông báo trống cuộn được ở chữ lớn.
- Tài khoản dùng danh sách phẳng, bỏ khung và tiêu đề nhóm lặp; giữ avatar, điểm, các chức năng và xác nhận đăng xuất. Hàng tự tăng chiều cao ở màn hẹp/chữ lớn; phiên bản là footer.

## Phạm vi contract

Không thay Backend, schema/migration, dependency hoặc quy tắc đặt vé/thanh toán. Demo voucher catalogue giữ nguyên; nhập mã thật dùng quote Backend. Các thay đổi font trong chat không đổi socket/API.

## Kiểm chứng

Kết quả chạy lại trên toàn bộ thay đổi được ghi trong mô tả PR. Các test bao gồm session isolation, password/auth, quote, form bàn phím, lọc trạng thái, điều hướng, màn hẹp/landscape/chữ 2x và các màn booking/chat liên quan.

APK profile ARM64 đã build thành công, khoảng 32 MB. Bản tổng hợp `app-profile-home-information.apk` đã chép vào Download/Vexgo và đối chiếu SHA-256. Chưa có xác nhận cài/kiểm tra trực quan bản này trên máy thật; chưa đo frame timeline nên chưa kết luận hết giật/lag.

Chạy lại trước khi tạo PR: 205/205 test qua trong 18 file liên quan (unit/widget/regression).
Flutter analyze: No issues found. git diff --check không có lỗi whitespace.
