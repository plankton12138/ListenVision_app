import 'package:demo/constants/dimens.dart';
import 'package:demo/providers/audio_provider.dart';
import 'package:demo/ui/components/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class PlaylistPage extends StatefulWidget{
  const PlaylistPage({super.key});

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage>{
  @override
  Widget build(BuildContext context) {
    
    final provider = context.watch<AudioProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Playlist Page',
          style: TextStyle(
            fontSize: Dimens.fontSizeLarge,
          ),  
        ),
        actions: <Widget>[
          // Home Button
          IconButton(
            icon: Icon(Icons.home),
            iconSize: Dimens.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),

      drawer: const MyDrawer(),

      body: ListView.builder(
        itemCount: provider.playlist.length,
        itemBuilder: (context, index) {
          final audio = provider.playlist[index];
          return ListTile(
            title: Text(
              audio.title,
              style: TextStyle(
                fontSize: Dimens.fontSizeMedium,
              ),  
            ),
            subtitle: Text(
              'Artist: ${audio.artist}',
              style: TextStyle(
                fontSize: Dimens.fontSizeSmall,
              ),  
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => provider.removeFromPlaylist(audio.id!),
            ),
            onTap: () => provider.playAudio(index),
          );
        },
      ),
    );
  }
}