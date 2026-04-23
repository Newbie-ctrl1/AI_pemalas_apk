import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/chat_bubble.dart';
import 'login_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _threadSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<ChatThread> _threads = [];
  bool _isSending = false;
  bool _isLoadingHistory = false;
  bool _isLoadingThreads = false;
  bool _isCreatingThread = false;
  int? _activeThreadId;
  String? _token;

  static const Color _pageTop = Color(0xFFFDFEFF);
  static const Color _pageMid = Color(0xFFEFF6FF);
  static const Color _pageBottom = Color(0xFFDCEBFF);

  @override
  void dispose() {
    _controller.dispose();
    _threadSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await AuthService.instance.getToken();
    if (!mounted) return;
    setState(() => _token = token);

    if (token == null || token.isEmpty) {
      setState(() {
        _messages
          ..clear()
          ..add(
            ChatMessage(
              text: 'Token belum ada. Login ulang dulu ya.',
              isUser: false,
              createdAt: DateTime.now(),
            ),
          );
      });
      return;
    }

    await _loadThreads();
  }

  Future<void> _loadThreads() async {
    if (_token == null || _token!.isEmpty) return;

    setState(() => _isLoadingThreads = true);
    try {
      final query = _threadSearchController.text.trim();
      final threads = await ApiService.instance.getThreads(
        token: _token!,
        query: query.isEmpty ? null : query,
      );
      if (!mounted) return;

      setState(() {
        _threads
          ..clear()
          ..addAll(threads);
        _activeThreadId ??= _threads.isNotEmpty ? _threads.first.id : null;
      });

      if (_activeThreadId != null) {
        await _loadMessages(_activeThreadId!);
      } else {
        setState(() {
          _messages
            ..clear()
            ..add(
              ChatMessage(
                text: 'Belum ada topik chat. Klik New Chat dulu.',
                isUser: false,
                createdAt: DateTime.now(),
              ),
            );
        });
      }
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..add(
            ChatMessage(
              text: 'Gagal ambil history: ${err.toString().replaceFirst('Exception: ', '')}',
              isUser: false,
              createdAt: DateTime.now(),
            ),
          );
      });
    } finally {
      if (mounted) setState(() => _isLoadingThreads = false);
    }
  }

  Future<void> _loadMessages(int threadId) async {
    if (_token == null || _token!.isEmpty) return;

    setState(() => _isLoadingHistory = true);
    try {
      final rows = await ApiService.instance.getThreadMessages(token: _token!, threadId: threadId);
      if (!mounted) return;

      final loaded = <ChatMessage>[];
      for (final row in rows) {
        final userMsg = ChatMessage.fromJson(row, isUser: true);
        final aiMsg = ChatMessage.fromJson(row, isUser: false);
        if (userMsg.text.trim().isNotEmpty) loaded.add(userMsg);
        if (aiMsg.text.trim().isNotEmpty) loaded.add(aiMsg);
      }

      setState(() {
        _activeThreadId = threadId;
        _messages
          ..clear()
          ..addAll(
            loaded.isNotEmpty
                ? loaded
                : [
                    ChatMessage(
                      text: 'Topik ini masih kosong. Mulai chat aja.',
                      isUser: false,
                      createdAt: DateTime.now(),
                    ),
                  ],
          );
      });
      _scrollToBottom();
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..add(
            ChatMessage(
              text: 'Gagal ambil pesan: ${err.toString().replaceFirst('Exception: ', '')}',
              isUser: false,
              createdAt: DateTime.now(),
            ),
          );
      });
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _createNewThread() async {
    if (_token == null || _token!.isEmpty || _isCreatingThread) return;

    setState(() => _isCreatingThread = true);
    try {
      final thread = await ApiService.instance.createThread(token: _token!, title: 'Chat Baru');
      if (!mounted) return;

      setState(() {
        _threads.insert(0, thread);
        _activeThreadId = thread.id;
        _messages
          ..clear()
          ..add(
            ChatMessage(
              text: 'Topik baru siap. Tulis pertanyaanmu.',
              isUser: false,
              createdAt: DateTime.now(),
            ),
          );
      });
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isCreatingThread = false);
    }
  }

  Future<void> _deleteThread(ChatThread thread) async {
    if (_token == null || _token!.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Topik?'),
          content: Text('Topik "${thread.title}" akan dihapus permanen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ApiService.instance.deleteThread(token: _token!, threadId: thread.id);
      if (!mounted) return;

      setState(() {
        _threads.removeWhere((t) => t.id == thread.id);
        if (_activeThreadId == thread.id) {
          _activeThreadId = _threads.isNotEmpty ? _threads.first.id : null;
        }
      });

      if (_activeThreadId != null) {
        await _loadMessages(_activeThreadId!);
      } else {
        setState(() {
          _messages
            ..clear()
            ..add(
              ChatMessage(
                text: 'Belum ada topik chat. Klik New Chat dulu.',
                isUser: false,
                createdAt: DateTime.now(),
              ),
            );
        });
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _sendMessage() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || _isSending) return;

    if (_token == null || _token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token belum ada. Login ulang dulu.')),
      );
      return;
    }

    if (_activeThreadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buat New Chat dulu.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _messages.add(
        ChatMessage(text: prompt, isUser: true, createdAt: DateTime.now()),
      );
    });
    _controller.clear();

    _scrollToBottom();

    try {
      final reply = await ApiService.instance.sendChatToThread(
        prompt: prompt,
        token: _token!,
        threadId: _activeThreadId,
      );
      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            text: reply,
            isUser: false,
            createdAt: DateTime.now(),
          ),
        );
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Gagal kirim: ${err.toString().replaceFirst('Exception: ', '')}',
            isUser: false,
            createdAt: DateTime.now(),
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _logout() async {
    await AuthService.instance.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTitle = _threads.firstWhere(
      (t) => t.id == _activeThreadId,
      orElse: () => ChatThread(id: 0, title: 'sutar si ai pemalas', updatedAt: DateTime.now()),
    ).title;

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawerScrimColor: Colors.black.withOpacity(0.14),
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.50),
                  Colors.white.withOpacity(0.22),
                ],
              ),
              border: Border(
                right: BorderSide(color: Colors.white.withOpacity(0.34)),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.34)),
                        ),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFF0F172A),
                            shadowColor: Colors.transparent,
                          ),
                          onPressed: _isCreatingThread ? null : _createNewThread,
                          icon: _isCreatingThread
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add_comment_rounded),
                          label: const Text('New Chat'),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: TextField(
                        controller: _threadSearchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _loadThreads(),
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        cursorColor: const Color(0xFF2563EB),
                        decoration: InputDecoration(
                          hintText: 'Cari topik...',
                          hintStyle: const TextStyle(color: Color(0xFF64748B)),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF334155)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.34),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.24)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.24)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(18)),
                            borderSide: BorderSide(color: Color(0xFF93C5FD)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadThreads,
                    child: ListView.builder(
                      itemCount: _threads.length,
                      itemBuilder: (context, index) {
                        final thread = _threads[index];
                        final active = thread.id == _activeThreadId;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: active
                                      ? Colors.white.withOpacity(0.30)
                                      : Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: active
                                        ? Colors.white.withOpacity(0.42)
                                        : Colors.white.withOpacity(0.22),
                                  ),
                                ),
                                child: ListTile(
                                  selected: active,
                                  selectedColor: const Color(0xFF0F172A),
                                  iconColor: const Color(0xFF334155),
                                  leading: const Icon(Icons.forum_outlined),
                                  title: Text(
                                    thread.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Color(0xFF0F172A)),
                                  ),
                                  subtitle: Text(
                                    '${thread.updatedAt.hour.toString().padLeft(2, '0')}:${thread.updatedAt.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: Color(0xFF475569)),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded),
                                    color: const Color(0xFF334155),
                                    tooltip: 'Hapus topik',
                                    onPressed: () => _deleteThread(thread),
                                  ),
                                  onTap: () async {
                                    Navigator.of(context).maybePop();
                                    await _loadMessages(thread.id);
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.18),
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        title: Text(activeTitle),
        actions: [
          IconButton(
            onPressed: _isLoadingThreads ? null : _loadThreads,
            icon: _isLoadingThreads
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: _isCreatingThread ? null : _createNewThread,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New Chat',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.26)),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _pageTop,
                    _pageMid,
                    _pageBottom,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 36,
                    right: -48,
                    child: Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.18),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 70,
                    left: -56,
                    child: Container(
                      height: 220,
                      width: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.14),
                      ),
                    ),
                  ),
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return Align(
                        alignment: _messages[index].isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: ChatBubble(message: _messages[index]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.28)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            enabled: !_isSending,
                            style: const TextStyle(color: Color(0xFF0F172A)),
                            cursorColor: const Color(0xFF2563EB),
                            decoration: InputDecoration(
                              hintText: 'Ketik pertanyaan...',
                              hintStyle: const TextStyle(color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.42),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.22)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(18)),
                                borderSide: BorderSide(color: Color(0xFF93C5FD)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.50),
                                Colors.white.withOpacity(0.22),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.28)),
                          ),
                          child: IconButton(
                            onPressed: _isSending ? null : _sendMessage,
                            color: const Color(0xFF0F172A),
                            icon: _isSending
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}