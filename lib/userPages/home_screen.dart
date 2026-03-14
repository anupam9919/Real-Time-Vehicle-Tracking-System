import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vehicle/services/app_logger.dart';
import 'package:vehicle/userPages/account_page.dart';
import 'package:vehicle/userPages/help_support.dart';
import 'package:vehicle/userPages/search_page.dart';
import 'package:vehicle/userPages/track.dart';
import 'package:vehicle/components/bus_stop.dart';

final _log = AppLogger.getLogger('HomeScreen');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  static const List<String> _pageNames = ['Home', 'Track', 'Account', 'Help'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _log.info('HomeScreen initialized, starting on page: ${_pageNames[_selectedIndex]}');
  }

  @override
  void dispose() {
    _log.info('HomeScreen disposed');
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _log.info('Tab switched: ${_pageNames[_selectedIndex]} -> ${_pageNames[index]}');
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    });
  }

  void _openSearchPage() {
    _log.info('Opening SearchPage via FAB');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SearchPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A), // Deep dark premium background
      extendBodyBehindAppBar: true, // Let background flow under the app bar
      body: Stack(
        children: [
          // ── BACKGROUND DECORATIONS ──
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6C63FF).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00C9FF).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── MAIN CONTENT ──
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Custom Frosted Glass AppBar
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.directions_bus_filled_rounded, color: Color(0xFF00C9FF)),
                          const SizedBox(width: 8),
                          Text(
                            'Vehicle Tracking',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Page View
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      _log.fine('Page swiped to: ${_pageNames[index]}');
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    children: const <Widget>[
                      BusStopWidget(), // Display BusStopWidget as the first page
                      TrackingPage(),
                      AccountPage(),
                      HelpPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF1E1E2C), // Sleek dark surface color
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          enableFeedback: true,
          unselectedItemColor: Colors.white.withValues(alpha: 0.4),
          selectedItemColor: const Color(0xFF00C9FF), // Neon blue highlight
          selectedIconTheme: const IconThemeData(size: 30),
          unselectedIconTheme: const IconThemeData(size: 24),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 11),
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_rounded),
              label: 'Track',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.help_outline_rounded),
              label: 'Help',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                elevation: 0,
                onPressed: _openSearchPage,
                child: const Icon(Icons.search_rounded, size: 28),
              ),
            )
          : null, // Only show FAB if "Home" is selected
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
