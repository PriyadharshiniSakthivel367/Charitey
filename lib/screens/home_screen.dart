import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/chat_service.dart';
import '../models/notification_model.dart';
import '../models/chat_preview_model.dart';
import 'donor_listing_screen.dart';
import 'ngo_dashboard.dart';
import 'profile_screen.dart';
import 'create_listing_screen.dart';
//import 'role_selection_screen.dart';
import 'package:charity_app/screens/role_selection_screen.dart';
import 'hero_page.dart';
import 'notifications_screen.dart';
import 'chat_screen.dart';
import 'travel_agency_dashboard.dart';

// =========================================================================
// 1. HOME SCREEN
// =========================================================================

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  final String? targetPostId;

  const HomeScreen({
    Key? key,
    this.initialIndex = 0,
    this.targetPostId,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  String? targetPostId;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    targetPostId  = widget.targetPostId;
  }

  void switchTab(int index, {String? postId}) {
    setState(() {
      _currentIndex = index;
      targetPostId  = postId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user         = authProvider.currentUserModel;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFB56F76)),
        ),
      );
    }

    List<Widget> screens;
    List<BottomNavigationBarItem> navItems;

    // --- 1. NGO ROLE ---
    if (user.role == 'ngo') {
      screens = [
        const HeroPage(),
        NgoDashboard(targetPostId: targetPostId),
        const CreateListingScreen(),
        const ChatListScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded),        label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded),   label: 'Activity'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded),  label: 'Request'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded),      label: 'Profile'),
      ];
    }
    // --- 2. TRAVEL AGENCY ROLE ---
    else if (user.role == 'travel_agency') {
      screens = [
        const HeroPage(),
        NgoDashboard(targetPostId: targetPostId),
        const TravelAgencyDashboard(),
        const ChatListScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded),            label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded),       label: 'Activity'),
        BottomNavigationBarItem(icon: Icon(Icons.local_shipping_rounded),  label: 'Deliveries'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded),     label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded),          label: 'Profile'),
      ];
    }
    // --- 3. DONOR / VOLUNTEER ROLE (Default) ---
    else {
      screens = [
        const HeroPage(),
        NgoDashboard(targetPostId: targetPostId),
        const DonorListingScreen(),
        const ChatListScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded),        label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded),   label: 'Activity'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded),    label: 'Donate'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded),      label: 'Profile'),
      ];
    }

    if (_currentIndex >= screens.length) _currentIndex = 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            // Dove icon (doc4) with fallback to app_logo (doc3)
            Image.asset(
              'assets/dove_icon.png',
              height: 74,
              width: 74,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/app_logo.png',
                  height: 36,
                  width: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 36,
                    width: 36,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              "CHARITEY",
              style: TextStyle(
                color: Color(0xFF7D444C),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          // Notification bell
          StreamBuilder<List<NotificationModel>>(
            stream: FirestoreService().getUserNotifications(user.uid),
            builder: (context, snapshot) {
              bool hasUnread = false;
              if (snapshot.hasData) {
                hasUnread =
                    snapshot.data!.any((n) => !n.isRead);
              }
              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_none_rounded,
                        color: Colors.black87, size: 26),
                    if (hasUnread)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          height: 10,
                          width: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.white,
                                  spreadRadius: 1,
                                  blurRadius: 1),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  );
                },
              );
            },
          ),

          // Three-dot overflow menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: Colors.black87, size: 26),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            offset: const Offset(0, 50),
            color: const Color(0xFFFFF0F1),
            onSelected: (String result) async {
              if (result == 'contact') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ContactUsScreen()));
              } else if (result == 'about') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AboutUsScreen()));
              } else if (result == 'feedback') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FeedbackScreen()));
              } else if (result == 'recent_donations') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const RecentDonationsScreen()));
              } else if (result == 'logout') {
                await authProvider.signOut();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RoleSelectionScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'contact',
                child: Row(children: [
                  const Icon(Icons.contact_mail_rounded,
                      color: Color(0xFF7D444C), size: 20),
                  const SizedBox(width: 12),
                  const Text('Contact Support',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                ]),
              ),
              PopupMenuItem<String>(
                value: 'about',
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF7D444C), size: 20),
                  const SizedBox(width: 12),
                  const Text('About Charitey',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                ]),
              ),
              PopupMenuItem<String>(
                value: 'feedback',
                child: Row(children: [
                  const Icon(Icons.feedback_rounded,
                      color: Color(0xFF7D444C), size: 20),
                  const SizedBox(width: 12),
                  const Text('Share Feedback',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                ]),
              ),
              // Impact History item (doc3 only)
              PopupMenuItem<String>(
                value: 'recent_donations',
                child: Row(children: [
                  const Icon(Icons.list_alt_rounded,
                      color: Color(0xFF7D444C), size: 20),
                  const SizedBox(width: 12),
                  const Text('Impact History',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                ]),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(children: const [
                  Icon(Icons.logout_rounded,
                      color: Colors.redAccent, size: 20),
                  SizedBox(width: 12),
                  Text('Sign Out',
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: screens[_currentIndex],

      // ================================================================
      // BOTTOM NAV BAR
      // Combines:
      //   • doc3 – glass blur pill bar (all tabs equal)
      //   • doc4 – arched overflow FAB for the centre action tab
      // Result: glass pill bar with an elevated centre FAB bubble.
      // ================================================================
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          height: 85,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Glass-blur pill background (doc3 style)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(
                        color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7D444C)
                            .withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                          sigmaX: 15, sigmaY: 15),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          navItems.length,
                          (index) {
                            // Leave a blank slot for the centre FAB
                            if (index == 2) {
                              return const Expanded(
                                  child: SizedBox.shrink());
                            }

                            final item   = navItems[index];
                            final icon   = (item.icon as Icon).icon!;
                            final label  = item.label ?? '';
                            final isActive =
                                _currentIndex == index;
                            const themeColor =
                                Color(0xFF7D444C);

                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _currentIndex = index;
                                    if (index != 1) {
                                      targetPostId = null;
                                    }
                                  });
                                },
                                behavior:
                                    HitTestBehavior.opaque,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                    Icon(
                                      icon,
                                      color: isActive
                                          ? themeColor
                                          : themeColor
                                              .withOpacity(
                                                  0.4),
                                      size: isActive
                                          ? 26
                                          : 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        color: isActive
                                            ? themeColor
                                            : themeColor
                                                .withOpacity(
                                                    0.4),
                                        fontSize: 10,
                                        fontWeight: isActive
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Arched overflow FAB for centre action tab (doc4)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = 2;
                        targetPostId  = null;
                      });
                    },
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7D444C),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7D444C)
                                .withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            (navItems[2].icon as Icon).icon!,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            navItems[2].label ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 2. CHAT LIST SCREEN
