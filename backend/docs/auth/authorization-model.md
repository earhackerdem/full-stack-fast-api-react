# Authorization Model

## Niveles de Acceso

El sistema implementa 3 niveles de acceso, aplicados mediante dependencias FastAPI:

```
┌─────────────────────────────────────────────────┐
│ Público (sin autenticación)                      │
│                                                  │
│  POST /login/access-token                        │
│  POST /password-recovery/{email}                 │
│  POST /reset-password/                           │
│  POST /users/signup (si USERS_OPEN_REGISTRATION) │
├─────────────────────────────────────────────────┤
│ Autenticado (CurrentUser — is_active=True)       │
│                                                  │
│  GET/PATCH/DELETE /users/me                      │
│  PATCH /users/me/password                        │
│  GET /users/{user_id}                            │
│  POST /login/test-token                          │
│  GET/POST/PUT/DELETE /items/*                    │
├─────────────────────────────────────────────────┤
│ Superusuario (get_current_active_superuser)      │
│                                                  │
│  GET /users/                                     │
│  POST /users/                                    │
│  PATCH /users/{user_id}                          │
│  DELETE /users/{user_id}                         │
│  POST /password-recovery-html-content/{email}    │
└─────────────────────────────────────────────────┘
```

## Dependencias de Inyección

### `CurrentUser`

```python
# app/api/deps.py:50
CurrentUser = Annotated[User, Depends(get_current_user)]
```

Uso en routes: declararla como parámetro inyecta el usuario autenticado.

```python
@router.get("/me", response_model=UserPublic)
def read_user_me(current_user: CurrentUser) -> Any:
    return current_user
```

### `get_current_active_superuser`

```python
# app/api/deps.py:53-58
def get_current_active_superuser(current_user: CurrentUser) -> User:
    if not current_user.is_superuser:
        raise HTTPException(
            status_code=403, detail="The user doesn't have enough privileges"
        )
    return current_user
```

Uso en routes: se aplica como dependency en el decorador.

```python
@router.get("/", dependencies=[Depends(get_current_active_superuser)])
def read_users(session: SessionDep, skip: int = 0, limit: int = 100) -> Any:
    ...
```

### `SessionDep`

```python
# app/api/deps.py:27
SessionDep = Annotated[Session, Depends(get_db)]
```

Provee una sesión de SQLModel. No implica autenticación — la protección viene de `CurrentUser` o `get_current_active_superuser`.

## Ownership Verification en Items

Los items pertenecen a un usuario via `owner_id`. El control de acceso se implementa a nivel de route handler (no como dependencia):

```python
# Patrón usado en GET, PUT, DELETE de items
# app/api/routes/items.py:63-64
if not current_user.is_superuser and (item.owner_id != current_user.id):
    raise HTTPException(status_code=403, detail="Not enough permissions")
```

**Reglas:**

| Operación | Usuario regular | Superusuario |
|-----------|----------------|--------------|
| `GET /items/` | Solo sus items (`owner_id == user.id`) | Todos los items |
| `GET /items/{id}` | Solo si es owner | Cualquier item |
| `POST /items/` | Crea con `owner_id = user.id` | Crea con `owner_id = user.id` |
| `PUT /items/{id}` | Solo si es owner | Cualquier item |
| `DELETE /items/{id}` | Solo si es owner | Cualquier item |

**Filtrado en listado (`GET /items/`):**

```python
# app/api/routes/items.py:29-50
if current_user.is_superuser:
    statement = select(Item)...  # Todos los items
else:
    statement = select(Item).where(Item.owner_id == current_user.id)...
```

## Endpoints de Self-Management (`/me`)

Los usuarios autenticados pueden gestionar su propio perfil:

| Endpoint | Método | Descripción | Restricciones |
|----------|--------|-------------|---------------|
| `/users/me` | GET | Obtener perfil propio | — |
| `/users/me` | PATCH | Actualizar `full_name` y/o `email` | Email debe ser único (409 si duplicado) |
| `/users/me/password` | PATCH | Cambiar contraseña | Requiere `current_password` correcto. Nuevo password debe ser diferente al actual |
| `/users/me` | DELETE | Eliminar cuenta propia | Superusuarios NO pueden eliminarse (403) |

**Restricción de auto-eliminación de superusuarios:**

```python
# app/api/routes/users.py:138-141
if current_user.is_superuser:
    raise HTTPException(
        status_code=403, detail="Super users are not allowed to delete themselves"
    )
```

## Registro Público

El endpoint `POST /users/signup` permite auto-registro sin autenticación:

