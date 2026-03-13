import 'package:flutter/material.dart';
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
      appBar: AppBar(
        shape:
            ContinuousRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'Vehicle Tracking App',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
      body: PageView(
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        enableFeedback: true,
        unselectedItemColor: Colors.grey,
        selectedIconTheme:
            const IconThemeData(color: Colors.deepPurple, size: 32),
        unselectedIconTheme: const IconThemeData(size: 25),
        showSelectedLabels: false,
        showUnselectedLabels: false,
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
            icon: Icon(Icons.account_circle_rounded),
            label: 'Account',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'Help',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _openSearchPage,
              child: const Icon(Icons.search),
            )
          : null, // Only show FAB if "Home" is selected
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
