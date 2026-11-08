# Chuẩn bị tích hợp Trợ lý AI vào Mobile

> Cập nhật sau re-review UI: Codex đã nối route/provider và entry Trang chủ/Tài khoản, thêm optional bearer cho GET history. Backend QA checkout local đang0177105 (PR69), DB QA3313 đã backup + nâng migration4 bảng AI; PR GitHub chưa tự merge. Xem `MOBILE_AI_CHATBOT_INTEGRATION.md` cho tình trạng runtime/test/APK mới nhất. Các phần ec75064/17 test/chưa nối route bên dưới là snapshot ban đầu.

Ngày: 08/11/2026. Backend đã merge local develop bằng fast-forward: `72decda` → `ec75064` (PR68 chatbot, PR67 Admin UI). Không có conflict. Mobile đang ở `feature/mobile-accompanied-luggage`, base `8765e1e`, có nhiều thay đổi local đã kiểm thử trước đó; phải giữ nguyên. Tài liệu này chuẩn bị triển khai, không phải báo cáo đã có chatbot trên APK.

Kiểm chứng chuẩn bị: Prisma generate + Nest build exit0; 5 file unit test chatbot, 22/22 ca qua. Dòng log tool execution error trong suite là ca mô phỏng lỗi công cụ và handoff, không phải lỗi kết nối DB thật trong lượt này. Log tại `mobile-qa-evidence/chatbot-prep-20261108/`. Runner log build đầu tiên còn nhãn SHA72decda cũ; code được build là ec75064 đã xác minh bằng git, metadata runner đã cập nhật sau build. Chưa native smoke, migrate hoặc test LLM/Android thật.

Workspace: `D:\A_KhoaLuanTotNghiep\HeThongDatVeXeKhachTrucTuyen_Application`.

## Phân công và thứ tự

1. Codex phụ trách model/repository/Cubit/session/auth/validation và test contract.
2. Agent UI làm màn Trợ lý AI theo contract core đã chốt, giữ chat nhân viên đang hoạt động. Có thể chuẩn bị proposal UI ngay; chỉ nối code sau khi các file core bên dưới tồn tại. Không tự viết một core/API client song song.
3. Codex review, nối navigation, chạy hồi quy và kiểm thử API/Android. Chưa tạo nhánh/commit/worktree UI riêng trong đợt chuẩn bị này; không giao Agent chỉnh đồng thời worktree đang có thay đổi chưa commit.

Phạm vi đầu tiên: hỏi đáp chính sách, nguồn tham khảo, gợi ý câu hỏi/chuyến, chuyển người dùng tới chat nhân viên qua thao tác rõ ràng. Không tự đặt vé, thanh toán, hủy vé hoặc thay đổi vận đơn từ câu trả lời AI.

## Contract Backend ec75064

Prefix chung `/api/v1`, dùng ApiConfig của Mobile; không hardcode localhost4000 như fallback Web.

| Method/path | Auth | Contract |
| --- | --- | --- |
| POST `/ai-chatbot/messages` | OptionalAuth | body `{message, sessionToken?, nhaXeId?}`; response envelope `{data: response}` |
| GET `/ai-chatbot/suggestions` | Public | `{data: [{id,category,question,description}]}` |
| GET `/ai-chatbot/sessions/:sessionToken/messages` | Public hiện tại | `{data: {sessionToken,status,createdAt,messages}}`; 404 `SESSION_NOT_FOUND` |

Response gửi tin gồm `sessionToken`, `reply`, `intent`, `citations`, optional `suggestedTrips`, optional `suggestedQuestions`, `requiresHumanHandoff`, optional `handoffReason`, `latencyMs`.

Citation: `{documentCode,title,hierarchyPath,relevanceScore}`. Đây là nguồn nội bộ, không phải URL; không tự tạo link.

