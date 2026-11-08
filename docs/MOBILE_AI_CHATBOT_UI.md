# Mobile AI Chatbot UI — Implementation & Verification Report

> Sau báo cáo Agent: Codex đã nối UI vào Trang chủ/Tài khoản và route chính, sửa auth GET history;30 test chatbot/navigation qua và toàn bộ971 test Flutter qua. Xem `MOBILE_AI_CHATBOT_INTEGRATION.md` cho kiểm chứng tích hợp, runtime QA và APK. Các mục hướng dẫn nối route/count27 phía dưới mô tả thời điểm bàn giao của Agent.

## 1. Tổng quan & Bối cảnh triển khai
- **Worktree**: `D:\A_KhoaLuanTotNghiep\HeThongDatVeXeKhachTrucTuyen_Application\vexgo_accompanied_luggage_worktree`
- **Branch**: `feature/mobile-accompanied-luggage`
- **Handoff đầu vào**: `docs/MOBILE_AI_CHATBOT_INTEGRATION_HANDOFF.md`, `docs/MOBILE_AI_CHATBOT_CORE.md` & phản hồi review `mobile-qa-evidence/chatbot-ui-review-20261108/REVIEW.md`.
- **Skill áp dụng**: `/ui-ux-pro-max` (VexGo `DiscoveryTheme`, compact header, `SafeArea`, auto-scroll mượt, responsive `320x640` ở `2.0x` textScale kể cả khi mở bàn phím `viewInsets.bottom = 300` và mở thanh xác nhận Hội thoại mới, landscape `640x360` với bàn phím mở `viewInsets.bottom = 160`, touch target `>= 48x48dp`, chống tràn giao diện).

---

## 2. Danh sách File UI & Test đã tạo / cập nhật

### 2.1. Màn hình & Widgets (`lib/features/user/ai_chatbot/presentation/`)
1. `lib/features/user/ai_chatbot/presentation/screens/ai_chatbot_screen.dart`
   - Màn hình chính **“Trợ lý AI”** (`AiChatbotScreen`), khởi tạo và đóng `AiChatbotCubit(repository: RealAiChatbotRepository(), companyId: initialCompanyId)` theo vòng đời màn hình thông qua `BlocProvider`.
   - Tách biệt hoàn toàn với **Chat hỗ trợ nhân viên** (`SupportChatScreen` / `/support-chat`), có nút chuyển nhanh sang hỗ trợ nhân viên ở thanh tiêu đề.
   - Bắt và giữ câu hỏi đang gửi (`_pendingSentQuestion`) để hiển thị chính xác bong bóng câu hỏi đang gửi ngay cả khi người dùng gõ nháp câu tiếp theo trong lúc chờ phản hồi (`sending == true`).
   - **Quản lý vòng đời tra cứu chuyến xe (`_tripLookupGeneration`)**:
     - Mỗi lượt bấm **"Xem & chọn chuyến"** tăng `_tripLookupGeneration` và kiểm tra chặt chẽ `mounted`, `lookupGeneration == _tripLookupGeneration`, `TokenStorage.sessionVersion` và `companyId` trước mọi cập nhật trạng thái/lỗi hoặc điều hướng.
     - Mọi thao tác **Hội thoại mới / Tạo phiên mới**, **Bỏ lọc nhà xe**, **đổi tài khoản / đăng xuất**, hoặc **đóng màn hình (`dispose`)** đều tăng `_tripLookupGeneration` để vô hiệu hóa ngay lập tức kết quả `getTripById` muộn từ hội thoại cũ.
   - **Xác minh lịch trình khởi hành thực tế từ `TripModel` (`_resolveVerifiedDepartureDate`)**:
     - Lấy ngày khởi hành trực tiếp từ `trip.rawDepartureTime` của `TripModel` đã xác minh từ API (chuyển đổi múi giờ nghiệp vụ Việt Nam `UTC+7` theo đúng contract `TripModel.normalizeTime` / `RoundTripRequest`).
     - Tuyệt đối không ghép `TripModel` mới với `suggested.departureDate` cũ của AI và không suy diễn `DateTime.now()` khi thiếu ngày hợp lệ; nếu `TripModel` thiếu ngày khởi hành hợp lệ thì hiển thị cảnh báo lỗi an toàn và không điều hướng.
   - **Bố cục thanh xác nhận Hội thoại mới chống tràn (`_buildNewConversationConfirmBar`)**:
     - Đặt bên trong `ListView` cuộn chính (kèm tự động cuộn lên đầu danh sách khi mở xác nhận) và kích hoạt chế độ compact khi mở bàn phím kết hợp phóng chữ lớn (`320x640`, `2.0x` textScale, `viewInsets.bottom = 300`), đảm bảo `0` lỗi `RenderFlex overflow`.
