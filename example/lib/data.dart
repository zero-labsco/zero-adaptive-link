/// Sample data for the example app.
/// 示例应用的样例数据。
///
/// The demo is a support inbox: the ticket list is the master pane and the
/// thread is the detail pane, which is the shape `zero_adaptive_link` is built
/// for (one URL per ticket, deep-linkable).
/// 演示是一个支持工单收件箱：工单列表是 master pane，会话线程是 detail pane
/// ——这正是 `zero_adaptive_link` 面向的形态（每个工单一个 URL、可深链）。
enum TicketPriority { low, normal, urgent }

/// Ticket lifecycle state. / 工单生命周期状态。
enum TicketStatus { open, pending, resolved }

/// One message in a ticket thread. / 工单线程中的一条消息。
class TicketMessage {
  const TicketMessage({
    required this.author,
    required this.fromAgent,
    required this.body,
    required this.time,
  });

  final String author;
  final bool fromAgent;
  final String body;
  final String time;
}

/// A support ticket. / 一条支持工单。
class Ticket {
  const Ticket({
    required this.id,
    required this.subject,
    required this.customer,
    required this.company,
    required this.snippet,
    required this.received,
    required this.priority,
    required this.status,
    required this.messages,
    this.hasAttachment = false,
  });

  final String id;
  final String subject;
  final String customer;
  final String company;
  final String snippet;
  final String received;
  final TicketPriority priority;
  final TicketStatus status;
  final List<TicketMessage> messages;
  final bool hasAttachment;

  /// Two-letter initials for the avatar. / 头像使用的双字母缩写。
  String get initials {
    final parts = customer.split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, 2).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

/// A customer record. / 一条客户记录。
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.company,
    required this.plan,
    required this.openTickets,
    required this.since,
  });

  final String id;
  final String name;
  final String company;
  final String plan;
  final int openTickets;
  final String since;

  /// Two-letter initials for the avatar. / 头像使用的双字母缩写。
  String get initials {
    final parts = name.split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, 2).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

const List<Ticket> kTickets = [
  Ticket(
    id: '4821',
    subject: 'Refund still missing after return',
    customer: 'Marta Ruiz',
    company: 'Northwind Supply',
    snippet: 'We posted the parcel back on the 3rd and nothing has landed yet.',
    received: '12 min ago',
    priority: TicketPriority.urgent,
    status: TicketStatus.open,
    hasAttachment: true,
    messages: [
      TicketMessage(
        author: 'Marta Ruiz',
        fromAgent: false,
        body:
            'We posted the parcel back on the 3rd and the tracking shows it '
            'arrived. The refund has not appeared on our statement yet — '
            'receipt is attached.',
        time: '09:14',
      ),
      TicketMessage(
        author: 'You',
        fromAgent: true,
        body:
            'Thanks Marta. Returns are settled within five working days of '
            'arrival, so this should clear on Thursday. I have asked finance '
            'to confirm the exact date.',
        time: '09:31',
      ),
    ],
  ),
  Ticket(
    id: '4820',
    subject: 'Sign-in loop on Safari 17',
    customer: 'Devin Park',
    company: 'Lumen Labs',
    snippet: 'After the redirect it bounces back to the login screen.',
    received: '1 h ago',
    priority: TicketPriority.normal,
    status: TicketStatus.pending,
    messages: [
      TicketMessage(
        author: 'Devin Park',
        fromAgent: false,
        body:
            'Signing in from Safari 17 bounces me back to the login screen '
            'every time. Chrome on the same machine is fine.',
        time: '08:02',
      ),
      TicketMessage(
        author: 'You',
        fromAgent: true,
        body:
            'That points at third-party cookie blocking. Could you try with '
            '“Prevent cross-site tracking” switched off and tell me whether '
            'it still loops?',
        time: '08:20',
      ),
    ],
  ),
  Ticket(
    id: '4819',
    subject: 'VAT number missing on invoices',
    customer: 'Ana Sørensen',
    company: 'Fjord Retail',
    snippet: 'Our finance team cannot process the last three invoices.',
    received: '4 h ago',
    priority: TicketPriority.normal,
    status: TicketStatus.open,
    hasAttachment: true,
    messages: [
      TicketMessage(
        author: 'Ana Sørensen',
        fromAgent: false,
        body:
            'The last three invoices arrived without our VAT number, so '
            'finance cannot book them. Our number is on file — I checked.',
        time: '07:45',
      ),
    ],
  ),
  Ticket(
    id: '4818',
    subject: 'Seat count does not update',
    customer: 'Tomás Ferreira',
    company: 'Harbor Coop',
    snippet: 'We removed two members but the plan still bills for seven.',
    received: 'Yesterday',
    priority: TicketPriority.low,
    status: TicketStatus.resolved,
    messages: [
      TicketMessage(
        author: 'Tomás Ferreira',
        fromAgent: false,
        body:
            'We removed two members last week but the plan still bills for '
            'seven seats.',
        time: 'Mon 16:10',
      ),
      TicketMessage(
        author: 'You',
        fromAgent: true,
        body:
            'Seat changes apply at the start of the next billing period, so '
            'the July invoice already reflected five. Closing this one — '
            'reopen it if August looks wrong.',
        time: 'Mon 17:02',
      ),
    ],
  ),
];

const List<Customer> kCustomers = [
  Customer(
    id: 'c1',
    name: 'Marta Ruiz',
    company: 'Northwind Supply',
    plan: 'Business',
    openTickets: 3,
    since: 'Mar 2022',
  ),
  Customer(
    id: 'c2',
    name: 'Devin Park',
    company: 'Lumen Labs',
    plan: 'Team',
    openTickets: 1,
    since: 'Aug 2023',
  ),
  Customer(
    id: 'c3',
    name: 'Ana Sørensen',
    company: 'Fjord Retail',
    plan: 'Business',
    openTickets: 0,
    since: 'Jan 2021',
  ),
  Customer(
    id: 'c4',
    name: 'Tomás Ferreira',
    company: 'Harbor Coop',
    plan: 'Starter',
    openTickets: 2,
    since: 'Nov 2024',
  ),
];