Trip: `{tripId,code,operator,origin,destination,departureDate,departureTime,arrivalTime,vehicleType,price,availableSeats,bookingUrl}`. Ngày hiện tại YYYY-MM-DD; giờ HH:mm, arrivalTime/price có thể null. `bookingUrl` là đường dẫn Web `/trips/<id>`; không mở trực tiếp như route Flutter. Core phải lấy tripId, tải lại trip bằng API chuẩn rồi dùng flow chọn chuyến hiện có; giá/số ghế gợi ý không là xác nhận tồn kho.

History message: `{id,role,content,intent,citations,toolCalls,requiresHumanHandoff,createdAt}`. Không parse bằng cùng shape response gửi tin. `toolCalls` JSON có thể chứa gợi ý chuyến; phải kiểm tra shape, không thực thi như lệnh.

DTO hiện chưa giới hạn MaxLength message hoặc validate UUID sessionToken. Mobile trim, chặn trắng và đặt giới hạn UX 2000 ký tự; đây là giới hạn client dự kiến, không phải bảo vệ server.

## Core dự kiến — quyền sở hữu Codex

Các file dưới đây ĐÃ triển khai core local sau đợt chuẩn bị:

- `lib/data/models/ai_chatbot_model.dart`: immutable DTO cho response/suggestion/history/citation/trip; parse chặt trường bắt buộc, không bịa dữ liệu thiếu.
- `lib/data/repositories/ai_chatbot_repository.dart`: dùng ApiClient, unwrap `data`, encode sessionToken trong path; POST optionalAuth và expectedSessionVersion.
- `lib/features/user/ai_chatbot/ai_chatbot_cubit.dart`: state lời nhắn/nháp/gợi ý/loading/error/handoff; gửi một lần, hủy hiệu lực phản hồi cũ bằng generation/sessionVersion khi đổi phiên, tài khoản, nhà xe hoặc đóng.
- `test/ai_chatbot_core_test.dart`: contract, lỗi HTTP, session isolation, double tap, late response, draft retention và history404.

### API core đã có để Agent UI dùng

`RealAiChatbotRepository({ApiClient? client})` triển khai `AiChatbotRepository`: `suggestions()`, `send(message:, sessionToken:, companyId:)`, `history(sessionToken)`. Repository dùng envelope thật, POST optionalAuth, kiểm tra sessionVersion trước/sau kết quả, không gọi LLM provider.

Tạo `AiChatbotCubit(repository: RealAiChatbotRepository(), companyId: optionalId)` ở scope màn AI bằng BlocProvider (dispose khi đóng màn). Không bắt buộc thêm provider toàn app; Cubit tự nghe TokenStorage.sessionChanges/sessionInvalidations. Không gọi `newConversation` khi access-token refresh bình thường.

State UI đọc:

- `exchanges`: danh sách `AiChatExchange(question, answer)` đã ACK; answer có reply/citations/suggestedTrips/suggestedQuestions/handoff. Bubble pending lấy từ draft khi sending; chưa thêm exchange trước ACK.
- `draft`, `canSend`, `sending`, `uncertain`, `error`; `setDraft(text)`, `send()` không nhận tham số. Có thể sửa draft trong lúc gửi; ACK không xóa draft mới người dùng đang nhập.
- `suggestions`, `loadingSuggestions`, `suggestionsError`; `loadSuggestions()` chủ động từ màn UI. Lỗi gợi ý không cản gửi thủ công.
- `requiresHumanHandoff`, `handoffReason`: CTA tới chat CSKH phải do người dùng bấm. Core không gửi tin hay chuyển hướng.
- `loadingHistory`, `historySnapshot`, `historyError`; `readHistory()` chỉ đọc token của phiên đang giữ. Snapshot lịch sử không tự thay local exchanges hoặc gỡ uncertain.
- `setCompany(id)` reset toàn phiên khi đổi nhà xe; `newConversation(keepDraft: true/false)` là thao tác người dùng xác nhận để bắt đầu phiên khác, không xóa request/phiên trên server.
- `sessionToken` là capability nội bộ, không render/log/cache route; UI không nhập token từ ngoài.

