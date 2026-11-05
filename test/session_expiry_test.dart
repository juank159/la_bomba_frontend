// Pruebas del cierre automático de sesión al vencer el token.

import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:pedidos_frontend/app/core/di/service_locator.dart';
import 'package:pedidos_frontend/app/core/errors/failures.dart';
import 'package:pedidos_frontend/app/core/services/preferences_service.dart';
import 'package:pedidos_frontend/app/core/services/session_events.dart';
import 'package:pedidos_frontend/app/core/storage/secure_storage.dart';
import 'package:pedidos_frontend/features/auth/domain/entities/user.dart';
import 'package:pedidos_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:pedidos_frontend/features/auth/domain/usecases/login_usecase.dart';
import 'package:pedidos_frontend/features/auth/domain/usecases/logout_usecase.dart';
import 'package:pedidos_frontend/features/auth/presentation/controllers/auth_controller.dart';

/// JWT de prueba con `exp` = ahora + [fromNow] (sin firma real: la app no la
/// verifica, eso lo hace el servidor).
String jwt(Duration fromNow) {
  String b64(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  final exp = DateTime.now().add(fromNow).millisecondsSinceEpoch ~/ 1000;
  return '${b64({'alg': 'HS256'})}.${b64({'sub': 'u1', 'exp': exp})}.firma';
}

class FakeStorage implements SecureStorage {
  final Map<String, String> data = {};
  @override
  Future<String?> getAccessToken() async => data['access_token'];
  @override
  Future<String?> getRefreshToken() async => data['refresh_token'];
  @override
  Future<bool> isAuthenticated() async => (data['access_token'] ?? '').isNotEmpty;
  @override
  Future<void> clearAuthData() async => data.clear();
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakeRepo implements AuthRepository {
  final FakeStorage storage;
  FakeRepo(this.storage);
  @override
  Future<Either<Failure, bool>> isAuthenticated() async => Right(await storage.isAuthenticated());
  @override
  Future<Either<Failure, User?>> getCurrentUser() async =>
      const Right(User(id: 'u1', username: 'verdulero', email: 'v@x.co', role: UserRole.verdulero));
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakePrefs implements PreferencesService {
  @override
  String? getLastEmail() => 'verdulero@local.test';
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeStorage storage;

  setUp(() async {
    Get.testMode = true;
    await getIt.reset();
    storage = FakeStorage();
    getIt.registerSingleton<SecureStorage>(storage);
    getIt.registerSingleton<PreferencesService>(FakePrefs());
  });

  Future<AuthController> boot() async {
    final repo = FakeRepo(storage);
    final c = AuthController(loginUseCase: LoginUseCase(repo), logoutUseCase: LogoutUseCase(repo), authRepository: repo);
    c.onInit();
    while (!c.isInitialized) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    return c;
  }

  group('lectura del vencimiento', () {
    test('jwtExpiry lee exp', () {
      final e = jwtExpiry(jwt(const Duration(hours: 2)))!;
      expect(e.difference(DateTime.now()).inMinutes, inInclusiveRange(118, 120));
    });
    test('token basura → null', () {
      expect(jwtExpiry('no-es-un-jwt'), isNull);
      expect(jwtExpiry(null), isNull);
    });
    test('la sesión dura lo que dure el más tardío (renovación)', () {
      final ends = sessionEndsAt(jwt(const Duration(minutes: -5)), jwt(const Duration(days: 20)))!;
      expect(ends.isAfter(DateTime.now().add(const Duration(days: 19))), isTrue);
    });
  });

  group('al abrir la app', () {
    test('sesión vigente → entra normal', () async {
      storage.data.addAll({'access_token': jwt(const Duration(days: 6)), 'refresh_token': jwt(const Duration(days: 29))});
      final c = await boot();
      expect(c.isAuthenticated, isTrue);
      expect(c.sessionNotice.value, isNull);
      c.onClose();
    });
    test('solo venció el acceso (renovación vigente) → entra (se renueva solo)', () async {
      storage.data.addAll({'access_token': jwt(const Duration(hours: -1)), 'refresh_token': jwt(const Duration(days: 10))});
      final c = await boot();
      expect(c.isAuthenticated, isTrue);
      c.onClose();
    });
    test('sesión totalmente vencida → al login con aviso y sin tokens', () async {
      storage.data.addAll({'access_token': jwt(const Duration(days: -20)), 'refresh_token': jwt(const Duration(hours: -1))});
      final c = await boot();
      expect(c.isAuthenticated, isFalse);
      expect(c.sessionNotice.value, contains('expiró'));
      expect(storage.data, isEmpty);
      c.onClose();
    });
    test('instalación vieja sin token de renovación y acceso vencido → al login', () async {
      storage.data.addAll({'access_token': jwt(const Duration(minutes: -1))});
      final c = await boot();
      expect(c.isAuthenticated, isFalse);
      expect(c.sessionNotice.value, isNotNull);
      c.onClose();
    });
    test('sin sesión guardada → login sin aviso', () async {
      final c = await boot();
      expect(c.isAuthenticated, isFalse);
      expect(c.sessionNotice.value, isNull);
      c.onClose();
    });
  });

  group('con la app abierta', () {
    test('vence mientras está abierta → se cierra sola con aviso', () async {
      storage.data.addAll({'access_token': jwt(const Duration(days: 1)), 'refresh_token': jwt(const Duration(days: 1))});
      final c = await boot();
      expect(c.isAuthenticated, isTrue);
      // pasa la medianoche…
      storage.data.addAll({'access_token': jwt(const Duration(hours: -1)), 'refresh_token': jwt(const Duration(seconds: -1))});
      await c.checkSessionStillValid();
      expect(c.isAuthenticated, isFalse);
      expect(c.sessionNotice.value, contains('expiró'));
      c.onClose();
    });
    test('el servidor rechaza la renovación → se cierra (aviso del cliente HTTP)', () async {
      storage.data.addAll({'access_token': jwt(const Duration(days: 1)), 'refresh_token': jwt(const Duration(days: 9))});
      final c = await boot();
      SessionEvents.notifyExpired();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.isAuthenticated, isFalse);
      expect(c.sessionNotice.value, isNotNull);
      c.onClose();
    });
    test('con sesión vigente el chequeo no la cierra', () async {
      storage.data.addAll({'access_token': jwt(const Duration(minutes: -2)), 'refresh_token': jwt(const Duration(days: 9))});
      final c = await boot();
      await c.checkSessionStillValid();
      expect(c.isAuthenticated, isTrue);
      c.onClose();
    });
  });
}
