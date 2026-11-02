# Trang chủ: hướng dẫn, ưu đãi và thông tin VexGo

Cùng nhánh `fix/mobile-promotion-password-ux`, phụ thuộc PR #17 như mô tả trong `MOBILE_FORM_UX.md`.

## Phạm vi

- Trang chủ hiển thị ưu đãi theo nhà xe, tối đa hai mục ban đầu; mở danh sách đầy đủ khi có nhiều hơn. Hướng dẫn đặt vé gồm ba bước gọn và liên kết tới hướng dẫn đầy đủ.
- Tài khoản thêm một hàng Thông tin VexGo mở Giới thiệu và Hướng dẫn sử dụng.
- Nội dung Giới thiệu/Hướng dẫn tĩnh trong app, mô tả chức năng hiện có. Chưa dùng CMS/DB; không thêm liên lạc mẫu hoặc số liệu quảng cáo.
- Không thêm tiện ích nhanh. Điều khoản và Bảo mật để sau vì chưa có nội dung chính thức được duyệt.

## API ưu đãi

Dùng `GET /api/v1/promotions/available?nhaXeId=<ID thật>`; không gọi API quản trị hoặc gửi credential. Endpoint yêu cầu phạm vi nhà xe/chuyến; người dùng chọn nhà xe từ dữ liệu HomeBloc đã tải.

Đọc code/name/discountType/discountValue/maxDiscount/minimumTicketAmount/startsOn/endsOn, nhận decimal string của Backend. Hiển thị điều kiện/thời gian, cho sao chép mã. Không tự áp dụng mã hoặc tính giá thanh toán; điều kiện cuối do quote/create booking xác nhận.

Sai định dạng trả lỗi tải; API trống hiển thị trạng thái trống, có retry/làm mới. Không tạo dữ liệu mẫu. Response cũ không thay kết quả của nhà xe mới khi chuyển lựa chọn.

## Kiểm chứng và giới hạn

Test repository/widget bao gồm GET đúng scope, không gửi credential, decimal mapping, dữ liệu sai, empty, retry và response đến muộn; hướng dẫn có kiểm tra điều hướng với chữ lớn. Kết quả chạy lại nhóm test tổng hợp/analyze ghi trong mô tả PR.

Probe HTTP thật vào API local cổng 4002 với nhaXeId=3 trả 200 và data rỗng. Không tạo/sửa dữ liệu DB. Các ca có mã ưu đãi dùng fixture, không phải E2E với ưu đãi thật.

APK profile ARM64 đã build thành công và chép đúng SHA-256 vào Download/Vexgo/app-profile-home-information.apk. Kiểm tra trực quan/hiệu năng trên máy thật còn chờ. Không thay Backend/schema/migration.
