import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// Remote data source for civic authentication interacting with Supabase SDK.
class AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSource({required this.supabaseClient});

  /// Signs in with email and password
  Future<UserModel> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await supabaseClient.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Could not authenticate user with server.');
    }

    return await _fetchUserProfile(user.id, user.email ?? email);
  }

  /// Registers a new citizen account.
  /// Metadata is intercepted by the PostgreSQL trigger `handle_new_user`.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required int cityId,
    String? cityName,
  }) async {
    final response = await supabaseClient.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'nombre_completo': fullName.trim(),
        'city_id': cityId,
        'city_name': cityName ?? 'Cali',
        'ciudad_nombre': cityName ?? 'Cali',
      },
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Error registering user in Supabase.');
    }

    try {
      // Attempt to retrieve profile populated by trigger
      return await _fetchUserProfile(user.id, user.email ?? email);
    } catch (_) {
      // Fallback if trigger replication is still pending
      return UserModel(
        id: user.id,
        email: user.email ?? email,
        fullName: fullName,
        residenceCityId: cityId,
        cityName: cityName ?? 'Cali',
        rankId: 1,
        rankName: 'Urban Observer',
        reputationPoints: 0,
        isActive: true,
      );
    }
  }

  /// Signs out the active session in Supabase
  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }

  /// Retrieves the active authenticated citizen profile
  Future<UserModel?> getCurrentUser() async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) return null;

    try {
      return await _fetchUserProfile(user.id, user.email ?? '');
    } catch (_) {
      return null;
    }
  }

  /// Queries user profile from PostgreSQL table `user_profile` (with fallback to legacy)
  Future<UserModel> _fetchUserProfile(String userId, String fallbackEmail) async {
    // 1. English schema: JOIN user_profile with civic_rank by id_user
    try {
      final data = await supabaseClient
          .from('user_profile')
          .select('*, civic_rank(*)')
          .eq('id_user', userId)
          .maybeSingle();

      if (data != null) {
        return UserModel.fromJson(data);
      }
    } catch (_) {}

    // 2. English schema: Direct query on user_profile by id_user
    try {
      final flatData = await supabaseClient
          .from('user_profile')
          .select()
          .eq('id_user', userId)
          .maybeSingle();

      if (flatData != null) {
        return UserModel.fromJson(flatData);
      }
    } catch (_) {}

    // 3. English schema: Query by email
    try {
      final byEmail = await supabaseClient
          .from('user_profile')
          .select()
          .eq('email', fallbackEmail)
          .maybeSingle();

      if (byEmail != null) {
        return UserModel.fromJson(byEmail);
      }
    } catch (_) {}

    // 4. Legacy fallback: query usuario table
    try {
      final legacyData = await supabaseClient
          .from('usuario')
          .select('*, rango_civico(*)')
          .eq('id_usuario', userId)
          .maybeSingle();

      if (legacyData != null) {
        return UserModel.fromJson(legacyData);
      }
    } catch (_) {}

    // 5. Self-healing fallback: If auth session exists in Supabase but user_profile record is missing
    try {
      final user = supabaseClient.auth.currentUser;
      final fullName = user?.userMetadata?['full_name'] ??
          user?.userMetadata?['nombre_completo'] ??
          'Citizen VIGÍA';
      final cityName = user?.userMetadata?['city_name'] ??
          user?.userMetadata?['ciudad_nombre'] ??
          'Cali';

      await supabaseClient.from('user_profile').upsert({
        'id_user': userId,
        'email': fallbackEmail,
        'full_name': fullName,
        'id_rank': 1,
        'reference_city': cityName,
        'last_city': cityName,
        'experience_points': 0,
        'is_active': true,
      });

      final recovered = await supabaseClient
          .from('user_profile')
          .select('*, civic_rank(*)')
          .eq('id_user', userId)
          .maybeSingle();

      if (recovered != null) {
        return UserModel.fromJson(recovered);
      }
    } catch (_) {}

    throw Exception('Civic profile not found in database.');
  }
}
