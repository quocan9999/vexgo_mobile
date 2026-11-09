# Handoff Agent UI — Hành lý đi kèm vé

## Worktree bắt buộc

`D:\A_KhoaLuanTotNghiep\HeThongDatVeXeKhachTrucTuyen_Application\vexgo_accompanied_luggage_worktree`

Branch: `feature/mobile-accompanied-luggage`.
Base commit: `8765e1e915fbac1fe840ce6fdbfd943bb67fb7f9` + thay đổi local tương thích accountType/danh mục địa điểm/quên mật khẩu đã sao từ worktree auth-sync. Các thay đổi này là baseline đang chờ commit, không phải code UI Agent tự tạo. Không tạo worktree khác hoặc quay về branch cũ.

Backend source đối chiếu: origin/develop `0159558a6040dad9245796252d4b3ec66362c2dc` của vexgo_web. Backend chạy phục vụ APK báo cáo vẫn là f6ababc. Chưa merge/migrate Backend mới.

Giữ nguyên thư mục report-20261107, APK báo cáo, DB chính3306 và QA báo cáo3312. Không merge/push/commit hoặc chạy seed/migration khi chưa được người dùng yêu cầu.

## Mục tiêu UI

Thay phần “Gửi hàng kèm vé” trong booking bằng “Hành lý đi kèm”, cùng hướng Web mới:

1. Hành lý xách tay nhỏ trong hạn mức miễn phí trả từ API (không hardcode7kg).
2. Hành lý ký gửi: chọn S/M/L/XL, khối lượng/kích thước/số lượng, loại dịch vụ và các thông tin cần thiết.
3. Có thể nhóm phương tiện đặc biệt (xe đạp/xe máy) trong phần mở rộng, cùng contract đã hỗ trợ.
4. Hiển thị mức phí tham khảo, sau tạo đơn dùng đúng phí Backend xác nhận.
5. Luồng Gửi hàng độc lập ở navigation giữ nguyên.

Dùng ui-ux-pro-max và theme/font/header hiện có của VexGo. Không thêm nút demo, fake success hoặc dữ liệu mock vào app Real Mode. Báo tiến độ ngắn trong lúc làm. Trình bày phạm vi trước khi chỉnh.

## Core đã có — không tự viết lại

- `lib/data/models/luggage_policy.dart`
  - LuggagePolicy/LuggagePackage: parse chính sách và giá theo chuyến.
  - CarryOnBag: thông tin xách tay phía client, trong hạn mức mới miễn phí.
  - CheckedLuggageItem: CargoItemDraft + lựa chọn gói tham khảo.
  - LuggageSelection: xác thực và chuyển sang BookingCargoDraft chỉ gồm phần ký gửi.
- `lib/data/repositories/luggage_repository.dart`
  - RealLuggageRepository.load(tripId): GET `/bus-companies/trips/{tripId}/luggage-packages` và dùng CargoRepository để tải loại hàng/sức chứa/điểm đúng chuyến.
  - Không fallback về giá/gói hardcode khi lỗi API.
- `lib/features/user/booking/bloc/luggage_cubit.dart`
  - Một instance theo tripId, số hành khách thực tế và phiên đăng nhập, tách riêng từng chặng.
  - load/select/skip, validationError, referenceFee, requiresServerPricing, exportForBooking.
  - Phản hồi muộn/reload cũ sau skip/đổi phiên/close bị bỏ; chính sách có hạn5phút, CTA phải kiểm tra lại độ mới.
- SetBookingCargoEnabledEvent đã có optional `initialDraft`. Handoff selection vào booking bằng một event; BookingFlowBloc tiếp tục tự kiểm tra loại hàng/sức chứa/điểm và trạng thái khóa.

Không sửa BookingRepository, payload booking/payment, TokenStorage, giữ ghế, idempotency, webhook hoặc fee reconciliation để chiều theo UI. Nếu thấy core thiếu, báo finding cụ thể.

