# Hành lý đi kèm — các điểm cần lead chốt trước khi ghép UI

Ngày kiểm tra: 06/11/2026. Backend snapshot0159558a6040dad9245796252d4b3ec66362c2dc.
Đây là báo cáo đối chiếu contract và hành vi đã thực chạy, không tự thay đổi quy tắc Backend hoặc gửi PR sửa nghiệp vụ.

## Môi trường và bằng chứng

- Backend worktree: vexgo_luggage_backend_worktree, branch qa/luggage-contract-20261106, HEAD0159558, source sạch.
- API4012, DB MySQL3313/container vexgo-luggage-qa-20261106, clone từ DB QA báo cáo3312. Không phải DB chính hoặc DB báo cáo đang demo.
- Build thành công. Ban đầu npm workspace bị thiếu shim Nest tại node_modules root do dependency nằm ở apps/api; runner dùng Prisma generate rồi Nest CLI đúng app path. Dependency node_modules root và apps/api là junction đọc lại bộ đã cài cùng package-lock của vexgo_web; không chạy npm ci/install/prune trên worktree này khi junction còn dùng chung.
- Áp dụng thành công3migration mới: add_bus_company_luggage_policy, add_review_reply_fields, add_combo_order_code.62migration applied,0missing,0unfinished. Hai checksum drift cũ được giữ nguyên, không tự sửa lịch sử.
- Native Flutter RealLuggageRepository/LuggageCubit + HTTP/NestJS/MySQL thật:1/1 test qua. Không MockClient, chưa phải Android E2E.
-3booking được tạo qua giữ ghế và POST /bookings thật; không gọi thanh toán/webhook và không chuyển tiền. Email/push/reminder/Cloudinary của API4012 tắt.

Evidence: mobile-qa-evidence/luggage-api-20261106/{http-luggage-result.json,native-luggage-result.json,fixture-config.json,migration-review.json,build.log,migrate.log}.
Các credential/QAenv nằm private riêng, không đưa vào báo cáo/PR.

## Dữ liệu thử có kiểm soát — không phải giá đang bán thật

Clone kế thừa chuyến791/route10/Hoa Mai. Ban đầu chuyến không nhận ký gửi, route10 chỉ có1mức cước đã hết hiệu lực02/11. Vì vậy chỉ trên clone3313:

- Bật nhanGuiHang cho791.
- Thêm4mức cước BƯU PHẨM(category1), hiệu lực07–14/11: (0,5]kg50.000; (5,10]80.000; (10,20]120.000; (20,35]180.000. ID128–131.
- Cấu hình riêng NhaXe3: packageM95.000; fragileSurcharge30.000; maxFreeWeightKg9. Các giá trị còn lại lấy default Backend.
- Chính sách tùy chỉnh có chủ đích để kiểm tra API chốt giá có sử dụng cấu hình nhà xe hay không. Không gọi các con số này là lỗi dữ liệu production.
- Snapshot trạng thái trước thay đổi lưu fixture-config.json. Không sửa/xóa mức cước cũ.

## 1. Cần chốt trước khi UI gọi gói là “giá thanh toán”

GET /bus-companies/trips/791/luggage-packages trả đúng policy95.000 choM và miễn phí9kg.
POST /bookings vẫn dùng CargoPricingService.calculate → nhóm theo loaiHangHoaId + tổng khối lượng → BangCuocGuiHang. Giá packageM không được dùng làm baseFee booking.

| Ca thực chạy | Giá tham khảo theo gói/Web | Phí Backend chốt | Đối chiếu |
|---|---:|---:|---|
|1kiện8kg, chọnM trên client|95.000|80.000|booking844/order865; DB và readback80.000|
|2kiệnS, mỗi kiện5kg|100.000|80.000|booking845/order866; tổng10kg được tính chung bảng cước|
|2kiệnS dễ vỡ, mỗi kiện5kg|160.000|110.000|booking846/order867; base80.000 + phụ phí30.000 một lần|

**Lead cần quyết định:** mua gói có giá niêm yết cố định, hay gói chỉ là hướng dẫn/phí tham khảo và giá cuối cùng theo bảng cước hiện có?

Nếu mua theo gói: đề xuất Backend nhận và kiểm tra mã gói theo trip/route, số lượng, cân nặng hiệu dụng/kích thước; lấy giá cấu hình server và lưu snapshot gói/giá. Nên có quote hành lý/quote tổng đơn trước tạo booking, kèm thời hạn hoặc cơ chế phát hiện giá đổi. Không nhận số tiền client như nguồn sự thật.

Nếu giữ bảng cước: Mobile có thể ghép theo contract hiện tại, nhưng UI phải ghi rõ “tham khảo”; Web cũng cần dùng cách diễn đạt/tính preview tương ứng. Không gọi số95.000 là khoản chắc chắn sẽ thu.

Nguồn: apps/api/src/cargo-pricing/cargo-pricing.service.ts (weightsByType, đoạn420+, serviceFee đoạn513+); apps/api/src/bus-companies/bus-companies.service.ts getTripLuggageRates đoạn415+.

## 2. Chốt tính theo số kiện và phạm vi phụ phí

Web calculateLuggageFee nhân (giá gói + phụ phí) với quantity.
Backend cộng tổng khối lượng theo loại hàng, chọn1bảng cước cho tổng đó; fragile/valuable là cờ áp một lần trên đơn (có thể cộng cả hai cờ khi nhiều loại dịch vụ).

