import 'package:flutter/material.dart';
import 'package:vehicle/screen/VehicleSearchDelegate.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<String> recentSearches = ['Search 1', 'Search 2', 'Search 3'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicle Tracking App'),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showSearch(
              context: context,
              delegate: VehicleSearchDelegate(recentSearches));
        },
        child: Icon(Icons.search),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBody() {
    return Column(
      children: <Widget>[
        Text('Recent Searches'),
        for (var search in recentSearches)
          ListTile(
            title: Text(search),
            onTap: () {
              showSearch(
                context: context,
                delegate: VehicleSearchDelegate(recentSearches),
                query: search,
              );
            },
          ),
      ],
    );
  }

  Widget _buildHome() {
    return Center(
      child: Text('Home Screen'),
    );
  }

  Widget _buildTrack() {
    return Center(
      child: Text('Track Screen'),
    );
  }

  Widget _buildAccount() {
    return Center(
      child: Text('Account Screen'),
    );
  }

  Widget _buildHelp() {
    return Center(
      child: Text('Help Screen'),
    );
  }
}
