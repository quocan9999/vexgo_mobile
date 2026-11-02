import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/widgets/tab_page_header.dart';

Future<void> openAppInformation(BuildContext context, Widget page) =>
    Navigator.of(
      context,
      rootNavigator: true,
    ).push<void>(MaterialPageRoute(builder: (_) => page));

class AppInformationScreen extends StatelessWidget {
  const AppInformationScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: const TabPageHeader(title: 'Thông tin VexGo', showBackButton: true),
    body: ListView(
      children: [
        ListTile(
          minVerticalPadding: 16,
          leading: const Icon(Icons.directions_bus_outlined),
          title: const Text('Giới thiệu VexGo'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => openAppInformation(context, const AboutVexGoScreen()),
        ),
        const Divider(height: 1, indent: 56),
        ListTile(
          minVerticalPadding: 16,
          leading: const Icon(Icons.menu_book_outlined),
          title: const Text('Hướng dẫn sử dụng'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => openAppInformation(context, const BookingGuideScreen()),
        ),
      ],
    ),
  );
}

class AboutVexGoScreen extends StatelessWidget {
  const AboutVexGoScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: const TabPageHeader(
      title: 'Giới thiệu VexGo',
      showBackButton: true,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Đồng hành cùng hành trình của bạn',
          style: DiscoveryTextStyles.h2,
        ),
        const SizedBox(height: 12),
        const Text(
          'VexGo là ứng dụng đặt vé xe khách trực tuyến, giúp bạn tìm chuyến, chọn chỗ và theo dõi vé trên điện thoại.',
        ),
        const SizedBox(height: 24),
        Text('Bạn có thể làm gì với VexGo?', style: DiscoveryTextStyles.h4),
        const SizedBox(height: 12),
        const Text(
          '• Tìm chuyến một chiều hoặc khứ hồi.\n\n• Chọn ghế và điểm đón/trả theo chuyến.\n\n• Xem giá, nhập mã ưu đãi và thanh toán theo hướng dẫn.\n\n• Tra cứu vé và chứng từ đặt vé/thanh toán.\n\n• Theo dõi thông báo và trao đổi qua chat hỗ trợ.',
        ),
        const SizedBox(height: 24),
        const Text(
          'Giá vé, lịch chạy và điều kiện phục vụ được hiển thị theo từng chuyến. Bạn nên kiểm tra thông tin trước khi xác nhận đặt vé.',
        ),
      ],
    ),
  );
}

class BookingGuideScreen extends StatelessWidget {
  const BookingGuideScreen({super.key});
  static const topics = <(String, String)>[
    (
      '1. Tìm chuyến',
      'Chọn nơi đi, nơi đến và ngày khởi hành trên Trang chủ. Nếu đi khứ hồi, bật Khứ hồi và chọn ngày về. Mở kết quả để xem giờ chạy, giá và thông tin xe.',
    ),
    (
      '2. Chọn ghế và điểm đón/trả',
      'Chọn chỗ còn trống trên sơ đồ của chuyến. Với xe hai tầng, kiểm tra cả tầng dưới và tầng trên. Sau đó chọn điểm đón và điểm trả phù hợp. Hoàn tất đặt vé trong thời gian giữ chỗ hiển thị trên màn hình.',
    ),
    (
      '3. Kiểm tra hành khách và ưu đãi',
      'Điền thông tin liên hệ để nhận vé. Kiểm tra lại chuyến, ghế và các điểm đón/trả. Nếu có mã ưu đãi, nhập mã và chờ hệ thống kiểm tra điều kiện, sau đó xem tổng tiền đã cập nhật.',
    ),
    (
      '4. Thanh toán và nhận vé',
      'Làm theo thông tin ngân hàng, số tiền và nội dung chuyển khoản trên màn hình thanh toán. Chờ hệ thống xác nhận, sau đó kiểm tra vé đã phát hành. Nếu hết thời gian giữ chỗ, kiểm tra trạng thái đơn trước khi đặt lại hoặc liên hệ hỗ trợ khi cần.',
    ),
    (
      '5. Tra cứu vé và chứng từ',
      'Mở Vé của tôi để xem các vé gắn với tài khoản. Khi đặt vé không đăng nhập, dùng thông tin tra cứu được cung cấp sau đặt vé. Từ Chi tiết vé, mở chứng từ đặt vé/thanh toán để xem thông tin đơn. Với khứ hồi, kiểm tra trạng thái vé của cả lượt đi và lượt về.',
    ),
    (
      '6. Hủy vé và hỗ trợ',
      'Mở Chi tiết vé và chọn hủy nếu vé còn cho phép. Xem điều kiện, phí và số tiền hoàn được hệ thống hiển thị trước khi xác nhận. Theo dõi trạng thái hoàn tiền trong thông báo. Bạn có thể vào Chat với nhà xe trong Tài khoản để trao đổi khi cần.',
    ),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: const TabPageHeader(
      title: 'Hướng dẫn sử dụng',
      showBackButton: true,
    ),
    body: ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'Từ tìm chuyến đến nhận vé và quản lý hành trình. Chọn mục bạn cần xem.',
          ),
        ),
        for (var i = 0; i < topics.length; i++)
          ExpansionTile(
            initiallyExpanded: i == 0,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            title: Text(topics[i].$1, style: DiscoveryTextStyles.titleMedium),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(topics[i].$2)],
          ),
      ],
    ),
  );
}

class BookingGuideSection extends StatelessWidget {
  const BookingGuideSection({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Đặt vé cùng VexGo', style: DiscoveryTextStyles.h3),
        const SizedBox(height: 12),
        const Text(
          '1. Tìm chuyến phù hợp\n2. Chọn ghế và thông tin hành trình\n3. Thanh toán và nhận vé',
          style: TextStyle(height: 1.8),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () =>
                openAppInformation(context, const BookingGuideScreen()),
            child: const Text('Xem hướng dẫn đặt vé'),
          ),
        ),
      ],
    ),
  );
}
