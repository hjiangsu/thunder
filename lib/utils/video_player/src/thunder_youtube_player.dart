import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ypf;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'package:thunder/core/enums/internet_connection_type.dart';
import 'package:thunder/core/enums/video_auto_play.dart';
import 'package:thunder/post/utils/comment_action_helpers.dart';
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
  late YoutubePlayerController _controller;
  final bool _isPlayerReady = false;
  late ypf.YoutubePlayerController _ypfController;

  @override
  void dispose() {
    super.dispose();

    if (Platform.isAndroid || Platform.isIOS) {
      _ypfController.dispose();
    } else {
      _controller.close();
    }
  }

  @override
  void initState() {
    super.initState();

    final thunderBloc = context.read<ThunderBloc>().state;
    if (Platform.isAndroid || Platform.isIOS) {
      _ypfController = ypf.YoutubePlayerController(
        initialVideoId: ypf.YoutubePlayer.convertUrlToId(widget.videoUrl)!,
        flags: ypf.YoutubePlayerFlags(
          controlsVisibleAtStart: true,
          autoPlay: autoPlayVideo(),
          enableCaption: false,
          hideControls: false,
          loop: thunderBloc.videoAutoLoop,
          mute: thunderBloc.videoAutoMute,
        ),
      )
        ..addListener(listener)
        ..setPlaybackRate(double.parse(thunderBloc.videoDefaultPlaybackSpeed.label.replaceAll('x', '')));
      if (thunderBloc.videoAutoFullscreen) {
        _ypfController.toggleFullScreenMode();
      }
    } else {
      _controller = YoutubePlayerController(
        params: YoutubePlayerParams(
          showControls: true,
          mute: thunderBloc.videoAutoMute,
          showFullscreenButton: true,
          loop: thunderBloc.videoAutoLoop,
        ),
      );
      _controller
        ..loadVideoById(videoId: ypf.YoutubePlayer.convertUrlToId(widget.videoUrl)!)
        ..setPlaybackRate(double.parse(thunderBloc.videoDefaultPlaybackSpeed.label.replaceAll('x', '')));
    }
  }

  void listener() {
    if (_isPlayerReady && mounted && !_ypfController.value.isFullScreen) {}
  }

  bool autoPlayVideo() {
    final thunderBloc = context.read<ThunderBloc>().state;
    final networkCubit = context.read<NetworkCheckerCubit>().state;
    if (thunderBloc.videoAutoPlay == VideoAutoPlay.always) {
      return true;
    } else if (thunderBloc.videoAutoPlay == VideoAutoPlay.onWifi && networkCubit.internetConnectionType == InternetConnectionType.wifi) {
      return true;
    }

    return false;
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
                        color: Colors.white.withOpacity(0.90),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: IconButton(
                      onPressed: () => handleLink(context, url: widget.videoUrl, forceOpenInBrowser: true),
                      icon: Icon(
                        Icons.open_in_browser_rounded,
                        semanticLabel: l10n.openInBrowser,
                        color: Colors.white.withOpacity(0.90),
                      ),
                    ),
                  ),
                ],
              ),
              Center(
                child: ypf.YoutubePlayerBuilder(
                  player: ypf.YoutubePlayer(
                    onReady: () => _ypfController.addListener(listener),
                    aspectRatio: 16 / 10,
                    controller: _ypfController,
                    actionsPadding: const EdgeInsets.only(bottom: 8),
                  ),
                  builder: (context, player) => player,
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