## Nơi nối UI

Các chỗ hiện gọi BookingCargoSectionCard:

- `lib/features/user/booking/presentation/steps/step_4_passenger_info.dart`
- `lib/features/user/booking/presentation/steps/step_5_trip_summary.dart`
- `lib/features/user/round_trip/presentation/widgets/round_trip_passenger_step.dart` (hai chặng)
- `lib/features/user/round_trip/presentation/widgets/round_trip_summary_step.dart`

Widget hiện tại: `lib/features/user/booking/presentation/widgets/booking_cargo_section_card.dart`.
Có thể tạo widget chung mới booking_luggage_section_card.dart và adapter cho các caller trên. Chỉ cập nhật các dòng mô tả phí/nhãn liên quan trong booking_trip_summary_view.dart nếu cần.

Owner/provider cấp booking:
- booking/presentation/screens/booking_flow_screen.dart
- round_trip/presentation/screens/round_trip_booking_screen.dart

Không tạo Cubit mới mỗi build hoặc riêng ở bước4/bước5: cùng chặng phải giữ cùng draft khi chuyển bước. Owner phải dispose/recreate khi chuyến/số ghế thực chọn/phiên thay đổi. Khi số ghế thay đổi, thông báo cần xác minh lại hành lý; không tiếp tục dùng allowance theo số khách cũ. Không chia sẻ selection giữa hai chặng hoặc hai tài khoản.

## Cách áp vào BookingFlowBloc

Sau khi người dùng xác nhận lựa chọn, lấy current trip ID và **số ghế thực đang chọn** tại thời điểm nhấn:

```dart
final draft = luggageCubit.exportForBooking(
  expectedTripId: bookingFlow.state.trip!.numericTripId!,
  expectedPassengerCount: bookingFlow.state.selectedSeats.length,
);
await bookingFlow.applyDraftAction(
  SetBookingCargoEnabledEvent(draft != null, initialDraft: draft),
);
```

Đối chiếu tên getter thực tế nếu cần, không thay core chỉ để khớp snippet.
Khứ hồi dùng coordinator dispatch/command hiện có cho đúng TripLeg, không gọi thẳng Bloc con vượt cơ chế khóa.
Đợi state cargo hoàn tất tải/kiểm tra và cargo.isValid trước khi cho checkout. Không giữ một bản payload thứ hai trong UI.

Xách tay/không thêm ký gửi → draft null → cargo enabled false. Không gửi kiện xách tay miễn phí thành cargoItems và không gửi phí0 để giả báo giá Backend.

## Giới hạn API phải giữ rõ

- API booking hiện chưa nhận `packageCode`, `isFreeCarryOn` hay giá do FE cung cấp. Core không nhét các field đó vào note hoặc payload khác.
- Booking thật vẫn nhận cargoItems và senderPointId/receiverPointId. Không tự thay điểm gửi/nhận bằng ID điểm đón/trả hành khách, vì khác resource.
- Web tự chọn điểm đầu trong một số trường hợp; Mobile phải cho người dùng thấy/chọn điểm hiện có, không tự đoán điểm khi chưa đủ dữ liệu.
- Hành lý xách tay miễn phí hiện chỉ là chính sách/thông tin phía client, không có trường ghi khai báo vào booking Backend. Không nói “Backend đã lưu kiện xách tay”.
- Giá gói ở endpoint chính sách là **tham khảo**. CargoPricingService hiện vẫn tính baseFee từ BangCuocGuiHang; cấu hình NhaXe mới chỉ được sử dụng thêm cho phụ phí. Cách nhân phụ phí trên Web cũng có thể khác cách Backend tính theo đơn.
- Vì vậy không hiển thị giá tham khảo như giá thanh toán chắc chắn, không cộng vào request/payment. Sau POST booking phải giữ tổng shippingFee/totalAmount trả về, kể cả khác tham khảo; có bước xem lại trước chuyển khoản như flow hiện tại.
- Muốn cam kết giá gói/kiểm tra quyền lợi miễn phí ở Backend hoặc lưu mã gói: cần lead bổ sung contract/báo giá có kiểm chứng, không tự giải quyết bằng Dart.
- Không làm QR khứ hồi gộp comboCode trong task này.

