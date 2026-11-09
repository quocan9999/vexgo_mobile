# MOBILE ACCOMPANIED LUGGAGE UI REPORT (`feature/mobile-accompanied-luggage`)

## 1. Mục tiêu và phạm vi triển khai
Chuyển giao diện **“Gửi hàng kèm vé”** trong luồng đặt vé hành khách (một chiều & khứ hồi) sang **“Hành lý đi kèm”**, bám sát chính sách Web mới và tầng core đã nghiệm thu (`LuggagePolicy`, `LuggageRepository`, `LuggageCubit`), áp dụng hệ thống thiết kế `DiscoveryTheme` và chuẩn `/ui-ux-pro-max`.

- **Worktree triển khai**: `D:\A_KhoaLuanTotNghiep\HeThongDatVeXeKhachTrucTuyen_Application\vexgo_accompanied_luggage_worktree`
- **Branch**: `feature/mobile-accompanied-luggage`
- **Không chạm tầng core đã khóa**: giữ nguyên 100% `lib/data/models/luggage_policy.dart`, `lib/data/repositories/luggage_repository.dart`, `lib/features/user/booking/bloc/luggage_cubit.dart`, `BookingRepository`, payload booking/payment, `TokenStorage`, seat hold, idempotency, webhook và đối soát phí.
- **Không chạm luồng Gửi hàng độc lập**: giữ nguyên tab `/shipments` trên bottom navigation.

---

## 2. Danh sách file UI và tích hợp đã tạo / cập nhật

### File mới tạo
1. `lib/features/user/booking/presentation/widgets/booking_luggage_section_card.dart`
   - Widget `BookingLuggageSectionCard` hiển thị trọn vẹn trải nghiệm **Hành lý đi kèm** cho cả đặt vé một chiều (`scopeKey: 'oneway'`) và khứ hồi (`scopeKey: 'outbound'` / `'inbound'`).
   - **Hành lý xách tay miễn phí (`CarryOnBag`)**:
     - Hiển thị hạn mức miễn phí động theo `policy.freeWeightPerPassengerKg` trả về từ API (không hardcode `7kg`).
     - Tối đa 1 kiện xách tay miễn phí / hành khách (`bagCount <= cubit.passengerCount`).
     - Kiểm tra tức thời khi vượt `freeWeightPerPassengerKg` hoặc vượt số lượng hành khách, hiển thị hướng dẫn rõ ràng và nút chuyển nhanh sang hành lý ký gửi (**không tự giảm cân nặng và không tự đổi ngầm**).
     - Ghi chú trung thực: kiện xách tay được giữ ở phía ứng dụng (`CarryOnBag`), không gửi thành `cargoItems` lên Backend và không tuyên bố “Backend đã lưu kiện xách tay”.
   - **Hành lý ký gửi theo gói `S / M / L / XL` & Phương tiện đặc biệt (`CheckedLuggageItem`)**:
     - Hiển thị bảng gói `S`, `M`, `L`, `XL` từ `policy.packages` kèm khối lượng tối đa (`maxWeightKg`), kích thước tối đa (`maxDimensionsCm`), giá cơ bản (`baseFee`) và phụ phí dịch vụ (`fragile`, `valuable`).
     - Hỗ trợ nhóm **Phương tiện đi kèm (Xe đạp / Xe máy)** tách biệt với gói `S/M/L/XL`, chọn biểu giá xe máy `LuggageMotorcycleTariff` (`wave`, `scooter`, `big`), nhập dòng xe (`vehicleModel`), biển số (`licensePlate`), số lượng và dịch vụ.
     - Báo lỗi ngay trên UI nếu khối lượng hiệu dụng (hoặc quy đổi thể tích $L \times W \times H / 5000$) hoặc kích thước vượt gói đã chọn (**không tự chọn gói rẻ hơn hay đổi gói ngầm**).
     - Tự động ánh xạ `categoryId` hợp lệ từ `options.cargo.categories` theo đúng `CargoGroup` (`parcel`, `bulky`, `motorcycle`).
   - **Điểm gửi & Điểm nhận hàng hóa (`senderPointId`, `receiverPointId`)**:
     - Bắt buộc chọn từ `options.cargo.points.senders` và `options.cargo.points.receivers` khi có kiện ký gửi; không dùng nhầm `selectedPickupPoint` / `selectedDropoffPoint` của hành khách.
   - **Phí hành lý tham khảo (`referenceFee`) vs Phí chính thức từ Server**:
     - Hiển thị rõ `cubit.referenceFee` là **Phí hành lý tham khảo (tạm tính)** kèm ghi chú phí vận chuyển chính thức (`shippingFee`) và tổng thanh toán (`totalAmount`) do máy chủ xác nhận khi tạo đơn.
   - **Trạng thái tải, lỗi, hết hạn chính sách, khóa đơn và Responsive (`/ui-ux-pro-max`)**:
     - Hỗ trợ đầy đủ các trạng thái `LuggagePhase.idle`, `loading`, `failure` (giữ nguyên các mục đã chọn khi lỗi mạng cho tới khi bấm **Thử lại** hoặc chủ động bấm **Không thêm hành lý ký gửi** `cubit.skip()`), `revoked`, chính sách quá 5 phút (`!cubit.policyIsFresh` -> yêu cầu **Tải lại chính sách**), chuyến không nhận ký gửi (`!options.cargo.capacity.acceptsShipments`), và chế độ khóa (`locked`).
     - Đảm bảo touch target `>= 48dp`, không tràn giao diện ở `320x640` với `textScale = 2.0x` và `640x360` landscape khi mở bàn phím (`viewInsets.bottom = 160`).

