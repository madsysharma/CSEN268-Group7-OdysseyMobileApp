import 'package:flutter/material.dart';
import 'package:odyssey/components/navigation/app_bar.dart';
import 'package:odyssey/utils/spaces.dart';

class DownloadNetworkPage extends StatefulWidget {
  const DownloadNetworkPage({super.key});

  @override
  State<DownloadNetworkPage> createState() => DownloadNetworkPageState();
}

class DownloadNetworkPageState extends State<DownloadNetworkPage> {
  String? selectedOption = 'Wi-Fi';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
        appBar: MyAppBar(title: "Maps Download Network"),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: smallPadding,
                child: Text("How would you like to download your data?",
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              RadioListTile<String>(
                title: Text('Wi-Fi'),
                value: 'Wi-Fi',
                groupValue: selectedOption,
                onChanged: (value) {
                  setState(() {
                    selectedOption = value;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text('Cellular'),
                value: 'Cellular',
                groupValue: selectedOption,
                onChanged: (value) {
                  setState(() {
                    selectedOption = value;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text('Both'),
                value: 'Both',
                groupValue: selectedOption,
                onChanged: (value) {
                  setState(() {
                    selectedOption = value;
                  });
                },
              ),
            ],
          ),
        ));
  }
}
