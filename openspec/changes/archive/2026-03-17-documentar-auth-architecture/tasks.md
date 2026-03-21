## 1. Documentación del flujo JWT Auth

- [x] 1.1 Crear documento de arquitectura de autenticación JWT en `backend/docs/auth/jwt-auth-flow.md` con diagrama del flujo de login (request → validación → token generation → response)
- [x] 1.2 Documentar el flujo de validación de tokens en rutas protegidas (header extraction → JWT decode → user lookup → active check)
- [x] 1.3 Documentar la configuración de tokens (SECRET_KEY, ACCESS_TOKEN_EXPIRE_MINUTES, algoritmo HS256) con referencia a `core/config.py` y `core/security.py`
- [x] 1.4 Documentar el flujo de password recovery (generación de token con 48h expiry, envío de email, reset endpoint)

## 2. Documentación de seguridad de contraseñas

- [x] 2.1 Crear documento `backend/docs/auth/password-security.md` describiendo el sistema dual Argon2/Bcrypt y la configuración de `pwdlib.PasswordHash`
- [x] 2.2 Documentar el mecanismo de migración automática de hashes (Bcrypt → Argon2 en login exitoso)
- [x] 2.3 Documentar la prevención de timing attacks con DUMMY_HASH y el patrón de verificación constante
- [x] 2.4 Documentar las reglas de validación de contraseñas (8-128 caracteres) y la validación de SECRET_KEY en diferentes entornos

## 3. Documentación del modelo de autorización

- [x] 3.1 Crear documento `backend/docs/auth/authorization-model.md` describiendo los niveles de acceso: público, usuario autenticado activo, superusuario
- [x] 3.2 Documentar las dependencias de inyección (`CurrentUser`, `get_current_active_superuser`, `SessionDep`) y cómo se usan en routes
- [x] 3.3 Documentar el patrón de ownership verification en items (owner_id check, superuser bypass)
- [x] 3.4 Documentar los endpoints de self-management (`/me`) y el registro público con `USERS_OPEN_REGISTRATION`

## 4. Mapa de referencia y diagramas

- [x] 4.1 Crear tabla de referencia de archivos involucrados en auth con su responsabilidad (security.py, config.py, deps.py, login.py, service.py, schemas.py)
- [x] 4.2 Crear diagrama de flujo ASCII del ciclo completo: login → token → request protegido → autorización → response
- [x] 4.3 Crear mapa de endpoints con su nivel de protección (público, autenticado, superuser-only) en formato tabla