2. `test/accompanied_luggage_ui_test.dart`
   - Bộ 7 nhóm kịch bản widget test toàn diện kiểm tra toàn bộ yêu cầu mục 10 của handoff:
     1. Hành lý xách tay miễn phí theo `policy.freeWeightPerPassengerKg` động (`5kg` custom allowance), chặn quá cân / vượt số túi / số ghế, nút chuyển sang ký gửi, và xác minh `exportForBooking() == null` khi chỉ có xách tay.
     2. Chọn, đổi, xóa gói `S/M/L/XL` và phương tiện đặc biệt (`CargoKind.motorcycle` + `LuggageMotorcycleTariff.scooter`); kiểm tra báo lỗi tức thời khi quá cân / quá khổ mà không tự đổi gói; chọn `senderPointId` & `receiverPointId` từ `options.cargo.points`.
     3. Lỗi tải chính sách (`404`), chính sách quá 5 phút (`!cubit.policyIsFresh`), nút **Thử lại** và nút **Không thêm hành lý ký gửi** (`cubit.skip()`) mà không tự xóa ngầm món ký gửi đã chọn khi API lỗi.
     4. Vòng đời một chiều trên `BookingFlowScreen`: giữ nguyên draft `LuggageCubit` qua `Step 4 -> Step 5 -> Quay lại Step 4`, hiển thị `Phí hành lý tham khảo (tạm tính)` ở Step 5, và tự reset kèm thông báo rõ ràng khi đổi số ghế đã chọn (`1 → 2 hành khách`).
     5. Vòng đời khứ hồi trên `RoundTripBookingScreen`: sở hữu 2 `LuggageCubit` độc lập cho `outbound` và `inbound`, giữ nguyên state qua `RoundTripPassengerStep -> RoundTripSummaryStep`.
     6. Chế độ khóa (`locked: true`) ẩn/khóa toàn bộ thao tác chỉnh sửa, và kiểm tra responsive `320x640` ở `2.0x textScale` + `640x360` landscape mở bàn phím (`0` overflow).
     7. Chuyến xe `acceptsShipments == false` chặn hành lý ký gửi nhưng vẫn cho phép khai báo xách tay miễn phí; đối soát `POST /bookings` xác minh payload không chứa `referenceFee` và UI nhận đúng `shippingFee` (`50.000đ`) / `totalAmount` (`240.000đ`) từ Server thay vì `referenceFee` (`80.000đ`).

### File đã cập nhật
1. `lib/app/app.dart`
   - Đăng ký `RepositoryProvider<CargoRepository>` và `RepositoryProvider<LuggageRepository>` ở cấp ứng dụng.
2. `lib/features/user/booking/presentation/screens/booking_flow_screen.dart`
   - Sở hữu `_luggageCubit` xuyên suốt `Step 4 <-> Step 5` của luồng đặt vé một chiều.
   - Tự hủy và tạo lại `_luggageCubit` khi `tripId`, `selectedSeats.length` hoặc phiên đăng nhập thay đổi; khi số ghế thay đổi và người dùng đã mở/khai báo hành lý, hiển thị cảnh báo `_luggageSeatChangeNotice` và xóa draft `cargo` cũ để người dùng xác nhận lại theo số hành khách mới.
   - Đồng bộ `exportForBooking` sang `BookingFlowBloc` qua `SetBookingCargoEnabledEvent` trước khi sang bước tiếp theo hoặc thanh toán.
3. `lib/features/user/booking/presentation/steps/step_4_passenger_info.dart` & `lib/features/user/booking/presentation/widgets/booking_passenger_info_view.dart`
   - Tích hợp `BookingLuggageSectionCard` ở Bước 4 và chặn nút `Tiếp tục` trên `BookingPassengerDock` khi `luggageCubit.validationError != null` hoặc chính sách hết hạn (`!luggageCubit.policyIsFresh`).