2. `lib/features/user/ai_chatbot/presentation/widgets/ai_chatbot_suggestions_view.dart`
   - Hiển thị trạng thái tải gợi ý ban đầu (`loadingSuggestions`), thẻ lỗi kèm nút **Thử lại** (`suggestionsError` -> `loadSuggestions()`) mà không khóa ô nhập câu hỏi thủ công, và danh sách thẻ gợi ý (`AiChatSuggestion`: badge `category`, `question`, `description`).
3. `lib/features/user/ai_chatbot/presentation/widgets/ai_chatbot_exchange_item.dart`
   - Hiển thị cặp `AiChatExchange(question, answer)` và bong bóng tạm thời khi `sending == true` kèm chỉ báo **"Trợ lý AI đang trả lời…"**.
   - **Citations (`AiCitation`)**: Khung thu gọn/mở rộng (**"Nguồn tham khảo nội bộ (N)"**) hiển thị `documentCode`, `title`, `hierarchyPath`. Không sinh liên kết URL cho tài liệu nội bộ.
   - **Suggested Trips (`AiSuggestedTrip`)**: Hiển thị đầy đủ thông tin chuyến xe từ máy chủ; khi `price == null` hiển thị rõ **"Chưa có giá"** (không tự sinh giá giả lập). Nút **"Xem & chọn chuyến"** bỏ qua `bookingUrl` và gọi luồng xác thực `TripRepository.getTripById`.
   - **Human Handoff (`requiresHumanHandoff`, `handoffReason`)**: Hiển thị thẻ hướng dẫn trung thực rằng hệ thống chỉ phát tín hiệu gợi ý và **chưa tự động kết nối hay gửi nội dung** sang nhân viên cho đến khi người dùng bấm **"Chat với nhân viên"**.
   - **Follow-up Questions (`suggestedQuestions`)**: Các chip gợi ý câu hỏi tiếp theo sau mỗi phản hồi, tự động khóa khi `sending` hoặc `uncertain`.
4. `lib/features/user/ai_chatbot/presentation/widgets/ai_chatbot_status_banners.dart`
   - `AiChatbotUncertainBanner`: Khi `uncertain == true` (timeout / 5xx / malformed 200), giải thích rõ câu hỏi trước có thể đã hoặc chưa được xử lý và không tự gửi lại; cung cấp nút **"Kiểm tra phản hồi đã lưu"** (`readHistory()` khi `sessionToken != null`), **"Hội thoại mới (Giữ nháp)"** (`newConversation(keepDraft: true)`) và **"Hội thoại mới (Xóa nháp)"** (`newConversation(keepDraft: false)`).
   - `AiChatbotErrorBanner`: Hiển thị thông báo lỗi thân thiện đã chuẩn hóa từ `AiChatbotCubit`, giữ nguyên bản nháp để người dùng chỉnh sửa/thử lại, tuyệt đối không lộ `sessionToken`, raw server message hay stack trace.
   - `AiChatbotHistoryCard`: Hiển thị `historySnapshot` tách biệt dưới tiêu đề **"Bản ghi phản hồi từ máy chủ (Chỉ đọc)"**, mô tả trung lập tương thích cả Backend `ec75064` (chỉ `ASSISTANT`) và PR 69 (`USER` + `ASSISTANT`), nêu rõ bản ghi chỉ đọc không tự thay thế hội thoại trên máy hay tự mở khóa trạng thái gián đoạn.
5. `lib/features/user/ai_chatbot/presentation/widgets/ai_chatbot_composer.dart`
   - Ô nhập câu hỏi đa dòng, đồng bộ hai chiều với `state.draft` mà không làm nhảy vị trí con trỏ khi người dùng đang gõ.
   - Nút gửi câu hỏi (`48x48dp`) chỉ bật khi `state.canSend == true`, nhưng vẫn cho phép người dùng sửa/gõ bản nháp mới trong lúc `sending == true`.
