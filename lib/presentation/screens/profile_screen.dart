import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../data/models/models.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final companion = profile.companion;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: profile.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent))
            : companion == null
                ? Center(
                    child: Text('아직 친구가 없어요', style: AppTypography.body))
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader(companion)),
                      SliverToBoxAdapter(child: _buildTabBar()),
                      SliverFillRemaining(
                        child: TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _AiProfileTab(
                              companion: companion,
                              changeLog: profile.changeLog,
                            ),
                            _UserProfileTab(knowledge: profile.userKnowledge),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader(Companion companion) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: () => _showAvatarPicker(companion),
            child: Container(
              width: AppSpacing.avatarSize,
              height: AppSpacing.avatarSize,
              decoration: BoxDecoration(
                color: AppColors.tvBackground,
                borderRadius:
                    BorderRadius.circular(AppSpacing.cardBorderRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  companion.avatarEmoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(companion.name, style: AppTypography.h2),
          if (companion.identitySummary != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              companion.identitySummary!,
              style: AppTypography.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${companion.currentMood} · ${companion.daysActive}일째',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: AppColors.accent,
      labelColor: AppColors.textPrimary,
      unselectedLabelColor: AppColors.textDim,
      labelStyle: AppTypography.label,
      tabs: const [
        Tab(text: 'AI 프로필'),
        Tab(text: '사용자'),
      ],
    );
  }

  void _showAvatarPicker(Companion companion) {
    const emojis = [
      '📺', '🤖', '👾', '🎮',
      '🌙', '⭐', '🎵', '🌿',
      '🦊', '🐱', '🎭', '💫',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.tvBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          children: emojis.map((emoji) {
            final isSelected = emoji == companion.avatarEmoji;
            return GestureDetector(
              onTap: () {
                ref.read(profileProvider.notifier).updateAvatar(emoji);
                Navigator.pop(ctx);
              },
              child: Container(
                width: AppSpacing.avatarOptionSize,
                height: AppSpacing.avatarOptionSize,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.2)
                      : AppColors.background,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardBorderRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 28)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI Profile Tab
// ---------------------------------------------------------------------------

class _AiProfileTab extends StatelessWidget {
  final Companion companion;
  final List<AiChangeLog> changeLog;

  const _AiProfileTab({required this.companion, required this.changeLog});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        _buildSection('성격',
            _buildTags(companion.personalityTraits)),
        const SizedBox(height: AppSpacing.lg),
        _buildSection('좋아하는 것',
            _buildTags(companion.likes)),
        const SizedBox(height: AppSpacing.lg),
        _buildSection('싫어하는 것',
            _buildTags(companion.dislikes)),
        if (changeLog.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildSection('변화 로그', _buildChangeLog()),
        ],
      ],
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        content,
      ],
    );
  }

  Widget _buildTags(List<String> items) {
    if (items.isEmpty) {
      return Text('아직 없어요', style: AppTypography.bodySecondary);
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items
          .map((item) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(item, style: AppTypography.tag),
              ))
          .toList(),
    );
  }

  Widget _buildChangeLog() {
    return Column(
      children: changeLog
          .take(5)
          .map((log) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('·', style: AppTypography.bodySmall),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${log.fieldChanged ?? log.changeType}: ${log.newValue ?? ""}',
                            style: AppTypography.bodySmall,
                          ),
                          if (log.reason != null)
                            Text(log.reason!,
                                style: AppTypography.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// User Profile Tab
// ---------------------------------------------------------------------------

class _UserProfileTab extends StatelessWidget {
  final List<UserKnowledge> knowledge;

  const _UserProfileTab({required this.knowledge});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<UserKnowledge>>{};
    for (final k in knowledge) {
      grouped.putIfAbsent(k.category, () => []).add(k);
    }

    if (grouped.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text('아직 알게 된 것이 없어요',
              style: AppTypography.bodySecondary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: grouped.entries
          .map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_categoryLabel(entry.key),
                      style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.sm),
                  ...entry.value.map((k) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(k.key,
                                  style: AppTypography.label),
                            ),
                            Expanded(
                                child: Text(k.value,
                                    style: AppTypography.body)),
                          ],
                        ),
                      )),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ))
          .toList(),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'basic_info':
        return '기본 정보';
      case 'preferences':
        return '취향';
      case 'emotions':
        return '감정';
      case 'life_events':
        return '인생 이벤트';
      case 'relationships':
        return '관계';
      case 'habits':
        return '습관';
      default:
        return category;
    }
  }
}
