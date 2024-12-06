import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odyssey/bloc/locations/locations_bloc.dart';
import 'package:odyssey/utils/debouncer.dart';

const List<String> proximityList = <String>['Any', '10 miles', '20 miles', '100 miles'];
const List<String> safePlacesList = <String>['Nature', 'History', 'Food', 'Culture', 'Arts'];

class SearchPlaces extends StatefulWidget {
  const SearchPlaces({super.key});

  @override
  State<SearchPlaces> createState() => _SearchPlacesState();
}

class _SearchPlacesState extends State<SearchPlaces> {
  final Debouncer _debouncer = Debouncer(milliseconds: 300); 
  String selectedCategory = 'Any';
  String selectedProximity = 'Any'; 
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SearchBar(
          leading: Icon(Icons.search),
          hintText: "Search for places",
          onChanged: (value) {
            searchQuery = value;
            _triggerSearchEvent(); 
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            DropdownMenu(
              initialSelection: selectedProximity,
              label: const Text('Proximity'),
              dropdownMenuEntries:
                  proximityList.map<DropdownMenuEntry<String>>((String value) {
                return DropdownMenuEntry<String>(
                    value: value, label: value);
              }).toList(),
              onSelected: (value) {
                if (value != null) {
                  setState(() {
                    selectedProximity = value;
                  });
                  _triggerSearchEvent(); 
                }
              },
            ),
            DropdownMenu(
              initialSelection: selectedCategory,
              label: const Text('Categories'),
              dropdownMenuEntries: ['Any', ...safePlacesList]
                  .map<DropdownMenuEntry<String>>((String value) {
                return DropdownMenuEntry<String>(value: value, label: value);
              }).toList(),
              onSelected: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                  _triggerSearchEvent(); 
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  void _triggerSearchEvent() {
    _debouncer.run(
        () => context.read<LocationsBloc>().add(
          FetchLocations(
            searchQuery: searchQuery,
            proximity: selectedProximity == 'Any' ? null : int.parse(selectedProximity.split(' ')[0]),
            category: selectedCategory == 'Any' ? null : selectedCategory
          ),
        )
    );
  }
}
