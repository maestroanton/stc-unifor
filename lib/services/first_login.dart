import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirstLoginService {
  static final FirstLoginService _instance = FirstLoginService._internal();
  factory FirstLoginService() => _instance;
  FirstLoginService._internal();

  final CollectionReference _firstLoginCollection = FirebaseFirestore.instance
      .collection('user_first_login');

  /// Verifica se o usuário precisa alterar a senha no primeiro acesso
  Future<bool> isFirstLogin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user?.email == null) {
        return false;
      }

      // Verifica se primeiro login foi concluído
      final doc = await _firstLoginCollection.doc(user!.email).get();
      final isFirst = !doc.exists;

      return isFirst;
    } catch (e) {
      return false;
    }
  }

  /// Marca primeiro login como concluído
  Future<void> markFirstLoginComplete(String email) async {
    try {

      await _firstLoginCollection.doc(email).set({
        'completedAt': FieldValue.serverTimestamp(),
        'email': email,
        'version': 1, // Versão para compatibilidade futura
      });

    } catch (e) {
      rethrow;
    }
  }

  /// Admin: reinicia status de primeiro login
  Future<void> resetFirstLoginStatus(String email) async {
    try {
      await _firstLoginCollection.doc(email).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Verifica se um usuário específico completou o primeiro login
  Future<bool> hasUserCompletedFirstLogin(String email) async {
    try {
      final doc = await _firstLoginCollection.doc(email).get();
      final completed = doc.exists;
      return completed;
    } catch (e) {
      return false;
    }
  }

  /// Força usuário a passar pelo primeiro login novamente
  Future<void> forceFirstLogin(String email) async {
    await resetFirstLoginStatus(email);
  }
}
