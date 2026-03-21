# Password Security

## Sistema Dual de Hashing: Argon2 + Bcrypt

El sistema usa `pwdlib.PasswordHash` con dos hashers configurados en orden de prioridad:

```python
# app/core/security.py:11-16
password_hash = PasswordHash(
    (
        Argon2Hasher(),   # Primario — todas las contraseñas nuevas
        BcryptHasher(),   # Fallback — soporte legacy
    )
)
```

**Argon2** (primario):
- Algoritmo: Argon2id v19
- Parámetros por defecto: `m=65536` (64MB memoria), `t=3` (iteraciones), `p=4` (paralelismo)
- Resistente a ataques GPU/ASIC por su uso intensivo de memoria

**Bcrypt** (fallback):
- Soportado para compatibilidad con contraseñas hasheadas antes de migrar a Argon2
- No se usa para nuevos hashes

### Funciones de Hashing

```python
# app/core/security.py:29-36
def verify_password(plain_password: str, hashed_password: str) -> tuple[bool, str | None]:
    return password_hash.verify_and_update(plain_password, hashed_password)
    # Retorna: (is_valid, new_hash_or_None)
    # new_hash es non-None cuando el hash actual usa un hasher deprecated (Bcrypt)

def get_password_hash(password: str) -> str:
    return password_hash.hash(password)
    # Siempre hashea con Argon2 (primer hasher)
```

## Migración Automática de Hashes

Cuando un usuario con hash Bcrypt se autentica exitosamente, el sistema automáticamente re-hashea con Argon2:

```
Login con password correcto
        │
        ▼
verify_password(password, bcrypt_hash)
        │
        ▼
┌───────────────────────────────┐
│ password_hash.verify_and_update│
│                               │
│ 1. Verifica contra Bcrypt ✓   │
│ 2. Detecta hasher deprecated  │
│ 3. Re-hashea con Argon2       │
│ 4. Retorna (True, new_hash)   │
└───────┬───────────────────────┘
        ▼
┌───────────────────────────────┐
│ authenticate() actualiza DB   │
│ (modules/users/service.py)    │
│                               │
│ if updated_password_hash:     │
│   db_user.hashed_password =   │
│     updated_password_hash     │
│   session.commit()            │
└───────────────────────────────┘
```

**Referencia:** `app/modules/users/service.py:51-58`

La migración es transparente — el usuario no nota ningún cambio. En login posteriores, la verificación usará Argon2 directamente.

## Prevención de Timing Attacks

El sistema previene timing attacks (donde un atacante mide el tiempo de respuesta para deducir si un email existe) usando un hash dummy:

```python
# app/modules/users/service.py:39-41
DUMMY_HASH = "$argon2id$v=19$m=65536,t=3,p=4$MjQyZWE1MzBjYjJlZTI0Yw$YTU4NGM5ZTZmYjE2NzZlZjY0ZWY3ZGRkY2U2OWFjNjk"
```

**Flujo en `authenticate()`:**

```
authenticate(email, password)
        │
        ▼
get_user_by_email(email)
        │
   ┌────┴────────┐
   │             │
   ▼             ▼
 None          User
   │             │
   ▼             ▼
verify_password  verify_password
(password,       (password,
 DUMMY_HASH)     user.hashed_password)
   │             │
   ▼             ▼
return None    return User o None
```

**Por qué funciona:** `verify_password` ejecuta la misma operación criptográfica (Argon2 verification) tanto si el usuario existe como si no. El tiempo de respuesta es similar en ambos casos, impidiendo que un atacante distinga entre "email no existe" y "password incorrecto".

**Referencia:** `app/modules/users/service.py:44-59`

## Reglas de Validación de Contraseñas

Las contraseñas se validan en los schemas de Pydantic/SQLModel:

| Schema | Campo | Mínimo | Máximo | Uso |
|--------|-------|--------|--------|-----|
| `UserCreate` | `password` | 8 chars | 128 chars | Creación por admin |
| `UserRegister` | `password` | 8 chars | 128 chars | Auto-registro público |
| `UserUpdate` | `password` | 8 chars | 128 chars | Actualización por admin |
| `UpdatePassword` | `current_password` | 8 chars | 128 chars | Cambio de contraseña propia |
| `UpdatePassword` | `new_password` | 8 chars | 128 chars | Cambio de contraseña propia |
| `NewPassword` | `new_password` | 8 chars | 128 chars | Reset de contraseña |

**Referencia:** `app/modules/users/models.py:20-43`, `app/modules/auth/schemas.py:15-17`

**Validación adicional:** Al cambiar contraseña via `/users/me/password`, el sistema verifica que el nuevo password sea diferente al actual (`app/api/routes/users.py:114-117`).

## Validación de SECRET_KEY por Entorno

El `SECRET_KEY` se usa para firmar todos los JWT (access tokens y reset tokens). La validación se ejecuta al iniciar la aplicación:

```python
# app/core/config.py:97-106
def _check_default_secret(self, var_name: str, value: str | None) -> None:
    if value == "changethis":
        message = f'The value of {var_name} is "changethis", ...'
        if self.ENVIRONMENT == "local":
            warnings.warn(message, stacklevel=1)
        else:
            raise ValueError(message)
```

| Entorno | SECRET_KEY = "changethis" | Resultado |
|---------|---------------------------|-----------|
| `local` | Warning en stdout | App inicia |
| `staging` | `ValueError` | App NO inicia |
| `production` | `ValueError` | App NO inicia |

La misma validación aplica a `POSTGRES_PASSWORD` y `FIRST_SUPERUSER_PASSWORD`.

**Referencia:** `app/core/config.py:108-116`
