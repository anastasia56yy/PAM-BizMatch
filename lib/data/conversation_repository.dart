import 'conversation.dart';
import 'result.dart';

/// Контракт переписок: /conversations на L5.
abstract class ConversationRepository {
  Future<Result<List<Conversation>>> fetchAll();
  Future<Result<Conversation>> fetchById(int id);
  Future<Result<Conversation>> create(Conversation conversation);
  Future<Result<Conversation>> update(Conversation conversation);
  Future<Result<void>> delete(int id);
}
