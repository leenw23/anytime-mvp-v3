import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../providers/navigation_provider.dart';
import '../widgets/swipe_indicator.dart';
import 'chat_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _pageController;

  static const int _initialPage = 1;
  static const int _pageCount = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(currentPageProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(currentPageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: _onPageChanged,
            children: const [
              ProfileScreen(),
              ChatScreen(),
              HistoryScreen(),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Center(
                  child: SwipeIndicator(
                    currentIndex: currentPage,
                    count: _pageCount,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
