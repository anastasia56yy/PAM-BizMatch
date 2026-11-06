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
}