Đây là khác biệt nghiệp vụ, không sửa bằng cách làm tròn hoặc đổi nhãn FE. Lead chốt tính theo kiện hay tổng khối lượng; phụ phí theo kiện hay theo đơn. Sau đó quote, booking, thông tin gói và Web/Mobile phải đồng bộ.

## 3. Lựa chọn gói và hành lý miễn phí chưa có field lưu trong booking

CargoItemDto hiện chỉ có name/type/loaiHangHoaId/quantity/weight/dimensions/category/note/thông tin phương tiện. Không có packageCode hoặc freeCarryOn. Validation dùng whitelist + forbidNonWhitelisted.

- Mobile hiện chỉ gửi ký gửi bằng cargoItems và điểm gửi/nhận, không tự nhét mã gói vào note hoặc gửi giá client.
- Hành lý xách tay trong allowance hiển thị/kiểm tra phía client và không tạo kiện hàng tính phí. Kiểm thử9kg miễn phí,9,1kg bị yêu cầu chuyển ký gửi đã qua.
- Nếu chỉ là nội quy xách tay để nhân viên kiểm tra khi lên xe: có thể giữ chưa lưu khai báo, không nhất thiết thêm schema.
- Nếu cần Backend quản lý từng kiện/quyền lợi theo số vé: cần DTO và lưu trạng thái riêng, kiểm tra số lượng theo hành khách và snapshot chính sách. Không thể nói đã quản lý Backend chỉ nhờ FE hiển thị miễn phí.

## 4. Dữ liệu cần cấu hình để ký gửi hoạt động

Policy endpoint trả gói mặc định không đồng nghĩa chuyến đã sẵn sàng nhận hành lý: còn cần acceptsShipments/sức chứa, loại hàng đúng nhóm, điểm gửi/nhận theo tuyến và bảng cước còn hiệu lực.

Trong clone trước fixture:791 chưa nhận ký gửi; route10 chỉ có giá hết hạn; danh mục7loại đều HANG_NHE, chưa có nhóm XE_MAY/HANG_CONG_KENH. Vì vậy bảng giá hiển thị xe máy/xe đạp chưa chứng minh có thể tạo đơn cho phương tiện.

Đây là yêu cầu dữ liệu/cấu hình cần chuẩn bị, không tự coi là bug code. UI phải ẩn/vô hiệu lựa chọn chưa được API cho phép, không tự chọn loại hàng HANG_NHE để gửi xe máy.

## 5. Quy tắc chống spam cần xác nhận nội dung

Sau3booking844–846 vừa tạo, chưa thanh toán và chưa hết hạn, lần giữ ghế tiếp theo trả429 TOO_MANY_UNPAID_BOOKINGS.

Source assertNoSpamUnpaidBookings dùng các đơn tạo30phút gần đây, trạng thái CHO_THANH_TOAN hoặc DA_HUY, không có thanh toán thành công; không chỉ đếm đơn đã hết hạn như mô tả comment. Có kiểm tra cả hold HET_HAN theo tài khoản.

Lead xác nhận đây là chủ đích chặn3đơn chưa trả ngay, hay chỉ chặn3lần bỏ đơn hết hạn. Nếu là chủ đích, nên đồng bộ mô tả/thông báo và các ca khứ hồi/tập demo; không đề xuất bỏ bảo vệ.

## 6. Lưu ý nâng DB — tách khỏi việc vẽ UI

Hai checksum drift trong clone:
-20261013150000_add_chat_support_conversations_and_messages: lịch sử cũ đã có, không phải kết luận do update lần này gây ra.
-20261103233000_route_based_cargo_pricing: migration đã áp trong clone từ bản trước, file trên develop mới bị sửa thêm backfill. Không đổi checksum DB để giả lịch sử sạch.

Backfill mới gán mọi row tuyenXeId=0 về tuyến đầu tiên trong TuyenXe. Nếu dùng để nâng dữ liệu cũ thực, cần lead đối chiếu ánh xạ tuyến đúng thay vì chỉ làm FK pass. Clone hiện đã được backfill theo mapping trong đợt QA trước nên không chạy lại migration cũ này; việc3migration mới thành công không chứng minh rollout cũ an toàn cho DB chính.

## Hướng ghép UI trong lúc chờ lead

Agent tiếp tục UI bằng core đã có. Giữ nhãn tham khảo, checkout lấy tổng Backend, không gửi packageCode/giá chưa có contract, không tự tạo dữ liệu hoặc sửa Backend để ép qua.
Nếu lead chốt bán đúng gói, phần cam kết giá/lưu gói chờ Backend rồi mới nghiệm thu full-stack. Mobile không tự mô phỏng quyết toán gói để che chênh lệch.

## Bản báo cáo vẫn nguyên

Đã đối chiếu lại DB3312: trip791 nhanGuiHang0;0đơn QA Luggage Contract; không có cột chính sách mới. Backend báo cáo vẫn f6ababc. APK báo cáo giữ SHA2569d36a9b847130b660123759bb07cc59dff382123cf87da4c78a20716d01053c9.


## Cập nhật 07/11/2026 — PR66

Đã đồng bộ contract cước dự tính thu tại bến trên Backend72decda và Mobile; giữ tổng lịch sử. Xem MOBILE_CARGO_COUNTER_PAYMENT_SYNC_20261107.md cho phạm vi, 486 test Flutter, 62 test Backend và giới hạn kiểm thử thật. Ghi chú chờ Backend loại cước khỏi tiền vé ở các phần trước là lịch sử; các vấn đề gói/bảng giá khác chưa mặc nhiên được giải quyết.
