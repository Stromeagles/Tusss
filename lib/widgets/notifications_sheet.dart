import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'dart:ui';

class AppNotificationsSheet extends StatelessWidget {
  final bool isDark;
  final List<AppNotificationItem> notifications;

  const AppNotificationsSheet({
    super.key,
    required this.isDark,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppTheme.background : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bildirim Merkezi',
                      style: GoogleFonts.inter(
                        color: textColor, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1.0,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: textColor.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: notifications.isEmpty
                      ? _buildEmptyState(textColor)
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _NotificationCard(
                              notification: notifications[index],
                              isDark: isDark,
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: textColor.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('Şu an için yeni bir bildirim yok.',
            style: GoogleFonts.inter(color: textColor.withValues(alpha: 0.4), fontSize: 14)),
        ],
      ),
    );
  }
}

class AppNotificationItem {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String? timeLabel;

  AppNotificationItem({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.timeLabel,
  });
}

class _NotificationCard extends StatelessWidget {
  final AppNotificationItem notification;
  final bool isDark;

  const _NotificationCard({
    required this.notification,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: notification.color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: notification.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(notification.icon, color: notification.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(notification.title,
                      style: GoogleFonts.inter(
                        color: notification.color, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5,
                      )),
                    if (notification.timeLabel != null)
                      Text(notification.timeLabel!,
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted.withValues(alpha: 0.6), fontSize: 10,
                        )),
                  ],
                ),
                const SizedBox(height: 6),
                Text(notification.message,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                    fontSize: 14, fontWeight: FontWeight.w600, height: 1.4,
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
