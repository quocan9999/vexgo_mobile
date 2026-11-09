# Mobile: quản lý đánh giá và phản hồi nhà xe

Ngày 06/11/2026. Worktree `vexgo_accompanied_luggage_worktree`, nhánh `feature/mobile-accompanied-luggage`; các thay đổi đang ở working tree, chưa commit/push. Backend đối chiếu tại `0159558a6040dad9245796252d4b3ec66362c2dc`.

## Phạm vi

- Trong Vé của tôi và Chi tiết vé đã hoàn tất, mở **Xem đánh giá** để đọc nhận xét và phản hồi thực tế của nhà xe.
- Dùng endpoint của khách hàng đang đăng nhập; không sử dụng endpoint Admin hoặc dữ liệu đánh giá công khai để xác định quyền sở hữu.
- Sửa số sao/nội dung khi API trả `isEditable: true`; xóa đánh giá của mình có xác nhận. Thời hạn sửa 3 ngày không được áp dụng nhầm thành hạn xóa.
- Chỉ cập nhật nội dung sau khi ACK và lần đọc lại khớp. Sau xóa, lần đọc lại phải xác nhận đánh giá không còn tồn tại.
- Giữ bản nháp khi lỗi. Khi kết quả thay đổi chưa xác định, khóa gửi lại trên mọi vé cùng chuyến cho đến khi tải lại đánh giá thành công.
- Một đánh giá theo khách/chuyến được đồng bộ cho các vé cùng chuyến. Snapshot chậm của danh sách/chi tiết vé không được khôi phục nội dung trước lần sửa/xóa đã xác nhận; lần đọc riêng `/reviews/my` là nguồn đối chiếu tiếp theo.
- Đăng xuất/đổi tài khoản che dữ liệu của sheet đang mở, bỏ phản hồi muộn và không đọc tiếp bằng token tài khoản kế tiếp.
- Nội dung hướng dẫn nằm trong nút thông tin. Form có cuộn, vùng chạm sao >=48dp, giới hạn 1.000 ký tự. Tag chỉ dùng trong Demo Mode như luồng cũ, không gửi lên API thật.

## Contract

| Thao tác | Endpoint |
|---|---|
| Tạo | `POST /reviews` |
| Đọc đánh giá của tài khoản | `GET /reviews/my` |
| Sửa | `PATCH /reviews/:id` |
| Xóa | `DELETE /reviews/:id` |

GET own trả `id`, `tripId`, `rating`, `comment`, `createdAt`, `isEdited`, `isEditable`, `reply`. Ticket snapshot chưa có đầy đủ quyền sửa/phản hồi, nên sheet đọc own endpoint khi mở. PATCH ACK không có đủ metadata, cần đọc lại GET own.

Backend hiện yêu cầu vé thanh toán hợp lệ, chuyến đã khởi hành/hoàn tất và gửi mới trong 7 ngày từ khởi hành. Quyền sửa được lấy từ API, không tự suy ra bằng đồng hồ điện thoại. Backend kiểm tra quyền sở hữu một lần nữa khi thay đổi.

## Các file chính

- `lib/data/models/review_model.dart`: ID, cờ quyền sửa, phản hồi nhà xe, parser dữ liệu API.
- `lib/data/datasources/remote/review_remote_data_source.dart`: HTTP, kiểm tra ACK/readback, chặn follow-up sau đổi phiên.
- `lib/data/models/ticket_model.dart`: hỗ trợ xóa review rõ ràng qua `clearReview`.
- `lib/features/user/my_bookings/bloc/my_tickets_{bloc,event,state}.dart`: thao tác một lượt, đối chiếu phiên, kết quả chưa xác định và đồng bộ theo chuyến.
- `lib/features/user/my_bookings/presentation/widgets/review_bottom_sheet.dart`: xem/sửa/xóa, giữ bản nháp và phản hồi.
- `ticket_summary_card.dart`, `ticket_detail_screen.dart`: điểm mở quản lý đánh giá.

Không sửa Backend, schema hay migration. Không thay đổi cước hành lý hoặc cách tính tiền vé.

## Kiểm chứng

- **390/390** kiểm thử HTTP fixture, BLoC và widget qua trong lượt này; gồm kiểm thử đánh giá mới và hồi quy đặt vé/khứ hồi/hành lý/gửi hàng/thanh toán/tài khoản/chi tiết vé.
- `test/review_management_test.dart`: quyền sửa hết hạn nhưng vẫn xóa được; ACK sai ID; readback cũ; timeout; thao tác lặp; đổi phiên; đồng bộ nhiều vé; ngăn snapshot chậm; giữ bản nháp; 320x640 và 640x360 với cỡ chữ 2x và bàn phím.
- Native Flutter → API4012/DB QA3313: đăng nhập và `GET /reviews/my` qua **1/1**, danh sách hiện rỗng. Kiểm tra vé hiện tại không tìm thấy chuyến đã trả tiền còn trong hạn gửi mới 7 ngày và chưa có đánh giá.
- **Chưa chạy CRUD đánh giá trên API thật hoặc máy Android** vì chưa có vé QA đủ điều kiện; không thay trạng thái thanh toán/chuyến trong DB để vượt điều kiện. Không coi fixture là E2E.
- ADB hiện chưa có thiết bị. Chưa commit/push/tạo PR cho phần này.

Log nằm ở workspace `mobile-qa-evidence/review-management-20261106/`: `regression-tests.log`, `analyze.log`, `native.log`, `native-result.json`, `build.log`.

## Kiểm tra tiếp trên máy thật

1. Dùng vé QA đã thanh toán của chính tài khoản, chuyến đã khởi hành và còn hạn 7 ngày.
2. Gửi nhận xét, tải lại danh sách, mở lại chi tiết và kiểm tra giữ đúng nội dung.
3. Sửa trong hạn, kiểm tra nội dung mới sau refresh; đọc phản hồi nhà xe nếu đã có.
4. Thử mất kết nối sau gửi; giữ nháp, kiểm tra lại thay vì gửi lặp.
5. Xóa, xác nhận, mở lại danh sách/chi tiết; không còn nhận xét cũ. Kiểm tra cả vé thứ hai cùng chuyến nếu có.
6. Đăng xuất khi sheet đang mở; nội dung tài khoản trước phải biến mất.

APK tích hợp tiếp tục dùng API4012/DB3313 và shortcut **VexGo - Hanh ly moi**. Bản báo cáo cũ/API4002/DB3312 giữ nguyên.
