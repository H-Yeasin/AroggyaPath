import 'dart:async';

import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'package:arogya_path3/providers/user_provider.dart';
import 'package:arogya_path3/screens/patient/navigation/patient_main_navigation.dart';
import 'package:arogya_path3/services/agora_chat_service.dart';
import 'package:arogya_path3/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/patient_chat_item.dart';

class PatientMessagesListScreen extends StatefulWidget {
  final String title;
  final String counterpartFallbackName;
  final String roleBadge;
  final bool showBackButton;

  const PatientMessagesListScreen({
    super.key,
    this.title = 'Messages',
    this.counterpartFallbackName = 'Doctor',
    this.roleBadge = 'Dr.',
    this.showBackButton = false,
  });

  @override
  State<PatientMessagesListScreen> createState() =>
      _PatientMessagesListScreenState();
}

class _PatientMessagesListScreenState extends State<PatientMessagesListScreen> {
  List<dynamic> _chats = [];
  bool _isLoading = true;
  String? _currentUserId;
  final Set<String> _selectedConversationIds = {}; // For multi-select delete
  bool _isSelectionMode = false; //  Selection mode toggle

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to access providers/context safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _currentUserId = userProvider.user?.id;

    if (_currentUserId == null) {
      await userProvider.fetchUserProfile();
      _currentUserId = userProvider.user?.id;
    }

