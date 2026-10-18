import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/data/models/usuario_model.dart';
import 'package:vigia_app/features/auth/domain/entities/usuario.dart';

void main() {
  group('UsuarioModel Serialization & Mapping', () {
    test('Correctly maps JSON from schema.sql columns to UsuarioModel and Usuario Entity', () {
      final json = {
        'id_usuario': '9d26be1f-8511-4314-8ab2-960dd82d13f0',
        'correo_electronico': 'juanm@fgmail.com',
        'nombre_completo': 'Juan David Quintero',
        'id_rango': 1,
        'ciudad_referencia': 'Cali',
        'ultima_ciudad': 'Cali',
        'puntos_experiencia': 150,
        'activo': true,
      };

      final model = UsuarioModel.fromJson(json);

      expect(model.id, '9d26be1f-8511-4314-8ab2-960dd82d13f0');
      expect(model.email, 'juanm@fgmail.com');
      expect(model.nombreCompleto, 'Juan David Quintero');
      expect(model.nivelReputacionId, 1);
      expect(model.nivelReputacionNombre, 'Observador');
      expect(model.ciudadNombre, 'Cali');
      expect(model.puntosReputacion, 150);
      expect(model.activo, true);

      final entity = model.toEntity();
      expect(entity, isA<Usuario>());
      expect(entity.id, model.id);
      expect(entity.email, model.email);
    });

    test('Correctly handles nested joins from rango_civico and ciudad_cobertura', () {
      final json = {
        'id_usuario': 'uuid-1234',
        'correo_electronico': 'ciudadano@vigia.co',
        'nombre_completo': 'María Camila Gómez',
        'ciudad_residencia_id': 1,
        'id_rango': 2,
        'puntos_experiencia': 500,
        'activo': true,
        'rango_civico': {
          'id': 2,
          'nombre': 'Inspector Comunitario',
        },
        'ciudad_cobertura': {
          'id': 1,
          'nombre': 'Cali',
          'departamento': 'Valle del Cauca',
        },
      };

      final model = UsuarioModel.fromJson(json);

      expect(model.nivelReputacionNombre, 'Inspector Comunitario');
      expect(model.ciudadNombre, 'Cali (Valle del Cauca)');
      expect(model.puntosReputacion, 500);
    });

    test('toJson generates expected map for storage', () {
      const model = UsuarioModel(
        id: 'user-abc',
        email: 'test@vigia.co',
        nombreCompleto: 'Test User',
        ciudadResidenciaId: 1,
        ciudadNombre: 'Cali',
        nivelReputacionId: 1,
        puntosReputacion: 0,
        activo: true,
      );

      final json = model.toJson();

      expect(json['id'], 'user-abc');
      expect(json['email'], 'test@vigia.co');
      expect(json['nombre_completo'], 'Test User');
      expect(json['activo'], true);
    });
  });
}
