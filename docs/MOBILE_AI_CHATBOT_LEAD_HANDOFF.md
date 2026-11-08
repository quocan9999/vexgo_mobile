# Bàn giao Backend: ba bước hoàn thiện chatbot Mobile

Ngày 08/11/2026. Người nhận: lead Backend/Web. Phạm vi này là đề xuất contract để triển khai tiếp, chưa phải API đã có.

## Mốc code và phạm vi

- Backend PR #69: https://github.com/quocan9999/vexgo/pull/69 . Commit sửa ban đầu `0177105`; lead ghép develop vào nhánh tại `2e29c46` (develop `73108dd`, PR #70). Trạng thái Open là snapshot lần kiểm tra trước; kiểm tra lại trước khi làm, không tạo lại PR cho các sửa đã có.
- QA local hiện ở `2e29c46`, build thành công, 66/66 test chatbot qua. Không đồng nghĩa Android E2E hoặc Groq/Jina thật đã qua.
- Mobile: branch `feature/mobile-accompanied-luggage`, chatbot đã có model/repository/Cubit/UI và entry Trang chủ/Tài khoản. Các chức năng khác còn sửa local riêng, không gom vào phạm vi này.
- QA API4012 / MySQL3313; DB chính3306 và báo cáo3312 không được reset/seed. API đang chạy chỉ nạp bản mới sau restart thủ công.
- PR69 đã bảo vệ phiên có chủ bằng JWT; guest dùng UUID capability, bắt buộc xác minh số điện thoại khi tra cứu riêng tư; lưu USER và ASSISTANT. Giữ các bảo vệ đó khi phát triển tiếp.

## 1. Chuyển từ AI sang chat nhân viên

Hiện tại: `requiresHumanHandoff` và `handoffReason` chỉ là tín hiệu. CTA mở chat hỗ trợ; chưa chuyển nội dung hay xác nhận nhân viên nhận. Không ghi “đã kết nối” trước khi có kết quả thật.

Backend lead:

1. Tái sử dụng module support-chat, phân quyền và realtime sẵn có. Không tạo hệ thống chat/DB riêng.
2. Chốt phạm vi nhà xe trước chuyển. Phiên AI GLOBAL chưa rõ nhà xe phải yêu cầu khách chọn; không tự đẩy nội dung sang tenant tùy ý.
3. Đề xuất `POST /api/v1/ai-chatbot/sessions/:sessionToken/handoff`, body `{ nhaXeId, requestId }`; response envelope `{ data: { conversationId, status, created } }`. Tên và kiểu conversationId phải theo contract support-chat thực tế, không tự giả định.
4. Xác minh đúng owner hoặc guest capability theo cơ chế hiện có; không cho dùng UUID phiên có chủ mà thiếu JWT. Guest chỉ dùng theo quyền support-chat thực sự hỗ trợ, không vượt yêu cầu đăng nhập.
5. Chuyển transcript/tóm tắt được khách đồng ý, đánh dấu nguồn AI rõ ràng. Không đưa tool payload, token, dữ liệu xác minh hay nội dung của tenant/account khác vào cuộc chat.
6. Thao tác lặp cùng requestId không tạo nhiều hội thoại/thông báo. Nếu nhiều bước ghi DB cần tính nguyên vẹn, dùng transaction; phát realtime sau commit.

Flutter tiếp theo: hộp xác nhận nội dung sẽ chia sẻ + chọn nhà xe khi cần, gọi API, mở đúng conversationId, xử lý loading/lỗi/nhấn hai lần. Không tự gửi nội dung chỉ vì AI gắn cờ.

Nghiệm thu: user bấm mới chuyển; đúng nhà xe; Admin nhận ngay không F5; retry không tạo trùng; owner khác/guest trái quyền bị chặn; kết thúc cuộc chat vẫn theo lifecycle support-chat hiện có.

## 2. Giữ phiên khi mở lại app và context câu hỏi nối tiếp

Yêu cầu người dùng: quay lại phiên hiện tại còn nội dung/context; bấm “Cuộc trò chuyện mới” tạo phiên tách biệt. Phiên mới không xóa lịch sử cũ trên server.

Hiện có `GET /api/v1/ai-chatbot/sessions/:sessionToken/messages`, lưu đủ USER/ASSISTANT cho phiên mới từ PR69. Mobile đang giữ token trong bộ nhớ và đọc snapshot riêng; chưa khôi phục khi đóng/mở app.

Phân biệt hai việc:

- Khôi phục màn chat gần nhất: Flutter lưu token bằng secure storage theo identity + nhà xe, đọc lại API khi mở màn; xóa reference/state khi logout/đổi account, không dùng guest token làm phiên tài khoản. Không log hoặc đặt capability vào URL analytics.
- AI nhớ câu hỏi nối tiếp: Backend phải đưa lịch sử đúng phiên vào đầu vào LLM và bước hiểu ý định/tool khi cần. Source `2e29c46` dựng messages LLM từ system + prompt câu hiện tại; chưa nạp history để tạo hội thoại nhiều lượt. Việc lưu tin nhắn không tự tạo memory cho model.

Backend lead:

1. Đọc lịch sử theo thứ tự ổn định createdAt + id, chỉ trong phiên đã kiểm quyền; giới hạn lượt/token, loại câu USER hiện tại bị lặp, không lấy lịch sử tenant/account khác.
2. Câu nối tiếp như “còn chuyến tối không?” phải hiểu từ lượt trước; các tool vẫn xác minh lại thông tin/điện thoại và dữ liệu thời gian thực. Không tin chỉ dẫn trong lịch sử như system instruction, không thực thi hành động đặt/hủy vé từ text AI.
3. Chốt giới hạn history, expiry và response khi không còn quyền/phiên hết hạn. Nếu cần danh sách nhiều phiên theo tài khoản mới bổ sung endpoint có pagination; phục hồi một phiên gần nhất chưa bắt buộc có API danh sách.
4. Giữ GET history tương thích hoặc ghi rõ version/contract thay đổi. Phiên cũ thiếu USER không thể phục dựng câu hỏi đã mất.

