import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundmarine_client/screens/saved_screen.dart';
import 'package:soundmarine_client/screens/settings_screen.dart';
import 'package:soundmarine_client/services/api_service.dart';
import 'package:soundmarine_client/services/audio_proxy_server.dart';
import 'package:soundmarine_client/services/cache_service.dart';
import 'package:soundmarine_client/services/liked_service.dart';
import 'package:soundmarine_client/widgets/player_bar.dart';
import 'screens/library_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.soundmarine_client.audio',
    androidNotificationChannelName: 'Audio Playback',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
    androidNotificationClickStartsActivity: true,
    androidShowNotificationBadge: false,
    preloadArtwork: true,
  );

  final prefs = await SharedPreferences.getInstance();
  ApiService.token = prefs.getString('token');
  ApiService.baseUrl = prefs.getString('server_url') ?? ApiService.baseUrl;
  await LikedService.instance.load();
  await CacheService.init();
  await AudioProxyServer.instance.init();

  runApp(SoundMarineApp(isLoggedIn: ApiService.token != null));
}

class SoundMarineApp extends StatelessWidget {
  final bool isLoggedIn;
  const SoundMarineApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: isLoggedIn ? const MainScreen() : const LoginScreen(),
      routes: {
        '/home': (context) => const MainScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isOnHiddenScreen = false;
  final _pageController = PageController();

  static const _navBarScreenCount = 4;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Overlay.of(context).insert(
        OverlayEntry(
          builder: (_) => const Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: Material(
              color: Colors.transparent,
              child: PlayerBar(),
            ),
          ),
        ),
      );
    });
  }

  void _onPageScroll() {
    final page = _pageController.page ?? 0;
    final onHidden = page >= _navBarScreenCount - 0.5;
    if (onHidden != _isOnHiddenScreen) {
      setState(() => _isOnHiddenScreen = onHidden);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (index < _navBarScreenCount) {
      setState(() => _selectedIndex = index);
    }
  }

  void _onNavBarTap(int index) {
    _selectedIndex = index;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: [
            const _PlaceholderScreen(label: 'Home'),
            const SavedScreen(),
            const LibraryScreen(),
            const _PlaceholderScreen(label: 'Search'),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedIndex,
        isOnHiddenScreen: _isOnHiddenScreen,
        onTap: _onNavBarTap,
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String label;
  const _PlaceholderScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Text(label, style: const TextStyle(color: Colors.blue)),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final bool isOnHiddenScreen;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.isOnHiddenScreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.blue.withValues(alpha: 0.2),
        highlightColor: Colors.blue.withValues(alpha: 0.1),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF040404),
        selectedItemColor: isOnHiddenScreen ? const Color(0xFF001937) : Colors.blue,
        unselectedItemColor: const Color(0xFF001937),
        currentIndex: selectedIndex,
        onTap: onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.playlist_add_check), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.album), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        ],
      ),
    );
  }
}