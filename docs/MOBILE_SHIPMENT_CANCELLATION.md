# Mobile — hủy đơn gửi hàng độc lập

Ngày 06/11/2026. Backend đối chiếu 0159558; API4012/DB QA3313. Chỉ sửa Flutter; không sửa Backend, migration, schema hay quy tắc hoàn tiền.

## Hành vi

- Thêm thao tác hủy trong chi tiết đơn và kết quả tra cứu công khai. Chỉ cho gửi khi trạng thái đã biết là MOI_TAO; Backend quyết định điều kiện cuối cùng.
- POST /shipments/cancel gửi waybillCode, phoneNumber và reason optional tối đa 255 ký tự; optional auth. Dùng số điện thoại đã xác minh của kết quả tra cứu hoặc số người gửi trong chi tiết đơn, không lấy ô nhập vừa sửa làm quyền xác minh cho kết quả cũ.
- Hộp xác nhận có lý do chọn sẵn/Khác, nút Giữ đơn và Xác nhận hủy. Nội dung giải thích không hoàn tiền trực tuyến; đã thanh toán thì liên hệ nhà xe.
- Chỉ cập nhật DA_HUY khi API xác nhận đúng mã vận đơn, status, timestamp và hasPaidBeforeCancel hợp lệ. Giữ lịch sử tiền; không tự gán đã hoàn tiền hoặc gọi API refund.
- Bỏ cache danh sách sau hủy; quay lại danh sách sẽ tải lại. Dừng hướng dẫn mang hàng/thanh toán và polling thanh toán của đơn đã hủy.
- Single flight chặn nhấn hai lần và đổi target trong khi mutation đang chạy. Đổi phiên/đóng Cubit chặn phản hồi muộn, hộp thoại không tiếp tục hiện dữ liệu đơn của phiên trước.
- Khi mất phản hồi hoặc payload không đủ xác minh: khóa gửi lại cho vận đơn đó, chỉ cho tra cứu trạng thái. Không tự POST lại.
- Lỗi 4xx xác định sẽ đọc lại trạng thái để bỏ nút hủy nếu hàng đã tiếp nhận/đã hủy. BOOKING_SHIPMENT_TRIP_FIXED và các lỗi không đủ điều kiện không cho lặp yêu cầu hủy độc lập. Trạng thái không biết cũng không cho hủy.
- Lỗi/kết quả hủy được hiển thị đúng vận đơn đang xem; danh tính chưa xác minh được theo dõi riêng theo mã vận đơn trong phiên.

## Các file chính

- lib/data/models/shipment_model.dart: model xác nhận hủy; copy tracking giữ nguyên thông tin hàng/phí.
- lib/data/repositories/shipment_repository.dart: API khách hàng hủy; kiểm tra ACK đúng vận đơn.
- lib/features/user/shipments/shipment_flow_cubit.dart: mutation, session fence, unknown outcome, tra cứu lại, bỏ cache danh sách.
- lib/features/user/shipments/presentation/widgets/shipment_cancellation_section.dart: xác nhận, lý do, trạng thái và hướng dẫn hỗ trợ.
- shipment_detail_view.dart và shipment_lookup_view.dart: gắn thao tác hủy; bỏ hướng dẫn thanh toán sau hủy.

## Kiểm chứng

- 18 suite đặt vé/thanh toán/khứ hồi/hành lý/gửi hàng: **281/281 pass**. Log ở workspace cha mobile-qa-evidence/shipment-cancel-20261106/regression-tests.log.
- 13 ca riêng trong test/shipment_cancellation_test.dart: ACK đúng, lookup bằng số người nhận, trạng thái không được phép, chặn hàng kèm vé sau Backend từ chối, single flight, timeout và phục hồi qua lookup, ACK sai đơn, conflict/trạng thái mới, đổi tài khoản trong khi request/hộp thoại mở, lý do quá dài, giữ đơn/xác nhận và hướng dẫn cước đã trả, chữ 2x/landscape/bàn phím.
- Kiểm thử native Flutter repository/Cubit qua HTTP/NestJS/MySQL thật: **1/1 pass**, không MockClient, không Android.
- Chỉ tạo một đơn QA mới #33 qua API, rồi hủy chính đơn đó qua API khách hàng. Tra cứu lại DA_HUY, hasPaidBeforeCancel=false. Không hủy/sửa đơn cũ, không chuyển tiền, không gọi refund/webhook. DB3312 và DB3306 giữ nguyên.
- Native test có journal chống replay tại mobile-qa-evidence/shipment-cancel-20261106/native-result.json; credential/contact chỉ đọc từ thư mục private đã có, không đưa vào tài liệu.
- Chưa kiểm thử trên điện thoại; tình huống đã thanh toán/race/timeout được kiểm chứng bằng fixture, không gọi đó là live E2E.

Chưa commit/push. Phần hành lý chỉ dự tính và không cộng cước vào vé vẫn chờ teammate Backend; tính năng hủy này không thay đổi quy tắc đó.


## APK và shortcut

Build debug thành công. APK ở workspace cha `luggage-preview-20261106/app-debug-accompanied-luggage.apk`, SHA-256 `0e29b5fc2d392fe2320c7390d4a34ab0f0815f6ea0fe1edacfd45aaa4f1c8e8c`. Chữ ký hợp lệ, manifest và CheckOnly của shortcut bản mới hợp lệ. APK bao gồm cả UI hành lý và QR khứ hồi đã làm trước. APK/script báo cáo dự phòng vẫn khớp hash cũ. ADB chưa có thiết bị tại lúc đóng gói nên chưa chép/cài trên Android.
