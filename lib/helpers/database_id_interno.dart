import 'package:cloud_firestore/cloud_firestore.dart';

Future<int> getNextInventarioInternalId() async {
  final counterRef = FirebaseFirestore.instance
      .collection('internal_counters')
      .doc('inventario_internal_id');

  return FirebaseFirestore.instance.runTransaction<int>((transaction) async {
    final snapshot = await transaction.get(counterRef);
    int current = 0;
    if (snapshot.exists && snapshot.data() != null && snapshot.data()!.containsKey('current')) {
      final value = snapshot['current'];
      if (value is int) {
        current = value;
      } else if (value is double) {
        current = value.toInt();
      } else if (value is String) {
        current = int.tryParse(value) ?? 0;
      }
    }
    final next = current + 1;
    transaction.set(counterRef, {'current': next});
    return next;
  });
}
