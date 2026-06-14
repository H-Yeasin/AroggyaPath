
import 'package:flutter/material.dart';
import '../../../../screens/patient/messages/patient_chat_screen.dart';
import 'package:arogya_path3/screens/patient/navigation/patient_main_navigation.dart';
import 'package:arogya_path3/services/api_service.dart';
import 'package:arogya_path3/services/agora_chat_service.dart';
import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'package:provider/provider.dart';
import 'package:arogya_path3/providers/user_provider.dart';
import 'dart:async';

class PatientMessagesListScreen extends StatefulWidget {
  const PatientMessagesListScreen({super.key});

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
          debugPrint('📨 Agora message received in list - refreshing');
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
      debugPrint('🔍 Loading patient chats from Agora SDK...');
      // 1. Fetch conversations from Agora
      final List<ChatConversation> conversations = await AgoraChatService
          .instance
          .fetchConversations();

      // 2. Pre-fetch details for sorting
      List<Map<String, dynamic>> tempChats = [];

      for (var conv in conversations) {
        if (conv.id.isEmpty) continue; 

        final lastMsg = await conv.latestMessage(); 
        if (lastMsg == null) continue;

        tempChats.add({
          'conv': conv,
          'lastMsg': lastMsg,
          'time': lastMsg.serverTime,
        });
      }

      // Sort by time descending
      tempChats.sort((a, b) => (b['time'] as int).compareTo(a['time'] as int));


      if (!mounted) return;
      final List<Map<String, dynamic>> formattedChats = await Future.wait(
        tempChats.map((item) async {
          final conv = item['conv'] as ChatConversation;
          final lastMsg = item['lastMsg'] as ChatMessage;
          final conversationId = conv.id;

          try {
            String fullName = 'Doctor';
            String? avatarUrl;

            // Resolve backend chatId and doctor profile
            final result = await ApiService.createOrGetChat(userId: conversationId);
            if (result['success'] == true) {
              final chatData = result['data'];
              final backendChatId = chatData['_id']?.toString();
              
              final participants = chatData['participants'] as List;
              final otherUser = participants.firstWhere(
                (p) => p['_id'] != _currentUserId,
                orElse: () => participants[0],
              );
              
              fullName = otherUser['fullName'] ?? 'Doctor';
              avatarUrl = otherUser['avatar']?['url'];

              // Format for UI
              String content = '';
              if (lastMsg.attributes?['type'] == 'call_log') {
                final isVideo = lastMsg.attributes?['call_type'] == 'video';
                content = isVideo
                    ? ('Video Call')
                    : ('Voice Call');
              } else if (lastMsg.body.type == MessageType.TXT) {
                content = (lastMsg.body as ChatTextMessageBody).content;
              } else if (lastMsg.body.type == MessageType.IMAGE) {
                content = '[Image]';
              } else if (lastMsg.body.type == MessageType.FILE) {
                content = '[File]';
              } else {
                content = '[Message]';
              }

              // Get unread count from backend instead of Agora
              int unreadCount = 0;
              if (backendChatId != null) {
                try {
                  final messagesResult = await ApiService.getChatMessages(
                    chatId: backendChatId,
                    page: 1,
                    limit: 100, // Get recent messages to count unread
                  );
                  if (messagesResult['success'] == true) {
                    final messages = messagesResult['data']['items'] as List;
                    // Count messages where isRead is false
                    unreadCount = messages.where((msg) => msg['isRead'] == false).length;
                  }
                } catch (e) {
                  debugPrint(' Could not fetch unread count for $backendChatId: $e');
                  // Fallback to Agora count
                  unreadCount = await conv.unreadCount();
                }
              } else {
                unreadCount = await conv.unreadCount();
              }

              return {
                '_id': backendChatId ?? conversationId,
                'actualUserId': conversationId,
                'fullName': fullName,
                'avatarUrl': avatarUrl,
                'lastMessage': {
                  'content': content,
                  'createdAt': DateTime.fromMillisecondsSinceEpoch(
                    lastMsg.serverTime,
                  ).toIso8601String(),
                },
                'unreadCount': unreadCount, 
                'updatedAt': DateTime.fromMillisecondsSinceEpoch(
                  lastMsg.serverTime,
                ).toIso8601String(),
              };
            }
            // Fallback return if success is false
            return {
              '_id': conversationId,
              'actualUserId': conversationId,
              'participants': [],
              'lastMessage': {
                'content': '',
                'createdAt': DateTime.fromMillisecondsSinceEpoch(
                  lastMsg.serverTime,
                ).toIso8601String(),
              },
              'unreadCount': 0,
              'updatedAt': DateTime.fromMillisecondsSinceEpoch(
                lastMsg.serverTime,
              ).toIso8601String(),
            };
          } catch (e) {
            debugPrint(' Could not resolve chat/user $conversationId: $e');
            // Fallback return for error
            return {
              '_id': conversationId,
              'actualUserId': conversationId,
              'participants': [],
              'lastMessage': {
                'content': '',
                'createdAt': DateTime.now().toIso8601String(),
              },
              'unreadCount': 0,
              'updatedAt': DateTime.now().toIso8601String(),
            };
          }
        }),
      );

