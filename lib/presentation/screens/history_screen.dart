import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme.dart';
import '../../data/repositories/history_repository.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HISTORY',
                      style: AppTypography.label.copyWith(letterSpacing: 1),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: state.items.isEmpty
                          ? Center(
                              child: Text(
                                '아직 기록이 없어요',
                                style: AppTypography.bodySecondary,
                              ),
                            )
                          : _buildTimeline(state.items),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTimeline(List<HistoryItem> items) {
    // Group by date key preserving insertion order
    final groups = <String, List<HistoryItem>>{};
    for (final item in items) {
      final key = _dateGroupKey(item.createdAt);
      groups.putIfAbsent(key, () => []).add(item);
    }

    return SingleChildScrollView(
      child: Stack(
        children: [
          // Vertical timeline line
          Positioned(
            left: 4,
            top: 0,
            bottom: 0,
            child: Container(
              width: AppSpacing.timelineWidth,
              color: AppColors.border,
            ),
          ),
          // Content padded past the line
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in groups.entries) ...[
                  _buildDateHeader(entry.key),
                  for (final item in entry.value) _buildHistoryCard(item),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String label) {
    // Shift left by the same padding to align tick with the timeline
    return Transform.translate(
      offset: const Offset(-20, 0),
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 16),
        child: Row(
          children: [
            Container(width: 9, height: 1, color: AppColors.textDim),
            const SizedBox(width: 11),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textDim,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    final Color iconColor;
    switch (item.type) {
      case 'message':
        iconColor = const Color(0xFFFF8E8E);
      case 'insight':
        iconColor = const Color(0xFF7CB9E8);
      case 'calendar':
        iconColor = const Color(0xFF90EE90);
      case 'milestone':
        iconColor = const Color(0xFFDDA0DD);
      default:
        iconColor = AppColors.textDim;
    }

    final timeStr = DateFormat('HH:mm').format(item.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Timeline dot — positioned relative to this stack, offset left of card
          Positioned(
            left: -24,
            top: 16,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: item.isHighlight ? AppColors.accent : AppColors.background,
                border: Border.all(
                  color: item.isHighlight ? AppColors.accent : AppColors.textDim,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Card body
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              // rgba(255,255,255,0.03) ≈ 0x08 alpha
              color: const Color(0x08FFFFFF),
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: icon · type label · time
                Row(
                  children: [
                    Text(
                      item.icon,
                      style: TextStyle(fontSize: 14, color: iconColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.typeLabel.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textDim,
                        letterSpacing: 1,
                        fontSize: 9,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeStr,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textDim,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Content
                Text(
                  item.content,
                  style: AppTypography.historyCard.copyWith(
                    // rgba(255,255,255,0.7) ≈ 0xB3 alpha
                    color: const Color(0xB3FFFFFF),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                // Optional preview
                if (item.preview != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.preview!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textDim,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateGroupKey(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) return 'TODAY';
    if (date == today.subtract(const Duration(days: 1))) return 'YESTERDAY';

    const dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '$mm.$dd ${dayNames[dt.weekday - 1]}';
  }
}
