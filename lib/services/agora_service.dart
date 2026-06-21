import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:arogya_path3/core/config/agora_config.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  static AgoraService get instance => _instance;
  AgoraService._internal();

  RtcEngine? _engine;
  bool _isInitialized = false;
  String? _currentChannel;
  final Set<int> _remoteUids = {};

  bool get isInitialized => _isInitialized;
  String? get currentChannel => _currentChannel;
  Set<int> get remoteUids => _remoteUids;

  Function(int uid, int elapsed)? onUserJoined;
  Function(int uid, UserOfflineReasonType reason)? onUserOffline;
  Function(RtcStats stats)? onLeaveChannel;
  Function(int uid, bool muted)? onUserMuteAudio;
  Function(int uid, bool muted)? onUserMuteVideo;

  Future<void> initialize({bool skipPermissions = false}) async {
    if (_isInitialized && _engine != null) {
      debugPrint("Agora Engine already initialized â€” reusing");
      return;
    }
    if (_engine != null) {
      try {
        await _engine!.release();
      } catch (_) {}
      _engine = null;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    _isInitialized = false;

    try {
      if (!skipPermissions) {
        await [Permission.microphone, Permission.camera].request();
      }

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 960, height: 540),
          frameRate: 24,
          bitrate: 1200,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );

      await _engine!.enableVideo();
      await _engine!.startPreview();

      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Joined channel: ${connection.channelId}");
          _remoteUids.clear();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user $remoteUid joined");
          _remoteUids.add(remoteUid);
          onUserJoined?.call(remoteUid, elapsed);
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("Remote user $remoteUid left: $reason");
          _remoteUids.remove(remoteUid);
          onUserOffline?.call(remoteUid, reason);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint("Left channel");
          _remoteUids.clear();
          onLeaveChannel?.call(stats);
        },
        onUserMuteAudio: (RtcConnection connection, int remoteUid, bool muted) {
          onUserMuteAudio?.call(remoteUid, muted);
        },
        onUserMuteVideo: (RtcConnection connection, int remoteUid, bool muted) {
          onUserMuteVideo?.call(remoteUid, muted);
        },
      ));

      _isInitialized = true;
      debugPrint("Agora Engine Initialized");
    } catch (e) {
      debugPrint("Error initializing Agora: $e");
      _engine = null;
      _isInitialized = false;
      rethrow;
    }
  }

  Future<void> joinChannel({
    required String channelName,
    required int uid,
    bool isVideo = true,
    String? token,
  }) async {
    if (!_isInitialized) await initialize();
    try {
      try {
        await _engine!.leaveChannel();
      } catch (_) {}
      if (isVideo) {
        await _engine!.enableVideo();
      } else {
        await _engine!.disableVideo();
      }
      await _engine!.joinChannel(
        token: token ?? '',
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
      _currentChannel = channelName;
    } catch (e) {
      debugPrint("Error joining channel: $e");
      rethrow;
    }
  }

  Future<void> leaveChannel() async {
    try {
      await _engine?.leaveChannel();
      _currentChannel = null;
    } catch (e) {
      debugPrint("Error leaving channel: $e");
    }
  }

  /// Join channel with user account (string ID â€” for MongoDB interop)
  Future<void> joinChannelWithUserAccount({
    required String channelName,
    required String userAccount,
    bool isVideo = true,
    String? token,
  }) async {
    if (!_isInitialized) await initialize(skipPermissions: !isVideo);
    try {
      if (_currentChannel != null && _currentChannel != channelName) {
        try {
          await _engine!.leaveChannel();
        } catch (_) {}
      }
      if (isVideo) {
        await _engine!.enableVideo();
      } else {
        await _engine!.disableVideo();
      }
      await _engine!.joinChannelWithUserAccount(
        token: token ?? '',
        channelId: channelName,
        userAccount: userAccount,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
      _currentChannel = channelName;
    } catch (e) {
      debugPrint("Error joining channel: $e");
      rethrow;
    }
  }

  Future<void> toggleAudio(bool muted) =>
      _engine?.muteLocalAudioStream(muted) ?? Future.value();
  Future<void> toggleVideo(bool muted) =>
      _engine?.muteLocalVideoStream(muted) ?? Future.value();
  Future<void> switchCamera() => _engine?.switchCamera() ?? Future.value();
  Future<void> setSpeakerphone(bool enabled) =>
      _engine?.setEnableSpeakerphone(enabled) ?? Future.value();

  Future<void> dispose() async {
    if (_engine != null) {
      try {
        await _engine!.leaveChannel();
      } catch (_) {}
      await _engine!.release();
      _engine = null;
      _isInitialized = false;
    }
  }

  RtcEngine? get engine => _engine;
}
