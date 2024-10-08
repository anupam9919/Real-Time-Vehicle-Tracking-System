import 'package:flutter/material.dart';
import 'package:vehicle/userPages/accountPage.dart';
import 'package:vehicle/userPages/helpSupport.dart';
import 'package:vehicle/userPages/searchPage.dart';
import 'package:vehicle/userPages/track.dart';
import 'package:vehicle/components/busStop.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
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
