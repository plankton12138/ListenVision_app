import 'package:demo/constants/dimens.dart';
import 'package:demo/providers/audio_provider.dart';
// import 'package:demo/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AudioInfo extends StatelessWidget {
  const AudioInfo({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();


    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: [
        // album art
        _buildAlbumArt(context, provider),
        // audio info
        _buildAudioInfo(provider),
        // favorite button
        
      ],
    );
  }

  Widget _buildAlbumArt(BuildContext context, AudioProvider controller) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 300,
      decoration: BoxDecoration(
        image:
            controller.albumArt != null
                ? DecorationImage(
                  image: MemoryImage(controller.albumArt!),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                )
                : const DecorationImage(
                  image: AssetImage('assets/images/default_album_art.png'),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
      ),
    );
  }

  Widget _buildAudioInfo(AudioProvider controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 15),
        Text(
          'Title: ${controller.title}',
          style: const TextStyle(
            fontSize: Dimens.fontSizeMedium,
            fontWeight: FontWeight.bold,       
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 15),
        Text(
          'Artist: ${controller.artist}',
          style: const TextStyle(
            fontSize: Dimens.fontSizeSmall,
            // fontWeight: FontWeight.bold,       
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
