import 'package:arogya_path3/core/utils/api_config.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:async';

class SocketService {
  static SocketService? _instance;
  io.Socket? _socket;
  String? _currentUserId;
  bool _isConnecting = false;
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<void> _reconnectController =
      StreamController<void>.broadcast();

  static SocketService get instance {
    _instance ??= SocketService._();
    return _instance!;
  }

  SocketService._();

  io.Socket? get socket => _socket;
  bool get isConnected => _socket?.connected ?? false;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<void> get reconnectStream => _reconnectController.stream;
  String? get currentUserId => _currentUserId;

  Future<bool> connect(String userId) async {
    if (_isConnecting) {
      debugPrint('Socket connection in progress, skipping');
      return false;
    }

    if (_socket != null && _socket!.connected && _currentUserId == userId) {
      debugPrint('Socket already connected');
      _socket!.emit('joinUserRoom', userId);
      return true;
    }

    if (_socket != null && _currentUserId != userId) {
      disconnect();
    }

    _isConnecting = true;
    _currentUserId = userId;
    final completer = Completer<bool>();
    final String serverUrl = ApiConfig.baseUrl;

    debugPrint('Connecting socket â€” User: $userId, Server: $serverUrl');

    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(-1)
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(5000)
          .setTimeout(15000)
          .setExtraHeaders({'userId': userId})
          .setQuery({'userId': userId})
          .build(),
    );

    _setupListeners(userId, completer);
    _socket!.connect();

    return await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('Socket connection timeout');
        _isConnecting = false;
        return false;
      },
    );
  }

  void _setupListeners(String userId, Completer<bool> completer) {
    _socket!.onConnect((_) {
      debugPrint('Socket connected â€” ID: ${_socket!.id}');
      _socket!.emit('joinUserRoom', userId);
      Future.delayed(const Duration(milliseconds: 800), () {
        _connectionController.add(true);
        if (!completer.isCompleted) {
          completer.complete(true);
          _isConnecting = false;
        }
      });
    });

    _socket!.onDisconnect((reason) {
      debugPrint('Socket disconnected: $reason');
      _isConnecting = false;
      _connectionController.add(false);
    });

    _socket!.onConnectError((error) {
      debugPrint('Socket connect error: $error');
      if (!completer.isCompleted) {
        completer.complete(false);
        _isConnecting = false;
      }
    });

    _socket!.onError((error) => debugPrint('Socket error: $error'));

    _socket!.onReconnect((attempt) {
      debugPrint('Socket reconnected (attempt $attempt)');
      if (_currentUserId != null) {
        _socket!.emit('joinUserRoom', _currentUserId);
        _reconnectController.add(null);
      }
    });
  }

  Future<bool> emit(String event, dynamic data) async {
    if (_socket == null || !_socket!.connected) {
      debugPrint('Socket not connected, attempting reconnect...');
      if (_currentUserId != null) {
        ensureConnected();
        int retry = 0;
        while (retry < 5 && (_socket == null || !_socket!.connected)) {
          await Future.delayed(const Duration(milliseconds: 200));
          retry++;
        }
        if (_socket == null || !_socket!.connected) {
          debugPrint('Socket still not connected, skipping emit');
          return false;
        }
      } else {
        return false;
      }
    }

    try {
      _socket!.emit(event, data);
      return true;
    } catch (e) {
      debugPrint('Error emitting event: $e');
      return false;
    }
  }

  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void disconnect() {
    if (_socket != null) {
      if (_currentUserId != null && _socket!.connected) {
        _socket!.emit('user:offline', {'userId': _currentUserId});
      }
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _currentUserId = null;
      _isConnecting = false;
      debugPrint('Socket disconnected and disposed');
    }
  }

  Future<bool> ensureConnected() async {
    if (_socket == null || !_socket!.connected) {
      if (_currentUserId != null) return await connect(_currentUserId!);
      return false;
    }
    return true;
  }
}