4. `lib/features/user/booking/presentation/steps/step_5_trip_summary.dart` & `lib/features/user/booking/presentation/widgets/booking_trip_summary_view.dart`
   - Tích hợp `BookingLuggageSectionCard` ở Bước 5, hiển thị dòng `Phí hành lý tham khảo (tạm tính)` trong bảng chi tiết giá trước khi tạo đơn, hiển thị `shippingFee` chính thức từ Server sau khi tạo đơn, và khóa nút `Thanh toán` trên `BookingTripSummaryDock` nếu `luggageCubit` không hợp lệ hoặc hết hạn chính sách.
5. `lib/features/user/round_trip/presentation/screens/round_trip_booking_screen.dart`, `lib/features/user/round_trip/presentation/widgets/round_trip_passenger_step.dart`, `lib/features/user/round_trip/presentation/widgets/round_trip_summary_step.dart`
   - Sở hữu 2 `LuggageCubit` tách biệt cho `TripLeg.outbound` và `TripLeg.inbound`.
   - Bảo toàn dữ liệu hành lý từng chiều khi chuyển giữa bước Hành khách và bước Tóm tắt khứ hồi.
   - Tái tạo `LuggageCubit` của đúng chiều khi số ghế chiều đó thay đổi kèm thông báo riêng theo chiều (`Chiều đi` / `Chiều về`).

---

## 3. Lệnh kiểm tra đã chạy và kết quả

Tất cả lệnh được chạy trong worktree `D:\A_KhoaLuanTotNghiep\HeThongDatVeXeKhachTrucTuyen_Application\vexgo_accompanied_luggage_worktree`:

1. **Phân tích tĩnh (`flutter analyze`)**:
   ```powershell
   cd vexgo_accompanied_luggage_worktree; flutter analyze --no-pub
   ```
   - **Kết quả**: `No issues found!` (0 lỗi, 0 cảnh báo).

2. **Chạy bộ Widget Test Hành lý đi kèm mới (`test/accompanied_luggage_ui_test.dart`)**:
   ```powershell
   cd vexgo_accompanied_luggage_worktree; flutter test --no-pub test/accompanied_luggage_ui_test.dart
   ```
   - **Kết quả**: `7/7` kịch bản test pass (`0` fail).

3. **Chạy toàn bộ các bộ test Core, Hành lý đi kèm, Gửi hàng kèm vé, Khứ hồi, Hành khách, Tóm tắt chuyến & Gửi hàng độc lập**:
   ```powershell
   cd vexgo_accompanied_luggage_worktree; flutter test --no-pub test/accompanied_luggage_core_test.dart test/accompanied_luggage_ui_test.dart test/booking_cargo_core_test.dart test/booking_cargo_ui_test.dart test/round_trip_core_test.dart test/round_trip_passenger_lock_test.dart test/round_trip_ui_comprehensive_test.dart test/passenger_info_ui_test.dart test/trip_summary_ui_test.dart test/standalone_shipments_core_test.dart test/standalone_shipments_ui_test.dart
   ```
   - **Kết quả**: `195/195` test pass (`0` fail).

---

## 4. Những điểm chưa thể kiểm chứng trong môi trường hiện tại
- Chưa kiểm thử E2E trực tiếp với máy chủ Backend thật đang chạy live và thiết bị vật lý (do môi trường kiểm thử chạy hoàn toàn qua mock HTTP server nội bộ theo quy định không chạm DB `3306`/`3312`).
- Как đã ghi nhận trong `docs/MOBILE_LUGGAGE_BACKEND_FINDINGS_20261106.md`, `referenceFee` của gói `S/M/L/XL` và bảng giá xe máy (`wave/scooter/big`) là phí tham khảo phía client; khi kết nối Backend thật, cần đối chiếu thêm cấu hình biểu phí trên DB thực tế của nhà xe để hạn chế độ lệch giữa phí tham khảo và `shippingFee` chính thức do `CargoValidationService` trả về.

## 5. Sửa sau review — 06/11/2026

- Kiểm tra khối lượng và tổng số kiện xách tay trước khi sửa selection. Draft sai vẫn nằm trong form; không tạo danh sách theo số lượng nhập và không tự giảm số lượng.
- Lưu kiện hợp lệ đóng editor; sửa kiện cập nhật đúng vị trí, không đếm lại hoặc thêm trùng.
- Chuyển xách tay sang ký gửi giữ nguyên kiện cũ trong lúc nhập. Chỉ khi lưu ký gửi thành công mới đồng thời xóa kiện nguồn và thêm mục ký gửi; Hủy giữ nguyên selection. Giữ số lượng kiện nguồn khi chuyển.
- Thêm `test/accompanied_luggage_regression_test.dart`: 5 ca hồi quy (lưu hợp lệ, số lượng 100 bị chặn, hủy chuyển, chuyển giữ số lượng, sửa không nhân đôi).
- Đã chạy: `flutter analyze --no-pub` → `No issues found!`.
- Đã chạy: `flutter test --no-pub test/accompanied_luggage_regression_test.dart test/accompanied_luggage_ui_test.dart test/accompanied_luggage_core_test.dart test/booking_cargo_core_test.dart test/round_trip_core_test.dart --reporter expanded` → **85/85 pass**.
- Log: `mobile-qa-evidence/luggage-core-20261106/fix-analyze.log` và `fix-regression-tests.log` ở workspace cha.
- Lượt sửa này kiểm thử tự động bằng MockClient/widget, chưa xác nhận trên Android hoặc API thật; chưa build APK/commit/push.

