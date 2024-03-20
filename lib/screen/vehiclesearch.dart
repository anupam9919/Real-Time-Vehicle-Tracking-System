import 'package:flutter/material.dart';

class VehicleSearchDelegate extends SearchDelegate<String> {
  final List<String> recentSearches;

  VehicleSearchDelegate(this.recentSearches);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    recentSearches.insert(0, query);
    if (recentSearches.length > 3) {
      recentSearches.removeRange(3, recentSearches.length);
    }
    return Center(
      child: Text(query),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<String> suggestions = <String>['Suggestion1', 'Suggestion2']
        .where((String item) => item.startsWith(query))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          leading: Icon(Icons.directions_car),
          title: Text(suggestions[index]),
          onTap: () {
            query = suggestions[index];
            showResults(context);
          },
        );
      },
    );
  }
}
