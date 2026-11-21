import 'package:flutter_test/flutter_test.dart';
import 'package:qarib/data/chat_repository.dart';
import 'package:qarib/data/demo_places_repository.dart';
import 'package:qarib/models/category.dart';
import 'package:qarib/models/chat.dart';
import 'package:qarib/models/place.dart';

const _place = Place(
  id: 'p1',
  name: 'صيدلية',
  category: PlaceCategory.pharmacy,
  area: 'منطقة',
  address: 'عنوان',
  phone: '01000000000',
  whatsapp: '',
  lat: 30,
  lng: 31,
  status: PlaceStatus.approved,
  ownerId: 'owner',
);

void main() {
  test('chat between user and owner shows in both inboxes', () async {
    final repo = DemoChatRepository();
    final id = await repo.openChat(place: _place, userId: 'u1', userName: 'منى');
    expect(id, Chat.idFor('p1', 'u1'));

    // فتحها تاني بيرجع نفس المحادثة.
    expect(await repo.openChat(place: _place, userId: 'u1', userName: 'منى'), id);

    await repo.send(id, 'u1', 'متاح عندكم بنادول؟');
    await repo.send(id, 'owner', 'أيوه متاح');

    final userInbox = await repo.watchMyChats('u1').first;
    final ownerInbox = await repo.watchMyChats('owner').first;
    expect(userInbox.single.id, id);
    expect(ownerInbox.single.id, id);
    expect(ownerInbox.single.titleFor('owner'), 'منى');
    expect(userInbox.single.titleFor('u1'), 'صيدلية');
    expect(userInbox.single.lastMessage, 'أيوه متاح');
    expect(userInbox.single.awaitingReplyFrom('u1'), isTrue);
    expect(userInbox.single.awaitingReplyFrom('owner'), isFalse);

    final messages = await repo.watchMessages(id).first;
    expect(messages.map((m) => m.senderId), ['u1', 'owner']);
    expect(await repo.watchMyChats('someone-else').first, isEmpty);
  });

  test('owner can switch WhatsApp off and on', () async {
    final places = DemoPlacesRepository(seed: [_place]);
    await places.updateWhatsapp('p1', '01011111111');
    var mine = await places.watchMine('owner').first;
    expect(mine.single.hasWhatsapp, isTrue);

    await places.updateWhatsapp('p1', '');
    mine = await places.watchMine('owner').first;
    expect(mine.single.hasWhatsapp, isFalse);
  });
}
