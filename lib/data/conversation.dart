/// Переписка с контактом. Имя и компания хранятся в самой записи:
/// контакт виден, даже если его профиль скрыт из подбора.
class Conversation {
  final int id;
  final int profileId;
  final String name;
  final String company;
  final String lastMessage;
  final String time;
  final int unread;
  final List<Message> messages;

  const Conversation(this.id, this.profileId, this.name, this.company,
      this.lastMessage, this.time, this.unread, this.messages);

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        j['id'] as int,
        j['profile_id'] as int,
        j['name'] as String,
        j['company'] as String? ?? '',
        j['last_message'] as String? ?? '',
        j['time'] as String? ?? '',
        j['unread'] as int? ?? 0,
        [
          for (final m in j['messages'] as List? ?? const [])
            Message.fromJson(m as Map<String, dynamic>)
        ],
      );

  Map<String, dynamic> toJson() => {
        'profile_id': profileId,
        'name': name,
        'company': company,
        'last_message': lastMessage,
        'time': time,
        'unread': unread,
        'messages': [for (final m in messages) m.toJson()],
      };

  Conversation copyWith(
          {int? id,
          String? lastMessage,
          String? time,
          int? unread,
          List<Message>? messages}) =>
      Conversation(
        id ?? this.id,
        profileId,
        name,
        company,
        lastMessage ?? this.lastMessage,
        time ?? this.time,
        unread ?? this.unread,
        messages ?? this.messages,
      );
}

class Message {
  final bool fromMe;
  final String text;
  final String time;

  const Message(this.fromMe, this.text, this.time);

  factory Message.fromJson(Map<String, dynamic> j) =>
      Message(j['from_me'] as bool, j['text'] as String, j['time'] as String);

  Map<String, dynamic> toJson() => {'from_me': fromMe, 'text': text, 'time': time};
}
