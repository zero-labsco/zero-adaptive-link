import 'package:flutter/material.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

import 'data.dart';
import 'theme.dart';
import 'widgets.dart';

// ----------------------------------------------------------------- tokens --

Color _priorityColor(TicketPriority priority) => switch (priority) {
  TicketPriority.urgent => AppColors.clay,
  TicketPriority.normal => AppColors.slate,
  TicketPriority.low => AppColors.muted,
};

String _priorityLabel(TicketPriority priority) => switch (priority) {
  TicketPriority.urgent => 'Urgent',
  TicketPriority.normal => 'Normal',
  TicketPriority.low => 'Low',
};

Color _statusColor(TicketStatus status) => switch (status) {
  TicketStatus.open => AppColors.pine,
  TicketStatus.pending => AppColors.clay,
  TicketStatus.resolved => AppColors.muted,
};

String _statusLabel(TicketStatus status) => switch (status) {
  TicketStatus.open => 'Open',
  TicketStatus.pending => 'Pending',
  TicketStatus.resolved => 'Resolved',
};

// ------------------------------------------------------------------ inbox --

/// The ticket list (tab root, master pane). / 工单列表（tab 根页面、master pane）。
Widget buildInboxList(BuildContext context, ZeroRouteState state) {
  return Scaffold(
    key: const ValueKey('page-inbox'),
    backgroundColor: AppColors.paper,
    appBar: AppBar(
      title: const Text('Inbox'),
      bottom: const AppBarRule(),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text('${kTickets.length} threads', style: kCaptionStyle),
          ),
        ),
      ],
    ),
    body: ListView.separated(
      itemCount: kTickets.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final ticket = kTickets[index];
        return ZeroLink(
          location: '/inbox/${ticket.id}',
          child: _TicketRow(ticket: ticket),
        );
      },
    ),
  );
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialsAvatar(initials: ticket.initials),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.subject,
                        style: kSubjectStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (ticket.priority == TicketPriority.urgent) ...[
                      const SizedBox(width: 8),
                      const TagChip(
                        label: 'Urgent',
                        color: AppColors.clay,
                        background: AppColors.clayTint,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  ticket.snippet,
                  style: kSnippetStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                Text(
                  '${ticket.company} · ${ticket.received}',
                  style: kCaptionStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusDot(color: _statusColor(ticket.status)),
              const SizedBox(height: 5),
              Text(_statusLabel(ticket.status), style: kCaptionStyle),
            ],
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- thread --

/// The ticket thread (detail pane). / 工单线程（detail pane）。
Widget buildTicketDetail(
  BuildContext context,
  ZeroRouteState state,
  ValueChanged<String> onReply,
) {
  final id = state.pathParameters['id']!;
  final ticket = kTickets.firstWhere((t) => t.id == id);
  return _TicketThread(
    key: const ValueKey('page-ticket'),
    ticket: ticket,
    onReply: onReply,
  );
}

class _TicketThread extends StatefulWidget {
  const _TicketThread({required this.ticket, required this.onReply, super.key});

  final Ticket ticket;
  final ValueChanged<String> onReply;

  @override
  State<_TicketThread> createState() => _TicketThreadState();
}

class _TicketThreadState extends State<_TicketThread> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text('Ticket #${ticket.id}'),
        bottom: const AppBarRule(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _TicketHeader(ticket: ticket),
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 15, 16, 6),
                  child: SectionLabel('Thread'),
                ),
                for (final message in ticket.messages)
                  _MessageBubble(message: message),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const Divider(height: 1),
          _Composer(
            controller: _controller,
            onSend: () {
              final text = _controller.text.trim();
              if (text.isEmpty) {
                return;
              }
              widget.onReply(text);
              _controller.clear();
            },
          ),
        ],
      ),
    );
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ticket.subject, style: kTitleStyle.copyWith(fontSize: 19)),
          const SizedBox(height: 11),
          Row(
            children: [
              InitialsAvatar(initials: ticket.initials, size: 28),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.customer, style: kSubjectStyle),
                    Text(ticket.company, style: kCaptionStyle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TagChip(
                label: _statusLabel(ticket.status),
                color: _statusColor(ticket.status),
                background: AppColors.pineTint,
              ),
              TagChip(
                label: _priorityLabel(ticket.priority),
                color: _priorityColor(ticket.priority),
                background: AppColors.slateTint,
              ),
              TagChip(label: ticket.received),
            ],
          ),
          if (ticket.hasAttachment) ...[
            const SizedBox(height: 15),
            ZeroLink(
              location: '/inbox/${ticket.id}/attachment',
              child: const _AttachmentRow(),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, size: 17, color: AppColors.muted),
          const SizedBox(width: 9),
          const Expanded(
            child: Text('Return receipt.pdf', style: kSubjectStyle),
          ),
          Text('Preview', style: kCaptionStyle.copyWith(color: AppColors.pine)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final TicketMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.fromAgent ? AppColors.pineTint : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  message.author,
                  style: kSubjectStyle.copyWith(fontSize: 13),
                ),
                const Spacer(),
                Text(message.time, style: kCaptionStyle),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message.body,
              style: kSnippetStyle.copyWith(
                color: AppColors.inkSoft,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 13),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              style: kSubjectStyle,
              decoration: InputDecoration(
                hintText: 'Write a reply',
                hintStyle: kSnippetStyle,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                border: _composerBorder(AppColors.hairline),
                enabledBorder: _composerBorder(AppColors.hairline),
                focusedBorder: _composerBorder(AppColors.pine),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(onPressed: onSend, child: const Text('Send')),
        ],
      ),
    );
  }

  OutlineInputBorder _composerBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: color),
  );
}