- **No** verifica `USERS_OPEN_REGISTRATION` actualmente en el código (el endpoint está siempre disponible)
- Usa schema `UserRegister` (email, password, full_name) — no permite setear `is_superuser` ni `is_active`
- Valida que el email no esté registrado (400 si ya existe)
- Nuevos usuarios se crean con `is_active=True` y `is_superuser=False` por defecto

**Referencia:** `app/api/routes/users.py:147-160`

## Mapa de Archivos de Auth

| Archivo | Responsabilidad |
|---------|----------------|
| `app/core/security.py` | Creación de JWT, hashing de contraseñas (Argon2 + Bcrypt) |
| `app/core/config.py` | SECRET_KEY, ACCESS_TOKEN_EXPIRE_MINUTES, validación de secretos |
| `app/api/deps.py` | OAuth2 bearer, decodificación de tokens, inyección de CurrentUser |
| `app/api/routes/login.py` | Endpoints de login, test-token, password recovery/reset |
| `app/api/routes/users.py` | CRUD de usuarios con checks de auth y ownership |
| `app/api/routes/items.py` | CRUD de items con ownership verification |
| `app/modules/users/service.py` | authenticate(), create_user(), update_user(), DUMMY_HASH |
| `app/modules/users/models.py` | User model, schemas (UserCreate, UserUpdate, etc.) |
| `app/modules/auth/schemas.py` | Token, TokenPayload, NewPassword schemas |
| `app/utils.py` | Password reset token generation/verification, email sending |

## Mapa de Endpoints por Nivel de Protección

| Endpoint | Método | Protección | Notas |
|----------|--------|------------|-------|
| `/login/access-token` | POST | Público | OAuth2 password flow |
| `/login/test-token` | POST | Autenticado | Verifica token válido |
| `/password-recovery/{email}` | POST | Público | Anti-enumeración |
| `/reset-password/` | POST | Público | Requiere token de reset |
| `/password-recovery-html-content/{email}` | POST | Superuser | Debug/preview de email |
| `/users/signup` | POST | Público | Auto-registro |
| `/users/me` | GET | Autenticado | Perfil propio |
| `/users/me` | PATCH | Autenticado | Actualizar perfil |
| `/users/me` | DELETE | Autenticado | No superusers |
| `/users/me/password` | PATCH | Autenticado | Requiere password actual |
| `/users/{user_id}` | GET | Autenticado | Solo self o superuser |
| `/users/` | GET | Superuser | Listar todos |
| `/users/` | POST | Superuser | Crear usuario |
| `/users/{user_id}` | PATCH | Superuser | Actualizar usuario |
| `/users/{user_id}` | DELETE | Superuser | Eliminar usuario |
| `/items/` | GET | Autenticado | Filtrado por ownership |
| `/items/{id}` | GET | Autenticado | Owner o superuser |
| `/items/` | POST | Autenticado | owner_id = current_user |
| `/items/{id}` | PUT | Autenticado | Owner o superuser |
| `/items/{id}` | DELETE | Autenticado | Owner o superuser |

## Diagrama de Flujo Completo

```
┌──────────┐     POST /login/access-token      ┌──────────────┐
│  Cliente  │──────────────────────────────────▶│ Login Route   │
│           │  {username: email, password: pwd}  │ (login.py)   │
└──────────┘                                    └──────┬───────┘
                                                       │
                                                       ▼
                                               ┌──────────────┐
                                               │ authenticate()│
                                               │ (service.py)  │
                                               └──────┬───────┘
                                                      │
                                                      ▼
                                               ┌──────────────┐
                                               │ JWT Token     │
                                               │ {exp, sub}    │
                                               └──────┬───────┘
                                                      │
         ◀────────────────────────────────────────────┘
         │  {"access_token": "eyJ...", "token_type": "bearer"}
         │
         │  GET /api/v1/items/
         │  Authorization: Bearer eyJ...
         │
         ▼
┌──────────────┐     TokenDep          ┌──────────────────┐
│ OAuth2Bearer  │─────────────────────▶│ get_current_user()│
│ (deps.py)    │  extraer token        │ (deps.py)        │
└──────────────┘                       └──────┬───────────┘
                                              │
                                    jwt.decode + DB lookup
                                              │
                                              ▼
                                       ┌──────────────┐
                                       │ CurrentUser   │
                                       │ (User object) │
                                       └──────┬───────┘
                                              │
                              ┌───────────────┼───────────────┐
                              │               │               │
                              ▼               ▼               ▼
                      ┌──────────────┐ ┌──────────┐  ┌──────────────┐
                      │ Superuser?   │ │ Owner?   │  │ Route handler│
                      │ (admin only) │ │ (items)  │  │ (self ops)   │
                      └──────────────┘ └──────────┘  └──────────────┘
```
