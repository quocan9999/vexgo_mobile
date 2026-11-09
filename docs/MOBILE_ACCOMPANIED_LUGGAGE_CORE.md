# Core Mobile — Hành lý đi kèm

## Snapshot và phạm vi

Worktree `vexgo_accompanied_luggage_worktree`, branch `feature/mobile-accompanied-luggage`.
Base8765e1e + baseline local auth/accountType, catalogue và forgot-password từ bản báo cáo hiện tại. Chưa commit/push/PR. APK báo cáo và DB3306/3312 không đổi.
Backend contract đọc từ origin/develop0159558; chưa merge hoặc migrate/build/run Backend mới.

## Đã triển khai

1. Model LuggagePolicy/LuggagePackage: chính sách đúng trip/route/company, allowance miễn phí,4gói,giá phương tiện/phụ phí; từ chối dữ liệu thiếu/trùng/sai giới hạn hoặc tiền VND không hợp lệ. Không hardcode giá/7kg dự phòng.
2. RealLuggageRepository: endpoint public GET /bus-companies/trips/{tripId}/luggage-packages, kết hợp RealCargoRepository để kiểm tra categories/capacity/điểm đúng chuyến.
3. CarryOnBag và CheckedLuggageItem/LuggageSelection: tách xách tay miễn phí khỏi ký gửi, kiểm tra số hành khách, cân nặng hiệu dụng/kích thước/gói/sức chứa/điểm; dùng quy tắc thể tích/rounding và validation CargoItemDraft hiện có. Giá tham khảo tính bằng BigInt để tránh tràn số.
4. LuggageCubit: owner theo chuyến/số hành khách/phiên, selection riêng từng chặng, epoch bỏ phản hồi muộn, skip rõ ràng, fail closed, policy freshness5phút theo wall-clock, session revocation xóa draft. Export cần xác minh lại trip và số ghế hiện tại.
5. SetBookingCargoEnabledEvent bổ sung optional initialDraft; BookingFlowBloc tiếp nhận draft nguyên khối trong một event rồi kiểm tra lại như luồng hiện có. Coordinator khứ hồi tiếp tục hỗ trợ event cùng loại; không đổi payment flow.

## Nguồn giá và phần cần lead đối chiếu

GET luggage-packages trả rates/packages/vehicles/surcharges/maxFreeWeightKg. POST bookings chưa có packageCode/isFreeCarryOn hoặc luggage quote. CargoPricingService vẫn lấy baseFee từ BangCuocGuiHang; cấu hình mới của nhà xe được dùng cho phụ phí. Tham khảo Web có cách tính phụ phí theo kiện trong khi Backend hiện dùng cờ phụ phí trên đơn.

Core cố ý chỉ xuất CargoItemDraft/điểm của ký gửi, không gửi giá tham khảo hoặc bịa field. Hành lý xách tay không được lưu thành kiện hàng miễn phí trên Backend, đúng giới hạn contract hiện có. Tổng tiền sau tạo booking luôn từ Backend. Muốn giá gói được cam kết trước tạo đơn/lưu mã gói cần contract Backend từ lead.

## Kiểm thử đã thực chạy

Lệnh:

flutter test --no-pub test/accompanied_luggage_core_test.dart test/booking_cargo_core_test.dart test/booking_cargo_ui_test.dart test/round_trip_core_test.dart test/round_trip_passenger_lock_test.dart test/booking_flow_test.dart test/payment_integrity_test.dart test/real_vs_demo_mode_test.dart --reporter expanded

Kết quả:105/105 qua. Trong đó test mới18ca; có kiểm thử nối vào BookingFlowBloc/coordinator khứ hồi bằng MockClient. Một ca cố ý preview80.000 nhưng Backend fixture trả50.000 để bảo đảm checkout giữ đúng phí server, không lấy giá FE.

flutter analyze --no-pub: No issues found.

git diff --check: không có whitespace error.7file generated plugin desktop chỉ có thay đổi EOL từ flutter pub get, không thuộc feature.

Evidence ngoài Git: mobile-qa-evidence/luggage-core-20261106.

Chưa thực thi: UI mới, API0159558 thật, Android, thanh toán SePay hoặc migration mới. Không build/cài APK mới chỉ cho core chưa có UI; bản báo cáo hiện tại vẫn giữ hash9d36a9b847130b660123759bb07cc59dff382123cf87da4c78a20716d01053c9.

## Bàn giao UI

Xem docs/MOBILE_ACCOMPANIED_LUGGAGE_UI_HANDOFF.md và bản tương ứng ở workspace root. Agent thực hiện trên chính worktree này. Giữ các guard API/booking/payment; không tự sửa Backend hoặc bản báo cáo để ép UI chạy.

## Đã đối chiếu API thật sau chuẩn bị môi trường riêng

API4012/DB3313 của Backend0159558 đã build và áp3migration mới. Native Flutter RealLuggageRepository/LuggageCubit + HTTP/NestJS/MySQL thật1/1case qua với policy tùy chỉnh9kg/M95.000.3booking qua API thật chứng minh chênh lệch phí, ghi trong docs/MOBILE_LUGGAGE_BACKEND_FINDINGS_20261106.md. Chưa phải Android/UI E2E và chưa thanh toán.

Bản UI handoff đã cập nhật môi trường mới. Phần “chưa chạy API mới” ở kiểm chứng core ban đầu là snapshot trước bước này. Không thay APK hoặc DB báo cáo.
