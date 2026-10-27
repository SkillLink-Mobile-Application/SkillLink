import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../utils/session.dart';
import 'dart:async';

// Yellow & black palette (local to this screen)
const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);

class ChatScreen extends StatefulWidget {
  final String otherUserEmail;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserEmail,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  List<dynamic> messages = [];

  bool isLoading = true;
  bool isSending = false;
  Timer? chatRefreshTimer;

  @override
    void initState() {
      super.initState();

      loadMessages();

      chatRefreshTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) {
          loadMessages(
            silent: true,
          );
        },
      );
    }

  // ==================== Load Messages ====================

  Future<void> loadMessages({
    bool silent = false,
  }) async {
    try {
      final result =
        await ApiService.getChatConversation(
      otherUserEmail: widget.otherUserEmail,
    );

      if (!mounted) return;

      if (!mounted) return;

        setState(() {
          messages = result;
          isLoading = false;
        });

        if (!silent) {
          scrollToBottom();
        }

      scrollToBottom();
    } catch (e) {
      debugPrint(
        'CHAT LOAD ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ==================== Send Message ====================

  Future<void> sendMessage() async {
    final message =
        messageController.text.trim();

    if (message.isEmpty) {
      return;
    }

    if (isSending) {
      return;
    }

    setState(() {
      isSending = true;
    });

    final result =
        await ApiService.sendChatMessage(
      receiverEmail: widget.otherUserEmail,
      message: messageController.text.trim(),
    );

    if (!mounted) return;

    if (result != null) {
      messageController.clear();

      await loadMessages();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to send message.',
          ),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      isSending = false;
    });
  }

  // ==================== Scroll ====================

  void scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        return;
      }

      scrollController.animateTo(
        scrollController
            .position
            .maxScrollExtent,
        duration:
            const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ==================== Message Bubble ====================

  Widget messageBubble(
    dynamic message,
  ) {
    final senderEmail =
        message['senderEmail']
                ?.toString() ??
            '';

    final text =
        message['message']
                ?.toString() ??
            '';

    final isMine =
        senderEmail == Session.email;

    final sentAt =
      message['sentAt']?.toString() ?? '';

    return Align(
      alignment: isMine
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
            const BoxConstraints(
          maxWidth: 300,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: isMine ? _kYellow : Colors.white,
          border: isMine
              ? null
              : Border.all(color: _kBorder),
          borderRadius:
              BorderRadius.only(
            topLeft:
                const Radius.circular(18),
            topRight:
                const Radius.circular(18),
            bottomLeft:
                Radius.circular(
              isMine ? 18 : 4,
            ),
            bottomRight:
                Radius.circular(
              isMine ? 4 : 18,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                height: 1.3,
                fontWeight:
                    isMine ? FontWeight.w600 : FontWeight.w500,
                color: _kBlack,
              ),
            ),
            if (sentAt.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                sentAt.length >= 16
                    ? sentAt.substring(11, 16)
                    : sentAt,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isMine
                      ? _kBlack.withValues(alpha: 0.55)
                      : _kTextSecondary,
                ),
              ),
            ],
          ],
        ),

      ),
    );
  }

  // ==================== Build ====================

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EmptyChatIcon(),
          SizedBox(height: 16),
          Text(
            'No messages yet.\nStart the conversation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: _kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBlack,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _kYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: _kBlack,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherUserName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color: _kBlack,
                    ),
                  )
                : messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller:
                            scrollController,
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          20,
                          16,
                          10,
                        ),
                        itemCount:
                            messages.length,
                        itemBuilder:
                            (context, index) {
                          return messageBubble(
                            messages[index],
                          );
                        },
                      ),
          ),

          // ==================== Message Input ====================

          SafeArea(
            top: false,
            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                10,
                12,
                10,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: _kBorder),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(
                      alpha: 0.05,
                    ),
                    blurRadius: 8,
                    offset:
                        const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                          messageController,
                      minLines: 1,
                      maxLines: 4,
                      cursorColor: _kBlack,
                      textInputAction:
                          TextInputAction.newline,
                      style: const TextStyle(
                        fontSize: 15,
                        color: _kBlack,
                      ),
                      decoration:
                          InputDecoration(
                        hintText:
                            'Type a message...',
                        hintStyle: const TextStyle(
                          color: _kTextSecondary,
                          fontSize: 14.5,
                        ),
                        filled: true,
                        fillColor:
                            const Color(0xFFF3F3EE),
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            24,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            24,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            24,
                          ),
                          borderSide:
                              const BorderSide(
                            color: _kYellow,
                            width: 1.6,
                          ),
                        ),
                      ),
                      onSubmitted: (_) {
                        sendMessage();
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  SizedBox(
                    width: 50,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSending
                          ? null
                          : sendMessage,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor: _kYellow,
                        foregroundColor: _kBlack,
                        disabledBackgroundColor:
                            _kYellow.withValues(
                          alpha: 0.65,
                        ),
                        disabledForegroundColor:
                            _kBlack,
                        elevation: 0,
                        shadowColor:
                            Colors.transparent,
                        shape:
                            const CircleBorder(),
                        padding:
                            EdgeInsets.zero,
                      ),
                      child: isSending
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: _kBlack,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .send_rounded,
                              size: 21,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    chatRefreshTimer?.cancel();

    messageController.dispose();
    scrollController.dispose();

    super.dispose();
  }
}

class _EmptyChatIcon extends StatelessWidget {
  const _EmptyChatIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: _kYellow.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.chat_bubble_outline_rounded,
        size: 38,
        color: _kBlack,
      ),
    );
  }
}