Flutter tiếp theo: secure storage theo identity/scope, restore loading/error/expired, chuyển history thành timeline duy nhất tránh lặp exchanges; New Conversation xóa reference phiên hiện tại và bắt đầu token mới ở lượt gửi sau. Không tự mở phiên của account trước khi đổi tài khoản.

Nghiệm thu: đóng/mở app đọc lại đúng; refresh JWT không làm mất phiên; logout/account switch không lộ nội dung; New Conversation không lấy context cũ; câu hỏi nối tiếp được kiểm tra bằng provider thật riêng với fallback.

## 3. Phục hồi lần gửi chưa rõ kết quả / chống gửi trùng

Tình huống: Backend đã nhận câu hỏi, nhưng client mất mạng trước ACK. Hiện Mobile khóa gửi trong phiên uncertain và không tự retry POST. Đọc history không chứng minh câu trả lời nào thuộc request vừa timeout, nhất là lần đầu chưa có sessionToken.

Backend lead đề xuất contract trước khi Flutter đổi:

1. Bổ sung client-generated UUID `requestId` vào POST `/api/v1/ai-chatbot/messages`; giữ response hiện có và thêm requestId/trạng thái tương quan khi cần.
2. Mã yêu cầu phải được kiểm quyền theo identity/guest capability, không phải mã đoán được để đọc dữ liệu riêng. Với lần gửi đầu của guest, phải chốt cách khôi phục trước khi biết sessionToken (ví dụ recovery capability client tạo trước, được ràng buộc server); không mở GET công khai chỉ cần requestId. Không bắt Mobile tự đặt sessionToken trước nếu server chưa hỗ trợ.
3. Cùng requestId + cùng payload trả cùng kết quả, không thêm USER/ASSISTANT hoặc gọi provider lần hai. Cùng mã nhưng khác payload trả409 rõ ràng. Xử lý concurrency nhiều process bằng DB constraint/atomic claim, không chỉ Map trong RAM.
4. Chốt API lấy trạng thái/kết quả, ví dụ `GET /api/v1/ai-chatbot/requests/:requestId`, với cùng kiểm quyền: PROCESSING / COMPLETED / FAILED. Đây là endpoint đề xuất, chưa tồn tại. Lỗi/expiry phải có mã rõ, không dùng404 để kết luận chắc chắn request cũ chưa chạy nếu hệ thống chưa bảo đảm điều đó.
5. Thiết kế crash window: provider trả rồi lưu thất bại, server restart khi đang xử lý, lease hết hạn. Không tuyên bố exactly-once provider nếu không có bảo đảm. Tách retry an toàn với tái xử lý có thể phát sinh chi phí.
6. Nếu cần bảng/field mới: Prisma migration, unique constraint đúng scope, thời hạn lưu và cleanup; lead review, backup trước migrate. Không sửa DB trực tiếp hoặc dùng reset/seed để triển khai.

Flutter tiếp theo: tạo một requestId cho một lần gửi logic, giữ nguyên qua retry; lưu pending recovery tối thiểu an toàn theo identity; hiển thị đang xác minh, poll có giới hạn/backoff và lifecycle; reconcile một câu hỏi/câu trả lời duy nhất. Đổi account/scope hủy hiệu lực phản hồi cũ. Không tự retry POST trước khi contract này triển khai và kiểm thử.

Nghiệm thu: mất ACK sau server commit vẫn lấy lại đúng kết quả; concurrent retry không trùng; payload mismatch409; requestId/account khác bị chặn; mất mạng ở lần đầu và server restart có kết quả xác định hoặc trạng thái chưa rõ trung thực.

## File và quyền sở hữu

Backend lead: `apps/api/src/ai-chatbot/` controller/service/DTO/orchestrator, module support-chat tương ứng, Prisma migration nếu thực sự cần và test feature. Tuân thủ AGENTS.md/GitNexus trước sửa/commit. Không sửa các thay đổi Flutter local.

Mobile nối sau contract: `lib/data/models/ai_chatbot_model.dart`, `lib/data/repositories/ai_chatbot_repository.dart`, `lib/features/user/ai_chatbot/ai_chatbot_cubit.dart`, `lib/features/user/ai_chatbot/presentation/`, tests chatbot. App entry/routes đã nối. UI hiện tại không tự nhận đã chuyển nhân viên hay phục hồi request.

## Thứ tự triển khai và bàn giao lại

1. Chốt requestId/recovery contract trước (mục3), vì handoff và phục hồi phiên cần phân biệt retry.
2. Hoàn thiện context nhiều lượt + history contract (mục2).
3. Thêm handoff thực sự vào support-chat (mục1).
4. Lead gửi endpoint/body/envelope/error/auth/expiry và migration notes; Mobile nối theo contract đã chốt, test fixture và API/MySQL, rồi Android thật. Groq/Jina thật là kiểm thử riêng, không suy từ fallback.

Có thể tách PR Backend theo từng mục; ghi dependency và tránh thay đổi lại bảo vệ PR69. Không bật email/push, chuyển tiền, migrate DB chính hay gửi nội dung khách sang dịch vụ ngoài chỉ để chạy test tự động.