Quan trọng mới từ source: ec75064 **chỉ lưu ASSISTANT, chưa lưu USER**; history không có requestId để gắn một câu trả lời với POST vừa timeout. Vì vậy không dùng history để tuyên bố đã khôi phục đầy đủ hội thoại hoặc tự cho gửi lại. Giữ exchanges local, dùng historySnapshot như thông tin đọc lại riêng. Nếu uncertain: khóa gửi; có thể đọc lịch sử khi token đã biết, hoặc cho user chủ động bắt đầu hội thoại mới (giữ nháp tùy chọn), nói rõ câu hỏi cũ có thể đã xử lý. Cần lead sửa lưu USER/idempotency/correlation trước phục hồi đầy đủ sau mất kết nối.

Model chuyến cố ý không cung cấp bookingUrl để UI thực thi; chỉ dùng tripId gọi `TripRepository.getTripById` rồi kiểm tra phiên/mounted trước navigation. Chưa viết navigation vào core hoặc app để tránh chồng phần UI. Agent không tự tạo giá, ghế hoặc payload booking từ suggestedTrip.

17 ca test chatbot đã chạy qua trong lượt triển khai đầu. Kết quả hồi quy/analyze cuối xem `MOBILE_AI_CHATBOT_CORE.md`; chưa kết nối API chatbot thật hoặc Android.

Không đưa GROQ/JINA key hoặc URL provider vào Dart/APK. Không gọi trực tiếp LLM từ điện thoại. Không tự retry POST vì chưa có idempotency key: khi timeout phải giữ nháp, cho biết chưa xác định kết quả; nếu đã biết token thì đọc lịch sử trước khi đề nghị gửi lại. Request đầu tiên chưa có token mà timeout thì không thể khôi phục chắc chắn phiên server.

SessionToken có quyền truy cập lịch sử theo contract hiện tại: không log, không đưa URL analytics, không dùng chung giữa tài khoản/guest/nhà xe. Bản đầu ưu tiên giữ trong bộ nhớ; nếu cần phục hồi sau đóng app phải có thiết kế secure storage theo identity riêng. Đổi tài khoản phải xóa cả state đang hiển thị, overlay và pending response. Không chỉ xóa cache repository.

## UI dự kiến — quyền sở hữu Agent UI

- `lib/features/user/ai_chatbot/presentation/screens/ai_chatbot_screen.dart` và widgets cùng thư mục; không sửa repository/Cubit/core hoặc chat CSKH hiện có.
- Nhãn rõ “Trợ lý AI”; dùng màu/font VexGo hiện tại, header gọn, vùng tin nhắn và composer có SafeArea, tự cuộn khi hợp lý, keyboard không làm nhảy toàn màn.
- Gợi ý câu hỏi ban đầu; bubble user/AI; trạng thái đang trả lời; lỗi giữ nháp; nút gửi khóa khi đang gửi. Không render lỗi server/stack/token ra màn hình.
- Nguồn tham khảo mở rộng/thu gọn; card chuyến chỉ dùng dữ liệu server; giá null ghi chưa có giá. Không dùng dữ liệu demo để lấp phần thiếu.
- Khi `requiresHumanHandoff=true`, hiện CTA “Chat với nhân viên”. Backend chỉ trả tín hiệu, không tự tạo/chuyển hội thoại CSKH. Không ghi “đã kết nối” chỉ dựa trên câu reply của AI. Không tự chuyển hoặc gửi nội dung cho nhân viên khi user chưa bấm.
- Navigation dự kiến một entry trong khu hỗ trợ/Trang chủ, không thêm tab bottom navigation. `AppRoutes.supportChat` hiện là chat nhân viên và phải tiếp tục hoạt động.
- Route dự kiến `/ai-chatbot` do Codex nối trong `lib/app/routes.dart`; session sync nối tại `lib/app/app.dart` sau khi core sẵn sàng.
- Widget QA: màn hẹp, bàn phím, text scale2x, nội dung dài, danh sách nguồn/chuyến, empty/error/retry, quay lại, guest/login/logout đổi tài khoản.

