import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/scheduler.dart';
import 'ProfileViewPage.dart';

class SwipePage extends StatefulWidget {
  const SwipePage({Key? key}) : super(key: key);

  @override
  _SwipePageState createState() => _SwipePageState();
}

class _SwipePageState extends State<SwipePage> with TickerProviderStateMixin, WidgetsBindingObserver {
  Map<String, dynamic>? currentChatUser;
  String? chatSessionId;
  bool isLoading = true;
  bool isPresenting = false;
  
  final TextEditingController messageController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  StreamSubscription? _chatSubscription;
  StreamSubscription? _matchingSubscription;
  Timer? _heartbeatTimer;
  Timer? _searchTimer;

  List<Map<String, dynamic>> messages = [];

  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;

  final Color primaryGreen = const Color(0xFF00B09B);
  final Color secondaryGreen = const Color(0xFF96C93D);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _setUserOnlineStatus(true);
    _startHeartbeat();
    
    _startMatchingFlow();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _searchTimer?.cancel();
    _chatSubscription?.cancel();
    _matchingSubscription?.cancel();
    _setUserOnlineStatus(false);
    
    messageController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    _rippleController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setUserOnlineStatus(true);
      _startHeartbeat();
      if (currentChatUser == null) {
        _startMatchingFlow();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _heartbeatTimer?.cancel();
      _searchTimer?.cancel();
      _setUserOnlineStatus(false);
    }
  }

  Future<void> _setUserOnlineStatus(bool isOnline) async {
    if (currentUserId.isEmpty) return;
    await FirebaseFirestore.instance.collection('users').doc(currentUserId).set(
        {
          'isOnline': isOnline,
          if (isOnline) 'lastActive': FieldValue.serverTimestamp(),
          if (!isOnline) 'lastSeen': FieldValue.serverTimestamp()
        },
        SetOptions(merge: true));
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (currentUserId.isNotEmpty) {
        FirebaseFirestore.instance.collection('users').doc(currentUserId).set(
            {'isOnline': true, 'lastActive': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
      }
    });
  }

  Future<void> _startMatchingFlow({bool isSkipped = false}) async {
    _searchTimer?.cancel();
    
    if (mounted) {
      setState(() {
        isLoading = true;
        isPresenting = false;
        if (currentChatUser == null) {
           chatSessionId = null;
           messages.clear();
        }
      });
    }

    await _updateUserSearchingStatus(true);

    _listenForUserDocumentChanges();

    _searchTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (currentChatUser == null) {
        _attemptActiveMatch();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _updateUserSearchingStatus(bool isSearchingStatus) async {
    if (currentUserId.isEmpty) return;
    await FirebaseFirestore.instance.collection('users').doc(currentUserId).set(
        {
          'isSearching': isSearchingStatus,
          'matchedWith': null,
          'chatSessionId': null
        },
        SetOptions(merge: true));
  }

  void _listenForUserDocumentChanges() {
    if (currentUserId.isEmpty) return;

    _matchingSubscription?.cancel();
    _matchingSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .listen((snapshot) async {
      
      if (!snapshot.exists) return;
      final data = snapshot.data();
      final matchedWithId = data?['matchedWith'];
      final currentSessionId = data?['chatSessionId'];

      if (currentChatUser != null && matchedWithId == null) {
        _handleRemoteDisconnection();
        return;
      }

      if (currentChatUser == null && matchedWithId != null && currentSessionId != null) {
        final matchedUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(matchedWithId)
            .get();

        if (matchedUserDoc.exists) {
          _searchTimer?.cancel();
          
          if (mounted) {
            setState(() {
              currentChatUser = {'uid': matchedUserDoc.id, ...matchedUserDoc.data()!};
              chatSessionId = currentSessionId;
              isLoading = false;
              isPresenting = true;
              messages.clear();
            });
          }
          
          _listenToMessages();
          
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() {
              isPresenting = false;
            });
          }
        }
      }
    });
  }

  Future<void> _attemptActiveMatch() async {
    if (currentUserId.isEmpty || currentChatUser != null || !mounted) return;

    try {
      final potentialMatches = await FirebaseFirestore.instance
          .collection('users')
          .where('isSearching', isEqualTo: true)
          .where('isOnline', isEqualTo: true)
          .limit(10)
          .get();

      final otherUsers = potentialMatches.docs
          .where((doc) => doc.id != currentUserId)
          .toList();

      if (otherUsers.isNotEmpty) {
        otherUsers.shuffle();
        final matchedUserDoc = otherUsers.first;

        final result = await FirebaseFirestore.instance.runTransaction((transaction) async {
          final matchedUserRef = FirebaseFirestore.instance.collection('users').doc(matchedUserDoc.id);
          final currentUserRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);

          final matchedUserSnapshot = await transaction.get(matchedUserRef);
          final currentUserSnapshot = await transaction.get(currentUserRef);

          if (matchedUserSnapshot.exists &&
              (matchedUserSnapshot.data()?['isSearching'] == true) &&
              matchedUserSnapshot.data()?['matchedWith'] == null &&
              currentUserSnapshot.exists &&
              (currentUserSnapshot.data()?['isSearching'] == true) &&
              currentUserSnapshot.data()?['matchedWith'] == null) {

            String newSessionId = '${_getStaticChatId(currentUserId, matchedUserDoc.id)}_${DateTime.now().millisecondsSinceEpoch}';

            transaction.update(matchedUserRef, {
              'isSearching': false,
              'matchedWith': currentUserId,
              'chatSessionId': newSessionId
            });
            
            transaction.update(currentUserRef, {
              'isSearching': false,
              'matchedWith': matchedUserDoc.id,
              'chatSessionId': newSessionId
            });

            return {'user': matchedUserDoc.data(), 'sessionId': newSessionId};
          }
          return null;
        });

        if (result != null) {
          _searchTimer?.cancel();
          
          if (mounted) {
            final resultMap = result as Map<String, dynamic>;
            final userMap = resultMap['user'] as Map<String, dynamic>;

            setState(() {
              currentChatUser = {'uid': matchedUserDoc.id, ...userMap};
              chatSessionId = resultMap['sessionId'] as String;
              isLoading = false;
              isPresenting = true;
              messages.clear();
            });
          }
          
          _listenToMessages();
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() {
              isPresenting = false;
            });
          }
        }
      }
    } catch (e) {
    }
  }

  void _handleRemoteDisconnection() {
    if (mounted) {
      _chatSubscription?.cancel();
      setState(() {
        currentChatUser = null;
        chatSessionId = null;
        isLoading = true;
        isPresenting = false;
        messages.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("L'altro utente ha lasciato la chat. Cerco un nuovo match...", 
            style: GoogleFonts.montserrat()),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        )
      );

      _startMatchingFlow();
    }
  }

  Future<void> _endChatAndRestart({required bool isSkippedByUser, bool isExiting = false}) async {
    _searchTimer?.cancel();
    _chatSubscription?.cancel();
    _matchingSubscription?.cancel();

    if (currentChatUser != null) {
      final otherUserId = currentChatUser!['uid'];
      
      WriteBatch batch = FirebaseFirestore.instance.batch();

      batch.update(FirebaseFirestore.instance.collection('users').doc(currentUserId),
          {'matchedWith': null, 'isSearching': false, 'chatSessionId': null});

      batch.update(FirebaseFirestore.instance.collection('users').doc(otherUserId),
          {'matchedWith': null, 'isSearching': false, 'chatSessionId': null});

      if (isSkippedByUser && chatSessionId != null) {
        await FirebaseFirestore.instance.collection('chats').doc(chatSessionId).collection('messages').add({
          'senderId': 'system',
          'text': 'L\'utente ha lasciato la chat.',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    }

    if (!isExiting && mounted) {
      setState(() {
        currentChatUser = null;
        chatSessionId = null;
        isLoading = true;
        isPresenting = false;
        messages.clear();
      });
      _startMatchingFlow(isSkipped: true);
    }
  }

  void _listenToMessages() {
    if (currentChatUser == null || chatSessionId == null) return;

    _chatSubscription?.cancel();
    _chatSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatSessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      final newMessages = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      if (mounted) {
        setState(() {
          messages = newMessages;
        });
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }, onError: (error) {});
  }

  void _sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || currentChatUser == null || chatSessionId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatSessionId)
          .set({'user1': currentUserId, 'user2': currentChatUser!['uid'], 'active': true},
          SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatSessionId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'receiverId': currentChatUser!['uid'],
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      messageController.clear();
      _inputFocusNode.requestFocus();
    } catch (e) {}
  }

  String _getStaticChatId(String user1Id, String user2Id) {
    List<String> ids = [user1Id, user2Id];
    ids.sort();
    return ids.join('_');
  }

  void _skipChat() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Salta chat', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        content: Text('Vuoi davvero passare a un\'altra persona?', style: GoogleFonts.montserrat()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('No', style: GoogleFonts.montserrat(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Sì', style: GoogleFonts.montserrat(color: primaryGreen, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm == true && currentChatUser != null) {
      _endChatAndRestart(isSkippedByUser: true);
    }
  }

  Future<bool> _onWillPop() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Uscita', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        content: Text('Tornando al menu la ricerca o la chat verrà interrotta. Confermi?', style: GoogleFonts.montserrat()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annulla', style: GoogleFonts.montserrat(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Conferma', style: GoogleFonts.montserrat(color: primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _endChatAndRestart(isSkippedByUser: true, isExiting: true);
      return true;
    }
    return false;
  }

  void _openUserProfile() {
    if (currentChatUser == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileViewPage(
          userData: currentChatUser!,
          distance: null,
        ),
      ),
    );
  }

  String getGenderLabel(String gender) {
    gender = gender.toLowerCase();
    if (gender == 'maschio') return 'Uomo';
    if (gender == 'femmina') return 'Donna';
    return gender;
  }

  Widget _buildDecorativeCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && currentChatUser == null && !isPresenting) {
      return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryGreen, secondaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                top: -50,
                left: -50,
                child: _buildDecorativeCircle(Colors.white.withOpacity(0.1), 200),
              ),
              Positioned(
                bottom: 100,
                right: -30,
                child: _buildDecorativeCircle(Colors.white.withOpacity(0.1), 150),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _rippleAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 150 * _rippleAnimation.value + 100,
                              height: 150 * _rippleAnimation.value + 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(1 - _rippleAnimation.value),
                                  width: 2,
                                ),
                              ),
                            );
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: const Icon(Icons.radar_rounded, size: 60, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    Text(
                      'Cercando qualcuno...',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Resta in attesa, presto farai match!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isPresenting && currentChatUser != null) {
      final gender = (currentChatUser!['gender'] ?? '').toLowerCase();
      final imageAsset = gender == 'maschio'
          ? 'assets/images/male.png'
          : gender == 'femmina'
          ? 'assets/images/female.png'
          : 'assets/images/male.png';

      return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryGreen, secondaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _rippleController,
                        curve: Curves.elasticOut,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 30,
                              offset: Offset(0, 10),
                            )
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundImage: AssetImage(imageAsset),
                          radius: 90,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Match Trovato!',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        color: Colors.white70,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentChatUser!['name'] ?? '',
                      style: GoogleFonts.montserrat(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${getGenderLabel(currentChatUser!['gender'] ?? '')}, ${currentChatUser!['age']} anni',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F6F9),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.grey[800]),
            onPressed: () => _onWillPop().then((value) {
              if (value) Navigator.pop(context);
            }),
          ),
          title: GestureDetector(
            onTap: _openUserProfile,
            child: Row(
              children: [
                Hero(
                  tag: 'profile_pic_chat',
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [primaryGreen, secondaryGreen]),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage(
                        (currentChatUser!['gender']?.toString().toLowerCase() == 'femmina')
                            ? 'assets/images/female.png'
                            : 'assets/images/male.png',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentChatUser!['name'] ?? '',
                        style: GoogleFonts.montserrat(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Online',
                            style: GoogleFonts.montserrat(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: Colors.red.withOpacity(0.1),
                radius: 20,
                child: IconButton(
                  icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 20),
                  tooltip: 'Salta chat',
                  onPressed: _skipChat,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F6F9),
                ),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  controller: _scrollController,
                  itemCount: messages.length,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    bool isMe = msg['senderId'] == currentUserId;
                    bool isSystem = msg['senderId'] == 'system';

                    if (isSystem) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            msg['text'] ?? '',
                            style: GoogleFonts.montserrat(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      );
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                        decoration: BoxDecoration(
                          gradient: isMe
                              ? LinearGradient(
                                  colors: [primaryGreen, secondaryGreen],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isMe ? null : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(24),
                            topRight: const Radius.circular(24),
                            bottomLeft: Radius.circular(isMe ? 24 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isMe ? 0.2 : 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: GoogleFonts.montserrat(
                            color: isMe ? Colors.white : const Color(0xFF333333),
                            fontSize: 15,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F6F9),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: TextField(
                        controller: messageController,
                        focusNode: _inputFocusNode,
                        style: GoogleFonts.montserrat(color: Colors.black87, fontWeight: FontWeight.w500),
                        textInputAction: TextInputAction.send,
                        maxLines: null,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Scrivi un messaggio...',
                          hintStyle: GoogleFonts.montserrat(color: Colors.grey[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryGreen, secondaryGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}