## Trạng thái/UI bắt buộc

- Tải chính sách, tải lỗi + thử lại, chính sách đã cũ + tải lại, chuyến không nhận ký gửi, sức chứa không đủ.
- Cho phép “Không thêm hành lý ký gửi” để chỉ đặt vé; không silently bỏ phần đã chọn khi API lỗi.
- ≤ mức miễn phí: đúng nhãn theo API; vượt: yêu cầu chuyển sang ký gửi, không tự giảm cân nặng/đổi gói.
- Một kiện xách tay/hành khách theo hướng Web hiện tại; quá số khách phải báo rõ.
- Gói không vừa cân nặng hiệu dụng/kích thước: báo lỗi ngay, không âm thầm lấy gói rẻ hơn.
- Chữ lớn2x,320dp,landscape+bàn phím, tap target≥48dp; form cuộn, nhãn rõ, tránh rebuild/layout animation theo bàn phím gây giật.
- Khi checkout đã khóa/đơn đã tạo/unknown outcome: chỉ đọc; không cho thay hành lý nhằm tạo lại đơn.

## Kiểm thử bàn giao

Core đã chạy105/105 test liên quan qua; analyze sạch. Đó là model/repository MockClient/widget/regression, không phải E2E API mới hoặc máy thật.

Agent thêm widget tests cho chọn/đổi/xóa gói, miễn phí/vượt hạn mức, retry/skip, giữ draft qua bước4→5→Back, hai chặng riêng, thay số ghế, API lỗi, locked checkout,320dp2x/landscape keyboard.

Viết kết quả tại `docs/MOBILE_ACCOMPANIED_LUGGAGE_UI.md`, nêu đúng file đã sửa, các lệnh và kết quả thực thi, phần chưa test. Không tự nhận PASS trên thiết bị/API thật khi chưa chạy.

## Môi trường API thật đã chuẩn bị — cập nhật 06/11

- Backend0159558 ở vexgo_luggage_backend_worktree, API4012, MySQL3313/container vexgo-luggage-qa-20261106.
- Dịch vụ chạy bằng lệnh workspace: `node .\mobile-qa-evidence\luggage-api-20261106\run-qa.mjs api`. Không đổi API4002/DB3312 của báo cáo.
- Khi build APK hành lý để test, dùng dart-define API_BASE_URL=http://127.0.0.1:4012/api/v1 và adb reverse tcp:4012 tcp:4012; không đổi default API/report runner hoặc ghi đè APK báo cáo.
- Dữ liệu thử có chủ đích: trip791 ngày07/11, route10; miễn phí9kg, góiM95.000. Không hardcode7kg/80.000. Category bưu phẩm1, điểm gửi12/nhận14. Có4mức cước mới chỉ trong clone, mã nguồn Backend không sửa.
- Native Flutter repository/cubit đã đọcAPI4012 thành công1/1case.3bookingHTTP thật xác nhận chênh lệch giữa phí tham khảo/gói và phí chốt; xem `lead-handoff/MOBILE_LUGGAGE_BACKEND_FINDINGS_20261106.md` ở workspace.
- Tài khoản QA cũ trong clone vừa có3đơn chưa thanh toán, có thể gặp429trong30phút; không tắt chống spam để ép UI chạy. Khi test lại chờ chính sách cho phép hoặc nhờ Codex chuẩn bị fixture nhận diện riêng trong clone.
- Chưa nghiệm thu Android/UI mới. Không tự chốt đã có phí gói Backend bảo đảm chỉ từ bảng policy.