// =========================================================================

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user         = authProvider.currentUserModel;
    final chatService  = ChatService();
    const themeColor   = Color(0xFFB56F76);

    if (user == null) return const Center(child: Text("Please log in."));

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFDF7F8), Color(0xFFEEDAE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.1, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StreamBuilder<List<ChatPreviewModel>>(
          stream: chatService.getChatInbox(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                    color: themeColor),
              );
            }
            if (snapshot.hasError) {
              return const Center(
                  child: Text("Error loading chats."));
            }

            final chatPreviews = snapshot.data ?? [];

            if (chatPreviews.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.chat_bubble_outline,
                          size: 60,
                          color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 20),
                    const Text("No conversations yet",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text(
                      "Your active chats will appear here.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          height: 1.4),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding:
                  const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: chatPreviews.length,
              itemBuilder: (context, index) {
                final preview = chatPreviews[index];
                final formattedTime = DateFormat('h:mm a')
                    .format(preview.lastMessageTime);

                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                    // Profile image with fallback to initials (doc4)
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor:
                          themeColor.withOpacity(0.15),
                      backgroundImage: (preview.participantProfileImage !=
                                  null &&
                              preview.participantProfileImage!
                                  .isNotEmpty)
                          ? NetworkImage(
                              preview.participantProfileImage!)
                          : null,
                      child: (preview.participantProfileImage ==
                                  null ||
                              preview.participantProfileImage!
                                  .isEmpty)
                          ? Text(
                              preview.participantName.isNotEmpty
                                  ? preview.participantName[0]
                                      .toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: themeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      preview.participantName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        preview.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: preview.hasUnread
                              ? Colors.black87
                              : Colors.grey.shade600,
                          fontWeight: preview.hasUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    trailing: SizedBox(
                      width: 65,
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: preview.hasUnread
                                  ? themeColor
                                  : Colors.grey.shade500,
                            ),
                          ),
                          if (preview.hasUnread) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                  color: themeColor,
                                  shape: BoxShape.circle),
                            ),
                          ],
                        ],
                      ),
                    ),
                    onTap: () {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('chat_previews')
                          .doc(preview.chatRoomId)
                          .update({'hasUnread': false});
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            otherUserId:   preview.participantId,
                            otherUserName: preview.participantName,
                            // Pass profile image when available (doc4)
                            otherUserProfileImage:
                                preview.participantProfileImage,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// =========================================================================
// 3. POPUP MENU SCREENS
// =========================================================================

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  final Color themeColor = const Color(0xFF7D444C);
  final Color bgColor    = const Color(0xFFFBEBEB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context)),
        title: Text("About Charitey",
            style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.bold,
                fontSize: 24)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Our Mission",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            const Text(
              "Charitey is a platform that connects generous donors with NGOs, "
              "volunteers, and agencies to deliver help quickly and efficiently "
              "to those in need.",
              style: TextStyle(
                  fontSize: 15, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text("What We Do",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            _bullet("Connect donors with verified NGOs"),
            _bullet("Enable volunteers to contribute meaningfully"),
            _bullet("Coordinate logistics with partner agencies"),
            _bullet("Track impact and transparency"),
            _bullet("Make charitable giving easy and accessible"),
            const SizedBox(height: 24),
            const Text("Our Values",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            const Text(
              "Transparency • Trust • Impact •\nCommunity • Compassion",
              style: TextStyle(
                  fontSize: 15, color: Colors.black87, height: 1.5),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Close",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 15, height: 1.4))),
        ],
      ),
    );
  }
}