## Runtime và cấu hình trước test thật

Backend mới có migration `20261106080500_add_ai_chatbot_rag_models`: thêm `AiKnowledgeDocument`, `AiKnowledgeChunk`, `AiChatSession`, `AiChatMessage` và FK/index. Chưa áp dụng DB trong lượt chuẩn bị này. Phải backup QA3313 trước migrate deploy; không reset/seed DB chính3306 hoặc DB báo cáo3312.

HybridRetrievalService tự index kiến thức mặc định trong onApplicationBootstrap, có ghi DB khi khởi động Backend mới. Phải rà nội dung chính sách mặc định với lead trước dùng cho khách thật, nhất là hủy/hoàn tiền và hành lý. Không coi dữ liệu mặc định là quy chế đã phê duyệt.

Biến Backend: `GROQ_API_KEY`, `AI_LLM_BASE_URL`, `AI_LLM_MODEL`, `JINA_API_KEY`. File `.env.example` có placeholder; copy file example chưa đủ để xác nhận key hoạt động. Không ghi secret vào tài liệu, Git hoặc APK. Thiếu/lỗi LLM có template fallback, thiếu/lỗi Jina có vector fallback; câu trả lời xuất hiện không chứng minh LLM thật đã chạy.

Runner QA hiện tại dùng4012/3313, tắt email/push. Chưa restart API trong lượt này. Phải nạp cấu hình riêng QA và kiểm tra dịch vụ trước native smoke. Bản APK/shortcut báo cáo và gói hành lý đã đóng trước đó không tự có chatbot.

## Điểm cần lead xác nhận/sửa trước phát hành

Quan sát từ source ec75064, chưa chứng minh khai thác qua API thật:

1. GET history Public và POST reuse session chỉ tìm token, chưa đối chiếu chủ tài khoản. Cần xác định token-capability có chủ đích hay bổ sung owner check/expiry; client isolation không thay thế bảo vệ server.
2. Tool tra cứu vé/vận đơn chỉ kiểm tra số điện thoại nếu input có số, trong khi trả tên/số điện thoại. Cần bắt buộc xác minh hoặc kiểm tra ownership trước trả thông tin cá nhân. Không coi việc ẩn nút ở Mobile là sửa được vấn đề này.
3. Tool vé có cancellationEligible dựa vào `status !== HUY` và cancellationFeeRate0.1 cố định; cần dùng rule/quote thật. Mobile không sử dụng các giá trị AI này để cho phép hủy hoặc tính phí.
4. Nội dung mặc định và câu AI “đang kết nối nhân viên” cần thống nhất với cơ chế handoff chỉ là tín hiệu hiện có. Lỗi session persistence có thể bị catch rồi trả lời bình thường; cần test history thật.

Có thể làm model/state/UI và fixture trước; chưa bật chatbot AI cho người dùng thật trước khi lead xử lý/ra quyết định cho các điểm dữ liệu cá nhân.

## Checklist kiểm thử tích hợp

Fixture/unit/widget và native API/device phải báo riêng. Test guest, auth, gửi lần đầu/tiếp nối, suggestions, lịch sử/404, đổi identity giữa request, timeout/mất mạng/429/5xx, nguồn tham khảo, tripId navigation, yêu cầu nhân viên. Native dùng dữ liệu QA có chủ đích, không gửi PII/đơn thật sang LLM khi chưa cần. Xác nhận Groq/Jina thật riêng với fallback. Không thanh toán hoặc sửa booking chỉ từ câu chat.