    if (_currentUserId != null) {
      await _ensureAgoraConnection();
      _setupAgoraListener();
      _loadChats();
    }
  }

  // Setup Agora listener for real-time updates
  void _setupAgoraListener() {
    AgoraChatService.instance.addMessageListener(
      'patient_chat_list_refresher',
      ChatEventHandler(
        onMessagesReceived: (messages) {
          debugPrint('Agora message received in list - refreshing');
          _loadChatsQuietly(); // Reload chats when new message arrives
        },
      ),
    );
  }

  //  Silent reload (no loading indicator)
  Future<void> _loadChatsQuietly() async {
    await _loadChats(quiet: true);
  }

  Future<void> _ensureAgoraConnection() async {
    // 1. Initialize
    if (!AgoraChatService.instance.isConnected) {
      await AgoraChatService.instance.init();
    }
    // 2. Login Check
    try {
      final isLoggedIn = await ChatClient.getInstance.isLoginBefore();
      if (!isLoggedIn && _currentUserId != null) {
        debugPrint(
          ' ListScreen: Not logged in. logging in $_currentUserId...',
        );
        await AgoraChatService.instance.login(_currentUserId!);
      }
    } catch (e) {
      debugPrint(' ListScreen: Agora Auth Check Failed: $e');
    }
  }

  Future<void> _loadChats({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      debugPrint('Loading persisted chat user list from backend...');
      final response = await ApiService.getMyChats();

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Could not load chats');
      }

      final chats = response['data'] as List? ?? [];
      final formattedChats = chats.map<Map<String, dynamic>>((rawChat) {
        final chat = Map<String, dynamic>.from(rawChat as Map);
        final participants = chat['participants'] as List? ?? [];
        final otherUser = participants.firstWhere(
          (p) => p is Map && p['_id']?.toString() != _currentUserId,
          orElse: () {
            if (participants.isNotEmpty) {
              return participants.first;
            }
            return <dynamic>{};
          },
        );
        final other = otherUser is Map
            ? Map<String, dynamic>.from(otherUser)
            : <String, dynamic>{};
        final lastMessage = chat['lastMessage'];
        final lastMessageMap = lastMessage is Map
            ? Map<String, dynamic>.from(lastMessage)
            : <String, dynamic>{};

        return {
          '_id': chat['_id']?.toString() ?? '',
          'actualUserId': other['_id']?.toString() ?? '',
          'hasMessages': lastMessageMap.isNotEmpty,
          'fullName':
              other['fullName']?.toString() ?? widget.counterpartFallbackName,
          'avatarUrl': other['avatar'] is Map
              ? (other['avatar'] as Map)['url']?.toString()
              : null,
          'participants': participants,
          'lastMessage': {
            'content': _formatLastMessagePreview(lastMessageMap),
            'createdAt': lastMessageMap['createdAt']?.toString() ??
                chat['updatedAt']?.toString(),
          },
          'unreadCount': chat['unreadCount'] ?? 0,
          'updatedAt': lastMessageMap['createdAt']?.toString() ??
              chat['updatedAt']?.toString(),
        };
      }).where((chat) {
        return chat['_id'].toString().isNotEmpty &&
            chat['actualUserId'].toString().isNotEmpty &&
            chat['hasMessages'] == true;
      }).toList();

      formattedChats.sort((a, b) {
        final aDate = DateTime.tryParse(a['updatedAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(b['updatedAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      if (mounted) {
        setState(() {
          _chats = formattedChats;
          _isLoading = false;
        });
        debugPrint('Loaded ${_chats.length} persisted conversations');
      }
    } catch (e) {
      debugPrint(' Error loading chats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatLastMessagePreview(Map<String, dynamic> message) {
    final contentType = message['contentType']?.toString() ?? 'text';
    final content = message['content']?.toString().trim() ?? '';

    if (content.isNotEmpty) return content;
    if (contentType == 'image') return '[Image]';
    if (contentType == 'video') return '[Video]';
    if (contentType == 'audio') return '[Audio]';
    if (contentType == 'file') return '[File]';
    return 'No messages yet';
  }

  //  Multi-select Delete Helper
  void _toggleSelection(String convId) {
    setState(() {
      if (_selectedConversationIds.contains(convId)) {
        _selectedConversationIds.remove(convId);
        if (_selectedConversationIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedConversationIds.add(convId);
        _isSelectionMode = true;
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectedConversationIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelectedConversations() async {
    if (_selectedConversationIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Chats'),
        content:
            Text('Delete ${_selectedConversationIds.length} conversation(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final idsToDelete = _selectedConversationIds.toList();
        for (var id in idsToDelete) {
          final chat = _chats.cast<Map<String, dynamic>?>().firstWhere(
                (item) => item?['_id']?.toString() == id,
                orElse: () => null,
              );
          final conversationId = chat?['actualUserId']?.toString() ?? id;
          await AgoraChatService.instance.deleteConversation(
            conversationId: conversationId,
            deleteMessages: true,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Conversations deleted'),
            ),
          );
          _cancelSelection();
          _loadChats(); // Reload list
        }
      } catch (e) {
        debugPrint(' Failed to delete conversations: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete'),
            ),
          );
        }
      }
    }
  }

  void _goBackToHome() {
    if (!widget.showBackButton) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const PatientMainNavigation()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.showBackButton,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBackToHome();
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 248, 246, 246),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 80,
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: _cancelSelection,
                )
              : widget.showBackButton
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: _goBackToHome,
                    )
                  : null,
          title: Text(
            _isSelectionMode
                ? "${_selectedConversationIds.length} selected"
                : widget.title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: _isSelectionMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _deleteSelectedConversations,
                  ),
                  const SizedBox(width: 10),
                ]
              : null,
        ),
        body: RefreshIndicator(
          onRefresh: _loadChats,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _chats.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No conversations yet',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _loadChats,
                            icon: const Icon(Icons.refresh),
                            label: Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: _chats.length,
                      itemBuilder: (context, index) {
                        final chat = _chats[index];
                        final String convId = chat['_id']?.toString() ?? '';
                        return PatientChatItem(
                          chat: chat,
                          counterpartFallbackName:
                              widget.counterpartFallbackName,
                          roleBadge: widget.roleBadge,
                          isSelected: _selectedConversationIds.contains(convId),
                          isSelectionMode: _isSelectionMode,
                          onToggleSelection: _toggleSelection,
                          onChatUpdated: _loadChatsQuietly,
                        );
                      },
                    ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    AgoraChatService.instance.removeMessageListener(
      'patient_chat_list_refresher',
    );
    super.dispose();
  }
}