6. `lib/features/user/ai_chatbot/presentation/widgets/ai_chatbot_entry_card.dart`
   - Thẻ/nút vào màn hình **“Trợ lý AI”** (`AiChatbotEntryCard`) hỗ trợ điều hướng qua route `/ai-chatbot` (truyền `extra: companyId`) hoặc fallback `MaterialPageRoute`, sẵn sàng để Codex gắn vào Home/Support và `lib/app/routes.dart`.

### 2.2. Widget Tests (`test/ai_chatbot_ui_test.dart`)
- Bao phủ 10 kịch bản kiểm thử toàn diện:
  1. Tải gợi ý ban đầu (`loadSuggestions`), lỗi gợi ý + nút Thử lại không chặn nhập/gửi câu hỏi thủ công, bấm gợi ý gửi câu hỏi và không lộ `sessionToken` trên UI.
  2. Trạng thái `sending` hiển thị bong bóng câu hỏi đang gửi + **"Trợ lý AI đang trả lời…"**, khóa nút gửi, cho phép gõ bản nháp mới trong lúc chờ phản hồi và giữ nguyên bản nháp mới sau khi nhận ACK; lỗi `429` giữ lại nháp và không lộ thông báo lỗi thô từ server.
  3. Thu gọn/mở rộng `citations` (`documentCode`, `title`, `hierarchyPath`), hiển thị `suggestedTrips` với `price == null` (**"Chưa có giá"**) và `price != null`, xác thực chuyến xe qua `TripRepository.getTripById` trước khi mở `seatSelection`, và hiển thị cảnh báo an toàn khi không tải được chuyến.
  4. `requiresHumanHandoff == true` hiển thị lý do + nút **"Chat với nhân viên"**, không tự động chuyển màn hình cho đến khi người dùng bấm nút.
  5. Trạng thái `uncertain == true` (HTTP 500) khóa gửi lại, giữ bản nháp, cho phép đọc lịch sử chỉ đọc (`readHistory()`) và xử lý lỗi `404 SESSION_NOT_FOUND` mà không làm mất lịch sử cục bộ hay tự mở khóa `uncertain`, đồng thời hỗ trợ tạo hội thoại mới giữ nháp (`newConversation(keepDraft: true)`).
  6. Đổi tài khoản/đăng nhập/đăng xuất qua `TokenStorage` xóa toàn bộ hội thoại hiển thị, bản nháp, thanh xác nhận và chặn điều hướng từ yêu cầu `getTripById` đang chạy của phiên trước; kiểm tra bộ lọc `companyId` và nút Back.
  7. Kiểm thử responsive `/ui-ux-pro-max`: màn hình hẹp `320x640` với `textScale = 2.0x` (nội dung dài, citations mở rộng, suggested trips, handoff) và màn hình ngang `640x360` khi bàn phím mở (`viewInsets.bottom = 160`) đạt `0` lỗi overflow, kích thước vùng chạm `>= 48x48dp`.
  8. **[Review P2 #1]** Kết quả `getTripById` hoàn tất muộn sau khi người dùng bấm **Hội thoại mới / Tạo phiên mới** bị chặn hoàn toàn, không gọi `onOpenVerifiedTrip` hay điều hướng.
  9. **[Review P2 #2]** Khi `getTripById` trả về chuyến xe đã dời lịch (`rawDepartureTime: '2026-11-16T15:00:00.000Z'`), ngày đặt vé được lấy từ chuyến đã xác minh theo múi giờ `UTC+7` (`2026-11-16`) thay vì ngày gợi ý cũ của AI (`2026-11-15`); khi thiếu ngày hợp lệ thì báo lỗi và không suy ra hôm nay.
  10. **[Review P2 #3]** Mở thanh xác nhận **Hội thoại mới** trên màn hình `320x640`, `textScale = 2.0x`, bàn phím mở `viewInsets.bottom = 300` hiển thị đầy đủ trong vùng cuộn và đạt `0` lỗi overflow.

---

## 3. Kết quả Kiểm chứng Thực tế (Verification Outputs)

1. **Static Analysis**:
   - Lệnh: `flutter analyze --no-pub`
   - Kết quả: `No issues found!` (0 errors, 0 warnings).

2. **AI Chatbot Core & UI Tests**:
   - Lệnh: `flutter test --no-pub test/ai_chatbot_core_test.dart test/ai_chatbot_ui_test.dart`
   - Kết quả: `27/27` tests pass (`17` core tests + `10` UI widget tests).