// -------------------------------------------------------------- attachment --

/// The translucent fullscreen preview (covers the shell at any width).
/// 半透明 fullscreen 预览页（在任何宽度下覆盖 shell）。
Widget buildAttachmentPreview(BuildContext context, ZeroRouteState state) {
  final id = state.pathParameters['id']!;
  final ticket = kTickets.firstWhere((t) => t.id == id);
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Card(
        margin: const EdgeInsets.all(24),
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Return receipt · #$id', style: kTitleStyle),
              const SizedBox(height: 4),
              Text(ticket.company, style: kCaptionStyle),
              const SizedBox(height: 18),
              const _DocumentLines(),
              const SizedBox(height: 18),
              const Text(
                'Tap the barrier or press back to dismiss.',
                style: kCaptionStyle,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Static grey bars standing in for document text (no animation, so widget
/// tests can settle).
/// 代表文档正文的静态灰条（无动画，便于 widget 测试 settle）。
class _DocumentLines extends StatelessWidget {
  const _DocumentLines();

  static const List<double> _widths = [1, 0.92, 0.97, 0.64, 0.88, 0.51];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final width in _widths)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: FractionallySizedBox(
              widthFactor: width,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDim,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// -------------------------------------------------------------- customers --

/// The customers branch. / 客户 branch。
Widget buildCustomers(BuildContext context, ZeroRouteState state) {
  return Scaffold(
    key: const ValueKey('page-customers'),
    backgroundColor: AppColors.paper,
    appBar: AppBar(title: const Text('Customers'), bottom: const AppBarRule()),
    body: ListView.separated(
      itemCount: kCustomers.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final customer = kCustomers[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              InitialsAvatar(initials: customer.initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: kSubjectStyle),
                    const SizedBox(height: 3),
                    Text(
                      '${customer.company} · since ${customer.since}',
                      style: kCaptionStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TagChip(label: customer.plan),
                  const SizedBox(height: 5),
                  Text(
                    customer.openTickets == 0
                        ? 'No open tickets'
                        : '${customer.openTickets} open',
                    style: kCaptionStyle,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

// -------------------------------------------------------------------- you --

/// The You tab root. / You tab 根页面。
Widget buildYou(BuildContext context, ZeroRouteState state, bool loggedIn) {
  return Scaffold(
    key: const ValueKey('page-you'),
    backgroundColor: AppColors.paper,
    appBar: AppBar(title: const Text('You'), bottom: const AppBarRule()),
    body: ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Row(
            children: [
              const InitialsAvatar(initials: 'YO', size: 44),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your workspace', style: kTitleStyle),
                    const SizedBox(height: 3),
                    Text(
                      loggedIn ? 'Signed in' : 'Not signed in',
                      style: kCaptionStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 15, 16, 6),
          child: SectionLabel('Account'),
        ),
        const DetailRow(label: 'Workspace', value: 'Dispatch demo'),
        const DetailRow(label: 'Plan', value: 'Business'),
        const DetailRow(label: 'Member since', value: 'Mar 2022'),
        const Divider(height: 1),
        ZeroLink(
          location: '/you/billing',
          child: const _NavRow(
            title: 'Billing',
            subtitle: 'Invoices and payment method',
          ),
        ),
        const Divider(height: 1),
      ],
    ),
  );
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: kSubjectStyle),
                const SizedBox(height: 3),
                Text(subtitle, style: kCaptionStyle),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
        ],
      ),
    );
  }
}

/// The protected billing page (redirects to /login when signed out).
/// 受保护的账单页（未登录时重定向到 /login）。
Widget buildBilling(BuildContext context, ZeroRouteState state) {
  return Scaffold(
    key: const ValueKey('page-billing'),
    backgroundColor: AppColors.paper,
    appBar: AppBar(title: const Text('Billing'), bottom: const AppBarRule()),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DetailRow(label: 'Plan', value: 'Business · 12 seats'),
        const DetailRow(label: 'Cycle', value: 'Monthly, renews 1st'),
        const DetailRow(label: 'Method', value: 'Visa · 4242'),
        const Divider(height: 1),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'This route is protected. Signing out sends you back to the '
            'sign-in screen, and you return here afterwards.',
            style: kSnippetStyle,
          ),
        ),
      ],
    ),
  );
}

/// The sign-in page. / 登录页。
Widget buildLogin(
  BuildContext context,
  ZeroRouteState state,
  VoidCallback onLoggedIn,
) {
  final from = state.queryParameters['from'] ?? '/you';
  return Scaffold(
    key: const ValueKey('page-login'),
    backgroundColor: AppColors.paper,
    appBar: AppBar(title: const Text('Sign in'), bottom: const AppBarRule()),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BrandMark(size: 26),
              const SizedBox(height: 20),
              Text('Sign in to continue to $from', style: kSubjectStyle),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  onLoggedIn();
                  ZeroNav.of(context).open(from);
                },
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
