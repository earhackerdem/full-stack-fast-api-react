## Why

El proyecto carece de documentación formal sobre su arquitectura de autenticación. Los desarrolladores nuevos deben leer múltiples archivos para entender el flujo completo de auth (JWT, OAuth2, hashing, recuperación de contraseña). Documentar esta arquitectura reduce el tiempo de onboarding y establece una referencia clara para futuras modificaciones.

## What Changes

- Crear documentación técnica del sistema de autenticación JWT/OAuth2 existente
- Documentar el flujo de login, validación de tokens y protección de rutas
- Documentar el sistema de hashing de contraseñas (Argon2 + Bcrypt fallback)
- Documentar el flujo de recuperación de contraseña
- Documentar el modelo de autorización (roles: usuario activo, superusuario)
- Mapear las dependencias de seguridad y su inyección en rutas

## Capabilities

### New Capabilities
- `jwt-auth-flow`: Documentación del flujo completo de autenticación JWT con OAuth2 Password Bearer, incluyendo generación, validación y expiración de tokens
- `password-security`: Documentación del sistema de hashing dual (Argon2/Bcrypt), migración automática de hashes y prevención de timing attacks
- `authorization-model`: Documentación del modelo de autorización basado en roles (usuario activo, superusuario) y verificación de ownership en recursos

### Modified Capabilities

_No hay capabilities existentes que modificar._

## Impact

- **Código afectado**: Ninguno — este cambio es puramente documental
- **Archivos referenciados**:
  - `backend/app/core/security.py` — JWT y hashing
  - `backend/app/core/config.py` — configuración de secretos y expiración
  - `backend/app/api/deps.py` — dependencias OAuth2 y validación de tokens
  - `backend/app/api/routes/login.py` — endpoints de autenticación
  - `backend/app/modules/users/service.py` — servicio de autenticación de usuarios
  - `backend/app/modules/auth/schemas.py` — schemas de tokens
- **APIs**: Documenta endpoints existentes bajo `/api/v1/login/` y protección de `/api/v1/users/`, `/api/v1/items/`
- **Dependencias**: Referencia a `pyjwt`, `pwdlib[argon2,bcrypt]`
