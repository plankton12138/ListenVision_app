import 'package:demo/providers/audio_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ControlsPanel extends StatelessWidget {
  const ControlsPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // position/duration
        _buildTimeDisplay(context, provider),
        // progress bar
        _buildProgressBar(context, provider),
        // control buttons
        _buildControlButtons(context, provider),
      ],
    );
  }

  Widget _buildTimeDisplay(BuildContext context, AudioProvider controller) {
    return Text(
      '${controller.position.toString().split('.')[0]} / '
      '${controller.duration.toString().split('.')[0]}',
    );
  }

  Widget _buildProgressBar(BuildContext context, AudioProvider controller) {
    final durationSec = controller.duration.inSeconds;
    final positionSec = controller.position.inSeconds;


    final safeValue = (durationSec > 0 && positionSec <= durationSec)
       ? positionSec.toDouble()
        : 0.0;

    
    return Slider(
      value: safeValue,
      min: 0,
      max: durationSec > 0? durationSec.toDouble() : 1.0,
      activeColor: Colors.green,
      inactiveColor: Colors.grey,
      onChanged: (value) => controller.seek(Duration(seconds: value.toInt())),
    );
  }

  Widget _buildControlButtons(BuildContext context, AudioProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(Icons.skip_previous),
          iconSize: 45,
          onPressed: () => provider.playPrevious(),
        ),

        IconButton(
          icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow),
          iconSize: 45,
          onPressed: () => provider.togglePlayPause(),
        ),

        IconButton(
          icon: Icon(Icons.skip_next),
          iconSize: 45,
          onPressed: () => provider.playNext(),
        ),
      ],
    );
  }
}
