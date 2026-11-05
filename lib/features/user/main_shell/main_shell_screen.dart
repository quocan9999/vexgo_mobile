import 'package:flutter_bloc/flutter_bloc.dart';
import '../notification/bloc/notification_bloc.dart';
import '../notification/bloc/notification_event.dart';
import '../notification/bloc/notification_state.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';

class MainShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({super.key, required this.navigationShell});

  void _onItemTapped(BuildContext context, int index) {
    if (index == 3) {
      final bloc = context.read<NotificationBloc?>();
      if (bloc != null && bloc.state.status != NotificationStatus.initial) {
        bloc.add(const LoadNotificationsEvent());
      }
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.15,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => _onItemTapped(context, index),
            backgroundColor: Colors.white,
            selectedItemColor: navigationShell.currentIndex == 0
                ? DiscoveryColors.primary
                : AppColors.primary,
            unselectedItemColor: AppColors.neutral400,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle:
                (navigationShell.currentIndex == 0
                        ? DiscoveryTextStyles.caption
                        : AppTextStyles.caption)
                    .copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
            unselectedLabelStyle:
                (navigationShell.currentIndex == 0
                        ? DiscoveryTextStyles.caption
                        : AppTextStyles.caption)
                    .copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: AppColors.neutral400,
                    ),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.directions_bus_outlined),
                activeIcon: Icon(Icons.directions_bus_rounded),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.confirmation_number_outlined),
                activeIcon: Icon(Icons.confirmation_number_rounded),
                label: 'Vé của tôi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_shipping_outlined),
                activeIcon: Icon(Icons.local_shipping_rounded),
                label: 'Gửi hàng',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_none_rounded),
                activeIcon: Icon(Icons.notifications_rounded),
                label: 'Thông báo',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Tài khoản',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
