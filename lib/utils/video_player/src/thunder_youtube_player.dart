import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ypf;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'package:thunder/utils/global_context.dart';
import 'package:thunder/core/enums/internet_connection_type.dart';
import 'package:thunder/core/enums/video_auto_play.dart';
import 'package:thunder/thunder/thunder.dart';
import 'package:thunder/utils/links.dart';

class ThunderYoutubePlayer extends StatefulWidget {
  const ThunderYoutubePlayer({super.key, required this.videoUrl, this.postId});

  final int? postId;
  final String videoUrl;

  @override
  State<ThunderYoutubePlayer> createState() => _ThunderYoutubePlayerState();
}

class _ThunderYoutubePlayerState extends State<ThunderYoutubePlayer> with SingleTickerProviderStateMixin {
  /// Whether or not the video is muted.
  bool muted = false;

  late YoutubePlayerController _controller;
  late ypf.YoutubePlayerController _ypfController;

  @override
  void dispose() {
    if (Platform.isAndroid || Platform.isIOS) {
      _ypfController.dispose();
    } else {
      _controller.close();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    final state = context.read<ThunderBloc>().state;
    final timestamp = extractYouTubeTimestamp();

    if (Platform.isAndroid || Platform.isIOS) {
      _ypfController = ypf.YoutubePlayerController(
        initialVideoId: ypf.YoutubePlayer.convertUrlToId(widget.videoUrl)!,
        flags: ypf.YoutubePlayerFlags(
          controlsVisibleAtStart: true,
          autoPlay: autoPlayVideo(),
          enableCaption: false,
          hideControls: false,
          startAt: timestamp ?? 0,
          loop: state.videoAutoLoop,
          mute: state.videoAutoMute,
        ),
      )..setPlaybackRate(state.videoDefaultPlaybackSpeed.value);

      if (state.videoAutoFullscreen) _ypfController.toggleFullScreenMode();
    } else {
      _controller = YoutubePlayerController(
        params: YoutubePlayerParams(
          showControls: true,
          mute: state.videoAutoMute,
          showFullscreenButton: true,
          loop: state.videoAutoLoop,
        ),
      );
      _controller
        ..loadVideoById(videoId: ypf.YoutubePlayer.convertUrlToId(widget.videoUrl)!)
        ..seekTo(seconds: double.parse('$timestamp'))
        ..setPlaybackRate(state.videoDefaultPlaybackSpeed.value);
    }

    setState(() => muted = state.videoAutoMute);
  }

  bool autoPlayVideo() {
    final state = context.read<ThunderBloc>().state;
    final networkCubit = context.read<NetworkCheckerCubit>().state;

    if (state.videoAutoPlay == VideoAutoPlay.always) {
      return true;
    } else if (state.videoAutoPlay == VideoAutoPlay.onWifi && networkCubit.internetConnectionType == InternetConnectionType.wifi) {
      return true;
    }

    return false;
  }

  int? extractYouTubeTimestamp() {
    final uri = Uri.parse(widget.videoUrl);

    // Check for timestamp in query parameters
    String? timeParam = uri.queryParameters['t'] ?? uri.queryParameters['start'];

    // Check for embedded timestamps like t=1m30s
    final regex = RegExp(r't=(\d+h)?(\d+m)?(\d+s)?');

    if (timeParam != null) {
      return _convertTimeStringToSeconds(timeParam);
    } else if (regex.hasMatch(widget.videoUrl)) {
      final match = regex.firstMatch(widget.videoUrl)!;
      return _convertTimeComponentsToSeconds(match);
    }

    return null;
  }

  int _convertTimeStringToSeconds(String time) {
    final regex = RegExp(r'(\d+h)?(\d+m)?(\d+s)?');
    final match = regex.firstMatch(time);

    return match != null ? _convertTimeComponentsToSeconds(match) : 0;
  }

  int _convertTimeComponentsToSeconds(RegExpMatch match) {
    int hours = match.group(1) != null ? int.parse(match.group(1)!.replaceAll('h', '')) : 0;
    int minutes = match.group(2) != null ? int.parse(match.group(2)!.replaceAll('m', '')) : 0;
    int seconds = match.group(3) != null ? int.parse(match.group(3)!.replaceAll('s', '')) : 0;

    return hours * 3600 + minutes * 60 + seconds;
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      // Use youtube_player_flutter to play the videos android ios
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          bottom: false,
          left: false,
          right: false,
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
                        color: Colors.white.withValues(alpha: 0.90),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: IconButton(
                      onPressed: () => handleLink(context, url: widget.videoUrl, forceOpenInBrowser: true),
                      icon: Icon(
                        Icons.open_in_browser_rounded,
                        semanticLabel: GlobalContext.l10n.openInBrowser,
                        color: Colors.white.withValues(alpha: 0.90),
                      ),
                    ),
                  ),
                ],
              ),
              Center(
                child: ypf.YoutubePlayerBuilder(
                  player: ypf.YoutubePlayer(
                    aspectRatio: 16 / 10,
                    controller: _ypfController,
                    actionsPadding: const EdgeInsets.only(bottom: 8),
                    topActions: [
                      IconButton(
                        onPressed: () {
                          muted ? _ypfController.unMute() : _ypfController.mute();
                          setState(() => muted = !muted);
                        },
                        icon: Icon(
                          muted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                  builder: (context, player) => player,
                  onExitFullScreen: () {
                    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      /// Use youtube_player_iframe to play the videos
      return Material(
        child: YoutubePlayerScaffold(
          autoFullScreen: false,
          controller: _controller,
          builder: (context, player) {
            return LayoutBuilder(builder: (context, constraints) {
              return player;
            });
          },
        ),
      );
    }
  }
}