// ── Feedback Screen ────────────────────────────────────────────────────────

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  Map<int, int> answers = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  final Color themeColor = const Color(0xFF7D444C);
  final Color cardColor  = const Color(0xFFFFF0F1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context)),
        title: Text("Share Feedback",
            style: TextStyle(
                color: themeColor, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildQuestion(1, "Q1. Are notifications relevant and timely?"),
          _buildQuestion(2, "Q2. Are settings easy to find?"),
          _buildQuestion(3, "Q3. Would you recommend Charitey to others?"),
          _buildQuestion(4, "Q4. Did you find the NGO information useful?"),
          _buildQuestion(5, "Q5. Was it easy to contact support?"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: const Text('Feedback Submitted!'),
                    backgroundColor: themeColor),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Submit",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(int qIndex, String question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              int rating = index + 1;
              return GestureDetector(
                onTap: () =>
                    setState(() => answers[qIndex] = rating),
                child: Row(
                  children: [
                    Icon(
                      answers[qIndex] == rating
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: answers[qIndex] == rating
                          ? themeColor
                          : Colors.black54,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(rating.toString(),
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Recent Donations / Impact History Screen ───────────────────────────────

class RecentDonationsScreen extends StatelessWidget {
  const RecentDonationsScreen({super.key});

  final Color themeColor = const Color(0xFF7D444C);
  final Color cardColor  = const Color(0xFFFFF0F1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context)),
        title: Text("Recent Donations",
            style: TextStyle(
                color: themeColor, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Overview",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Raised",
                        style: TextStyle(color: Colors.grey)),
                    const Text("N/A",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text("0",
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                    const Text("Completed",
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Total Donations",
                        style: TextStyle(color: Colors.grey)),
                    const Text("93",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text("93",
                        style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold)),
                    const Text("Pending",
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text("Recent Donations",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildDonationCard("quFu5DfaelN06vmaaNjQ",
              "13 Apr 2026, 10:41 AM", "PENDING",
              Colors.grey.shade400),
          _buildDonationCard("88XkROatWB9TaLCCNKC8",
              "13 Apr 2026, 9:16 AM",
              "DELIVERY_ACCEPTED", Colors.orange),
          _buildDonationCard("gwTgwflYOQfFvgHOf274",
              "13 Apr 2026, 9:13 AM",
              "DELIVERY_ACCEPTED", Colors.orange),
        ],
      ),
    );
  }

  Widget _buildDonationCard(
      String id, String date, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Sree",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Text(status,
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text("ID: $id",
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text("Date: $date",
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Contact Us Screen ──────────────────────────────────────────────────────

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Support",
            style: TextStyle(
                color: Color(0xFF7D444C),
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const Center(
        child: Text(
          "Contact Support: support@charitey.com\nPhone: +91 9876543210",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}