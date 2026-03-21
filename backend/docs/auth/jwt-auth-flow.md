# JWT Authentication Flow

## Overview

El sistema usa JSON Web Tokens (JWT) con OAuth2 Password Bearer para autenticación. Los tokens se firman con HS256 y contienen el UUID del usuario como subject.

## Flujo de Login

```
POST /api/v1/login/access-token
        │
        ▼
┌─────────────────────────┐
│ OAuth2PasswordRequestForm│
│ (username=email,        │
│  password=password)     │
└────────┬────────────────┘
         ▼
┌─────────────────────────┐
│ user_service.authenticate│
│ (modules/users/service) │
│                         │
│ 1. get_user_by_email()  │
│ 2. verify_password()    │
│ 3. Auto-upgrade hash    │
└────────┬────────────────┘
         ▼
    ┌────┴────┐
    │ Valid?  │
    └────┬────┘
    No   │   Yes
    │    │    │
    ▼    │    ▼
  400    │  ┌─────────────────────┐
         │  │ Check is_active     │
         │  └────────┬────────────┘
         │      No   │   Yes
         │      │    │    │
         │      ▼    │    ▼
         │    400    │  ┌─────────────────────────┐
         │           │  │ create_access_token()   │
         │           │  │ (core/security.py)      │
         │           │  │                         │
         │           │  │ payload:                │
         │           │  │   exp = now + 8 days    │
         │           │  │   sub = user.id (UUID)  │
         │           │  │                         │
         │           │  │ jwt.encode(             │
         │           │  │   payload,              │
         │           │  │   SECRET_KEY,           │
         │           │  │   algorithm="HS256"     │
         │           │  │ )                       │
         │           │  └────────┬────────────────┘
         │           │           ▼
         │           │  ┌─────────────────────────┐
         │           │  │ Response:               │
         │           │  │ {                       │
         │           │  │   "access_token": "...",│
         │           │  │   "token_type": "bearer"│
         │           │  │ }                       │
         │           │  └─────────────────────────┘
```

**Archivos involucrados:**
- `app/api/routes/login.py:25-44` — endpoint `login_access_token`
- `app/modules/users/service.py:44-59` — función `authenticate`
- `app/core/security.py:22-26` — función `create_access_token`

## Validación de Tokens en Rutas Protegidas

```
GET /api/v1/items/ + Authorization: Bearer <jwt>
        │
        ▼
┌─────────────────────────────┐
│ OAuth2PasswordBearer        │
│ (api/deps.py:17-19)        │
│                             │
│ Extrae token del header     │
│ Authorization: Bearer ...   │
└────────┬────────────────────┘
         ▼
┌─────────────────────────────┐
│ get_current_user()          │
│ (api/deps.py:31-47)        │
│                             │
│ 1. jwt.decode(token,       │
│      SECRET_KEY, ["HS256"])│
│ 2. Validar TokenPayload    │
│      (extraer sub=UUID)    │
│ 3. session.get(User, UUID) │
│ 4. Check user exists       │
│ 5. Check user.is_active    │
└────────┬────────────────────┘
         ▼
    ┌────┴────────┐
    │ Resultado   │
    └────┬────────┘
         │
    ┌────┼──────────────┐
    │    │              │
    ▼    ▼              ▼
  403   400            200
 Token  Inactive       User inyectado
 inválido user        como CurrentUser
```

**Dependencias de inyección:**

| Dependencia | Tipo | Descripción |
|-------------|------|-------------|
| `TokenDep` | `Annotated[str, Depends(reusable_oauth2)]` | Extrae el token JWT del header |
| `CurrentUser` | `Annotated[User, Depends(get_current_user)]` | Usuario autenticado y activo |
| `SessionDep` | `Annotated[Session, Depends(get_db)]` | Sesión de base de datos |

**Códigos de error:**

| Código | Detalle | Causa |
|--------|---------|-------|
| 401 | Not Authenticated | No se envió header Authorization |
| 403 | Could not validate credentials | Token expirado, inválido o malformado |
| 404 | User not found | UUID del token no existe en DB |
| 400 | Inactive user | Usuario existe pero `is_active=False` |

## Configuración de Tokens

Definida en `app/core/config.py`:

| Variable | Default | Descripción |
|----------|---------|-------------|
| `SECRET_KEY` | `secrets.token_urlsafe(32)` | Clave de firma JWT. Auto-generada si no se define en `.env` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `11520` (8 días) | Tiempo de vida del access token |
| `ALGORITHM` | `"HS256"` | Algoritmo de firma (definido en `core/security.py:19`) |

**Validación en producción:** Si `SECRET_KEY` es `"changethis"` en entorno `staging` o `production`, el sistema lanza `ValueError` y no arranca. En `local` solo emite warning.

## Flujo de Password Recovery

```
1. POST /api/v1/password-recovery/{email}
        │
        ▼
┌─────────────────────────────────┐
│ get_user_by_email(email)        │
│                                 │
│ Si existe:                      │
│   generate_password_reset_token │
│   (utils.py:107-117)           │
│                                 │
│   payload:                      │
│     exp = now + 48h             │
│     nbf = now                   │
│     sub = email                 │
│                                 │
│   Enviar email con link:        │
│   {FRONTEND_HOST}/reset-password│
│   ?token={jwt}                  │
│                                 │
│ Siempre retorna:                │
│ "If that email is registered,   │
│  we sent a recovery link"       │
│ (previene enumeración de emails)│
└─────────────────────────────────┘

2. POST /api/v1/reset-password/
        │
        ▼
┌─────────────────────────────────┐
│ verify_password_reset_token()   │
│ (utils.py:120-127)             │
│                                 │
│ jwt.decode(token, SECRET_KEY)   │
│ → extraer sub (email)           │
│                                 │
│ Validar:                        │
│   - Token válido y no expirado  │
│   - Usuario existe y está activo│
│                                 │
│ Actualizar hashed_password      │
│ via user_service.update_user()  │
└─────────────────────────────────┘
```

**Configuración:**

| Variable | Valor | Archivo |
|----------|-------|---------|
| `EMAIL_RESET_TOKEN_EXPIRE_HOURS` | `48` | `core/config.py:86` |
| Token subject | Email del usuario (no UUID) | `utils.py:113` |
| Token claims extra | `nbf` (not before) | `utils.py:113` |

**Diferencia con access tokens:** Los tokens de reset usan el email como `sub` (no UUID) y expiran en 48 horas (no 8 días). Incluyen claim `nbf` que los access tokens no tienen.

## Test Token Endpoint

`POST /api/v1/login/test-token` es un endpoint protegido que simplemente retorna el `UserPublic` del usuario autenticado. Se usa para verificar que un token existente sigue siendo válido.

```python
# app/api/routes/login.py:47-52
@router.post("/login/test-token", response_model=UserPublic)
def test_token(current_user: CurrentUser) -> Any:
    return current_user
```
