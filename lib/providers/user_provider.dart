import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_provider.dart';

final userDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) {
      return null;
    }
    return snapshot.data() as Map<String, dynamic>;
  });
});


final hasCompletedOnboardingProvider = Provider<bool>((ref) {
  final userData = ref.watch(userDataProvider);
  return userData.when(
    data: (data) => data?['hasCompletedOnboarding'] ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

final userCountryProvider = Provider<String?>((ref) {
  final userData = ref.watch(userDataProvider);
  return userData.when(
    data: (data) => data?['country'],
    loading: () => null,
    error: (_, __) => null,
  );
});

final userGoalProvider = Provider<String?>((ref) {
  final userData = ref.watch(userDataProvider);
  return userData.when(
    data: (data) => data?['goal'],
    loading: () => null,
    error: (_, __) => null,
  );
});

class UserNotifier extends StateNotifier<AsyncValue<void>> {
  UserNotifier() : super(const AsyncValue.data(null));

  Future<void> updateCountry(String country) async {
    state = const AsyncValue.loading();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'country': country});
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateGoal(String goal) async {
    state = const AsyncValue.loading();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'goal': goal,
          'hasCompletedOnboarding': true,
        });
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? photoURL,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final updateData = <String, dynamic>{};
        
        if (name != null) {
          updateData['name'] = name;
          await user.updateDisplayName(name);
        }
        
        if (photoURL != null) {
          updateData['photoURL'] = photoURL;
          await user.updatePhotoURL(photoURL);
        }
        
        if (updateData.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update(updateData);
        }
        
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final userNotifierProvider = StateNotifierProvider<UserNotifier, AsyncValue<void>>((ref) {
  return UserNotifier();
});
