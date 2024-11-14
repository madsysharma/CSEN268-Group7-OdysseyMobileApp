import 'package:flutter/material.dart';

const List<int> proximityList = <int>[10, 20, 100];
const safePlacesList = <String>['Nature', 'History', 'Food', 'Culture', 'Arts'];

class SearchPlaces extends StatelessWidget {
  const SearchPlaces({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SearchBar(
          leading: Icon(Icons.search),
          hintText: "Search for places",
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            DropdownMenu(
              initialSelection: 20,
              label: const Text('Proximity'),
              dropdownMenuEntries:
                  proximityList.map<DropdownMenuEntry<int>>((int value) {
                return DropdownMenuEntry<int>(
                    value: value, label: "$value miles");
              }).toList(),
            ),
            DropdownMenu(
              initialSelection: 'Nature',
              label: const Text('SafePlaces'),
              dropdownMenuEntries:
                  safePlacesList.map<DropdownMenuEntry<String>>((String value) {
                return DropdownMenuEntry<String>(value: value, label: value);
              }).toList(),
            ),
          ],
        )
      ],
    );
  }
}
