import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:arogya_path3/models/appointment_message_model.dart';
import 'package:arogya_path3/models/appointment_model.dart';
import 'package:arogya_path3/providers/user_provider.dart';
import 'package:arogya_path3/screens/shared/appointment_chat_screen.dart';
import 'package:arogya_path3/services/appointment_message_service.dart';
import 'package:arogya_path3/services/appointment_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MessagesListScreen extends StatefulWidget {
  final String title;
  final String counterpartFallbackName;
  final String roleBadge;
  final bool showBackButton;
  final WidgetBuilder? backDestinationBuilder;

  const MessagesListScreen({
    super.key,
    this.title = 'Messages',
    this.counterpartFallbackName = 'Doctor',
    this.roleBadge = 'Dr.',
    this.showBackButton = false,
    this.backDestinationBuilder,
  });

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _AppointmentConversation {
  final AppointmentModel appointment;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final String? counterpartName;
  final String? counterpartImage;

  _AppointmentConversation({
    required this.appointment,
    this.lastMessageContent,
    this.lastMessageAt,
    this.counterpartName,
    this.counterpartImage,
  });
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  final _appointmentService = AppointmentService();
  final _messageService = AppointmentMessageService();

  List<_AppointmentConversation> _conversations = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
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

    await _loadConversations();
  }

  Future<void> _loadConversations({bool quiet = false}) async {
    if (!quiet && mounted) setState(() => _isLoading = true);

    try {
      final response = await _appointmentService.getMyAppointments();

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Could not load appointments');
      }

      final rawList = response['data'] as List? ?? [];
      final appointments = rawList
          .whereType<Map<String, dynamic>>()
          .map(AppointmentModel.fromJson)
          .toList();

      final List<_AppointmentConversation> conversations = [];

      for (final appt in appointments) {
        try {
          final msgResponse = await _messageService.getMessages(appt.id);
          final messages =
              (msgResponse['messages'] as List<AppointmentMessageModel>?) ?? [];

          if (messages.isEmpty) continue;

          final lastMsg = messages.last;
          final isCurrentUserTheDoctor = appt.doctorId == _currentUserId;
          final counterpartName =
              isCurrentUserTheDoctor ? appt.patientName : appt.doctorName;
          final counterpartImage =
              isCurrentUserTheDoctor ? appt.patientImage : appt.doctorImage;

          conversations.add(_AppointmentConversation(
            appointment: appt,
            lastMessageContent: lastMsg.content,
            lastMessageAt: lastMsg.createdAt,
            counterpartName: counterpartName,
            counterpartImage: counterpartImage,
          ));
        } catch (_) {
          // Keep the list usable if one appointment's messages fail to load.
        }
      }

      conversations.sort((a, b) {
        final aDate = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
        debugPrint('Loaded ${_conversations.length} persisted conversations');
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleBack() {
    if (!widget.showBackButton) return;

    final destinationBuilder = widget.backDestinationBuilder;
    if (destinationBuilder == null) {
      Navigator.maybePop(context);
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: destinationBuilder),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.showBackButton,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 248, 246, 246),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 80,
          leading: widget.showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: _handleBack,
                )
              : null,
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadConversations,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _conversations.isEmpty
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
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _loadConversations,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conv = _conversations[index];
                        return _ConversationTile(
                          conversation: conv,
                          roleBadge: widget.roleBadge,
                          counterpartFallbackName:
                              widget.counterpartFallbackName,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AppointmentChatScreen(
                                  appointmentId: conv.appointment.id,
                                  title: conv.counterpartName ??
                                      widget.counterpartFallbackName,
                                ),
                              ),
                            );
                            _loadConversations(quiet: true);
                          },
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final _AppointmentConversation conversation;
  final String roleBadge;
  final String counterpartFallbackName;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.roleBadge,
    required this.counterpartFallbackName,
    required this.onTap,
  });

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final counterpartName =
        conversation.counterpartName ?? counterpartFallbackName;
    final avatarUrl = conversation.counterpartImage;
    final lastMsg = conversation.lastMessageContent ?? 'No messages yet';
    final timeText = _formatTime(conversation.lastMessageAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                child: avatarUrl != null &&
                        avatarUrl.isNotEmpty &&
                        (avatarUrl.startsWith('http://') ||
                            avatarUrl.startsWith('https://'))
                    ? Image.network(
                        avatarUrl,
                        height: 56,
                        width: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/doctor1.png',
                          height: 56,
                          width: 56,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/images/doctor1.png',
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
                            counterpartName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.heading,
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
                          child: Text(
                            roleBadge,
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
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
}