      if (mounted) {
        setState(() {
          _chats = formattedChats;
          _isLoading = false;
        });
        debugPrint(' Loaded ${_chats.length} conversations from Agora');
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
        content: Text(
              'Delete ${_selectedConversationIds.length} conversation(s)?'),

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
          await AgoraChatService.instance.deleteConversation(
            conversationId: id,
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const PatientMainNavigation()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
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
              : IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: _goBackToHome,
                ),
          title: Text(
            _isSelectionMode
                ? "${_selectedConversationIds.length} selected"
                : 'Messages',
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
                    return _buildChatItem(_chats[index]);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final participants = chat['participants'] as List? ?? [];

    //  Robust search for doctor participant to avoid TypeError
    Map<String, dynamic>? doctor;
    for (var p in participants) {
      if (p is Map && p['role'] == 'doctor') {
        doctor = Map<String, dynamic>.from(p);
        break;
      }
    }

    if (doctor == null) {
      // Fallback: use pre-fetched name/avatar from the chat data directly
      doctor = {};
    }

    final String doctorName = doctor['fullName']?.toString() ??
        chat['fullName']?.toString() ??
        'Doctor';
    final String? doctorAvatar = doctor['avatar']?['url']?.toString() ??
        chat['avatarUrl']?.toString();
    final String doctorId = doctor['_id']?.toString() ?? '';

    final lastMessage = chat['lastMessage'];
    final String messageText = lastMessage != null
        ? (lastMessage['content']?.toString() ??
              'Start Conversation')
        : 'Start Conversation';

    //  Get unread count
    final int unreadCount = chat['unreadCount'] ?? 0;

    final DateTime? updatedAt = chat['updatedAt'] != null
        ? DateTime.tryParse(chat['updatedAt'].toString())
        : null;
    final String timeText = updatedAt != null ? _formatTime(updatedAt) : '';

    final String convId = chat['_id']?.toString() ?? '';
    final bool isSelected = _selectedConversationIds.contains(convId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          if (_isSelectionMode) {
            _toggleSelection(convId);
            return;
          }

          final String backendId = chat['_id']?.toString() ?? '';
          final String actualUserId =
              chat['actualUserId']?.toString() ?? backendId;

          debugPrint(' [PATIENT] Opening chat: $backendId (User: $actualUserId)');
          debugPrint('   • Current unread count: $unreadCount');

          //  Mark as read immediately (optimistic UI update)
          if (unreadCount > 0) {
            setState(() {
              chat['unreadCount'] = 0;
            });
            debugPrint('   • Optimistically set unread count to 0');

            // Mark all messages as read in both Agora and backend
            bool agoraSuccess = false;
            bool backendSuccess = false;
            
            try {
              // Agora SDK - MUST use UserID
              await AgoraChatService.instance.markAllMessagesAsRead(actualUserId);
              agoraSuccess = true;
              debugPrint(' Marked conversation $actualUserId as read in Agora');
            } catch (e) {
              debugPrint(' Failed to mark as read in Agora: $e');
            }

            try {
              // Backend API - MUST use ChatID
              final result = await ApiService.markChatAsRead(chatId: backendId);
              backendSuccess = result['success'] == true;
              if (backendSuccess) {
                debugPrint(' Marked conversation $backendId as read in backend');
              } else {
                debugPrint(' Backend mark as read failed: ${result['message']}');
              }
            } catch (e) {
              debugPrint('Failed to mark as read in backend: $e');
            }

            // Show error feedback if both failed
            if (!agoraSuccess && !backendSuccess && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to mark as read'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }

          // Navigate to chat screen
          if (!mounted) return;
          debugPrint('   • Navigating to chat screen...');
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                chatId: backendId,
                doctorName: doctorName,
                doctorAvatar: doctorAvatar,
                doctorId: actualUserId,
              ),
            ),
          ).then((_) {
            debugPrint('   • Returned from chat screen, refreshing list...');
            //  Reload chats when returning to update unread counts
            if (mounted) _loadChatsQuietly();
          });
        },
        onLongPress: () => _toggleSelection(convId),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[50] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: Colors.blue.shade300)
                : Border.all(color: Colors.transparent),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    doctorAvatar != null &&
                        doctorAvatar.isNotEmpty &&
                        doctorAvatar != 'file:///' &&
                        (doctorAvatar.startsWith('http://') ||
                            doctorAvatar.startsWith('https://'))
                    ? Image.network(
                        doctorAvatar,
                        height: 56,
                        width: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              "assets/images/doctor1.png",
                              height: 56,
                              width: 56,
                              fit: BoxFit.cover,
                            ),
                      )
                    : Image.asset(
                        "assets/images/doctor1.png",
                        height: 56,
                        width: 56,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doctorName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B2C49),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Dr.',
                            style: TextStyle(
                              color: Color(0xFF1E61D4),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    //  Added unread count display
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            messageText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unreadCount > 0
                                  ? const Color(0xFF1B2C49)
                                  : Colors.grey,
                              fontSize: 14,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        //  Unread badge
                        if (unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C5CE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeText,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  @override
  void dispose() {
    AgoraChatService.instance.removeMessageListener(
      'patient_chat_list_refresher',
    );
    super.dispose();
  }
}
