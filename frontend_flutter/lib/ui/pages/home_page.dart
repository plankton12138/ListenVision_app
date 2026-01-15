import 'package:demo/providers/audio_provider.dart';
import 'package:demo/services/file_picker.dart';
import 'package:demo/ui/components/audio_info.dart';
import 'package:demo/ui/components/controls_panel.dart';
import 'package:demo/ui/components/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:demo/constants/dimens.dart';

import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // handle file picker
  Future<void> _handleFilePicker(BuildContext context) async {
    final filePicker = context.read<FilePickerService>();
    final audioProvider = context.read<AudioProvider>();

    try {
      final filePath = await filePicker.pickAudioFile();
      if (filePath != null) {
        await audioProvider.loadAudio(filePath);
        // audioProvider.togglePlayPause();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Theme data for the app
      backgroundColor: Theme.of(context).colorScheme.surface,

      // Top app bar
      appBar: AppBar(
        title: const Text(
          'ListenVision',
          style: TextStyle(
            // fontFamily: 
            fontSize: Dimens.fontSizeLarge,
          )
        ),
        actions: <Widget>[
          // Filepicker button
          IconButton(
            icon: const Icon(Icons.file_upload),
            iconSize: Dimens.iconMedium,
            onPressed: () => _handleFilePicker(context),
          ),

          // Explore button
          IconButton(
            icon: const Icon(Icons.explore),
            iconSize: Dimens.iconMedium,
            onPressed: () => context.go('/explore'),
          ),

          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            iconSize: Dimens.iconMedium,
            onPressed: () => context.go('/search'),
          ),
        ],
      ),

      // Drawer
      drawer: const MyDrawer(),

      // The core content:Audio player //
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Controls panel
          AudioInfo(),
          ControlsPanel(),
        ],
      ),

      // Persistent footer buttons
      persistentFooterButtons: [
        ElevatedButton(
          onPressed: () => context.go('/playlist'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).secondaryHeaderColor,
            elevation: 4,
          ),
          child: const Icon(
            Icons.list,
            size: Dimens.iconMedium,
            color: Color.fromARGB(255, 20, 163, 25),
          ),
        ),
      ],
    );
  }
}