## 6. Thiết kế gọn theo yêu cầu mới — 06/11/2026

### Phạm vi
- Chỉ UI Flutter: `booking_luggage_section_card.dart` và kiểm thử liên quan. Không sửa Backend, schema, Cubit/model/repository, API payload hoặc phép tính tổng thanh toán.
- Quy tắc mới chỉ dự tính phí, không thu cùng tiền vé sẽ do teammate triển khai Backend. Bản UI này không tự bỏ `cargoItems` và không giả định phí đã bị loại khỏi đơn. Tổng tiền/QR vẫn theo dữ liệu hệ thống xác nhận.

### Bố cục và tương tác
- Màn hành khách/tóm tắt chỉ hiển thị hạn mức xách tay, các kiện đã lưu, cước phí dự tính và nút thêm/sửa.
- Nút thêm/sửa mở màn quản lý hành lý riêng có header VexGo, cuộn tránh bàn phím và nút Xong cố định.
- Xách tay thu gọn theo mặc định; gói S/M/L/XL nằm trong một danh sách chọn, hiển thị giới hạn và mức phí dự tính từ API. Không điền kích thước tối đa của gói thành số đo thực tế.
- Kích thước chi tiết, bảo quản và ghi chú chỉ mở khi cần. Kích thước vẫn là số đo thực tế; chưa tạo preset không có cơ sở từ API.
- Mô tả chính sách/công thức/điều kiện nằm trong nút thông tin có vùng bấm 48dp, mở dialog cuộn được với nút Đã hiểu; giá, hạn mức và lỗi vẫn hiển thị trực tiếp.
- Bỏ bảng gói lặp và các chip đổi gói trên từng kiện đã lưu; chỉnh sửa dùng một form thống nhất.
- Cảnh báo khi Back còn mục chưa lưu. Theo dõi khóa checkout và thay đổi phiên ngay cả khi màn khai báo đang mở; tách dữ liệu từng chặng như trước.

### Kiểm chứng của lượt sửa này
- `flutter analyze --no-pub`: No issues found.
- 13 suite liên quan (hành lý, đặt vé kèm hàng, khứ hồi, hành khách, tóm tắt, gửi hàng độc lập): **207/207 pass**. Log workspace cha: `mobile-qa-evidence/luggage-core-20261106/redesign-regression-tests.log`.
- 7 test giao diện mới có font thật: tóm tắt/ⓘ, giữ payload sau xem-sửa, Back với input chưa lưu, khóa checkout trong màn đang mở, đổi phiên, 320dp/640dp có bàn phím và chữ 2x. Log: `redesign-page-tests.log`.
- Ảnh widget fixture có font Plus Jakarta Sans/Material Icons: `redesign-images/luggage-summary.png`, `redesign-images/luggage-manager.png`. Đây là ảnh widget test, không phải bằng chứng chạy Android.
- Chưa kiểm thử UI mới trên điện thoại/API thật; ADB chưa nhận thiết bị khi kiểm tra. Chưa commit/push.


APK UI mới: workspace cha `luggage-preview-20261106/app-debug-accompanied-luggage.apk`. Build debug thành công, SHA-256 `5c5f9deff90b2d57a5c6a90023474709a2c9db8bbdcbfb890f8b94bb17d9c515`; chữ ký hợp lệ. Manifest/shortcut chép APK đã cập nhật; CheckOnly qua. APK/script báo cáo cũ đối chiếu hash không đổi. Chưa chép lên điện thoại (ADB không có thiết bị).


## Cập nhật 07/11/2026 — PR66

Đã đồng bộ contract cước dự tính thu tại bến trên Backend72decda và Mobile; giữ tổng lịch sử. Xem MOBILE_CARGO_COUNTER_PAYMENT_SYNC_20261107.md cho phạm vi, 486 test Flutter, 62 test Backend và giới hạn kiểm thử thật. Ghi chú chờ Backend loại cước khỏi tiền vé ở các phần trước là lịch sử; các vấn đề gói/bảng giá khác chưa mặc nhiên được giải quyết.
