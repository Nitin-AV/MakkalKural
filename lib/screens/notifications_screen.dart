import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_civic_connect/utils/my_navigator.dart';
import 'package:smart_civic_connect/services/notif_badge.dart';

// ─── Notification model ──────────────────────────────────────────────────────

enum _NType { statusUpdate, workerAssigned, reviewRequired }

class _AppNotification {
  final String id;
  final _NType type;
  final String complaintId;
  final String issueName;
  final String message;
  final String? statusValue;
  final DateTime createdAt;

  const _AppNotification({
    required this.id,
    required this.type,
    required this.complaintId,
    required this.issueName,
    required this.message,
    this.statusValue,
    required this.createdAt,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final supabase = Supabase.instance.client;

  bool _loading = true;
  List<_AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      await NotifBadgeService.load();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await NotifBadgeService.setCount(0);
        setState(() { _notifications = []; _loading = false; });
        return;
      }

      final data = await supabase
          .from('complaints')
          .select('id, complaint_id, issue_name, status, assigned_worker_id, rating, created_at')
          .eq('user_id', user.uid)
          .order('created_at', ascending: false);

      final List<_AppNotification> notifs = [];

      for (final c in data) {
        final String cid     = c['complaint_id'] ?? c['id'].toString();
        final String issue   = c['issue_name'] ?? 'Your complaint';
        final String status  = (c['status'] ?? 'open').toString();
        final DateTime created = DateTime.tryParse(c['created_at'].toString()) ?? DateTime.now();

        if (status == 'closed' && (c['rating'] == null || c['rating'] == 0)) {
          notifs.add(_AppNotification(
            id: 'review_$cid',
            type: _NType.reviewRequired,
            complaintId: cid,
            issueName: issue,
            message: 'Your complaint has been resolved. Please rate and review the work done.',
            createdAt: created,
          ));
        }

        if (status == 'progress') {
          notifs.add(_AppNotification(
            id: 'status_progress_$cid',
            type: _NType.statusUpdate,
            complaintId: cid,
            issueName: issue,
            message: 'Your complaint is now In Progress. The team is working on it.',
            statusValue: 'progress',
            createdAt: created,
          ));
        } else if (status == 'closed') {
          notifs.add(_AppNotification(
            id: 'status_closed_$cid',
            type: _NType.statusUpdate,
            complaintId: cid,
            issueName: issue,
            message: 'Your complaint has been marked as Closed/Resolved.',
            statusValue: 'closed',
            createdAt: created,
          ));
        }

        if (c['assigned_worker_id'] != null) {
          notifs.add(_AppNotification(
            id: 'worker_$cid',
            type: _NType.workerAssigned,
            complaintId: cid,
            issueName: issue,
            message: 'A worker has been assigned to your complaint.',
            createdAt: created,
          ));
        }
      }

      notifs.sort((a, b) {
        if (a.type == _NType.reviewRequired && b.type != _NType.reviewRequired) return -1;
        if (b.type == _NType.reviewRequired && a.type != _NType.reviewRequired) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      final visible = notifs.where((n) => !NotifBadgeService.isDismissed(n.id)).toList();
      await NotifBadgeService.setCount(visible.length);
      setState(() { _notifications = visible; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load notifications')),
        );
      }
    }
  }

  Future<void> _dismiss(String id) async {
    await NotifBadgeService.dismiss(id);
    if (mounted) setState(() => _notifications.removeWhere((n) => n.id == id));
  }

  Future<void> _clearAll() async {
    await NotifBadgeService.dismissAll(_notifications.map((n) => n.id).toList());
    if (mounted) setState(() => _notifications = []);
  }

  void _handleTap(_AppNotification n) {
    _dismiss(n.id);
    if (n.type == _NType.reviewRequired) {
      Navigator.pushNamedAndRemoveUntil(
        context, '/complaints', (_) => false,
        arguments: {'initialTab': 1},
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context, '/complaints', (_) => false,
      );
    }
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  IconData _icon(_NType t) {
    switch (t) {
      case _NType.reviewRequired: return Icons.star_rate_rounded;
      case _NType.workerAssigned: return Icons.engineering_rounded;
      case _NType.statusUpdate:   return Icons.update_rounded;
    }
  }

  Color _iconBg(_NType t, String? status) {
    switch (t) {
      case _NType.reviewRequired: return Colors.amber;
      case _NType.workerAssigned: return const Color(0xFF4A90E2);
      case _NType.statusUpdate:
        if (status == 'closed')    return Colors.green;
        if (status == 'progress')  return Colors.orange;
        return Colors.blueGrey;
    }
  }

  String _label(_NType t, String? status) {
    switch (t) {
      case _NType.reviewRequired: return 'Review Required';
      case _NType.workerAssigned: return 'Worker Assigned';
      case _NType.statusUpdate:
        if (status == 'closed')   return 'Resolved';
        if (status == 'progress') return 'In Progress';
        return 'Status Update';
    }
  }

  Color _labelColor(_NType t, String? status) {
    switch (t) {
      case _NType.reviewRequired: return Colors.amber.shade700;
      case _NType.workerAssigned: return const Color(0xFF4A90E2);
      case _NType.statusUpdate:
        if (status == 'closed')   return Colors.green;
        if (status == 'progress') return Colors.orange;
        return Colors.blueGrey;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 22),
            decoration: const BoxDecoration(color: Color(0xFF4A90E2)),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const Expanded(child: SizedBox()),
                  const Text(
                    "Notifications",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: !_loading && _notifications.isNotEmpty
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _clearAll,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Clear all",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ),

          // Body
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          itemCount: _notifications.length,
                          itemBuilder: (_, i) => _notifCard(_notifications[i]),
                        ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomNav(context),
    );
  }

  Widget _notifCard(_AppNotification n) {
    final color = _iconBg(n.type, n.statusValue);
    final labelColor = _labelColor(n.type, n.statusValue);
    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
      ),
      onDismissed: (_) => _dismiss(n.id),
      child: GestureDetector(
        onTap: () => _handleTap(n),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon(n.type), color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: labelColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _label(n.type, n.statusValue),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: labelColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          n.complaintId,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _dismiss(n.id),
                          child: const Icon(Icons.close_rounded, color: Colors.black26, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      n.issueName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    if (n.type == _NType.reviewRequired) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade300, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_outline_rounded, size: 15, color: Colors.amber.shade700),
                            const SizedBox(width: 5),
                            Text(
                              'Tap to rate →',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      children: const [
        SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none_rounded, size: 72, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "No notifications yet",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                "Updates on your complaints will appear here.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black38),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomNav(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.grey),
            onPressed: () => MyNavigator.goHome(context),
          ),
          IconButton(
            icon: const Icon(Icons.assignment_outlined, color: Colors.grey),
            onPressed: () => MyNavigator.goComplaints(context),
          ),
          const Icon(
            Icons.notifications_none,
            color: Color(0xFF4A90E2),
          ),
        ],
      ),
    );
  }
}