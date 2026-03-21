## Context

El proyecto es un template full-stack FastAPI que incluye un sistema de autenticación completo basado en JWT con OAuth2 Password Bearer. La autenticación está distribuida en múltiples módulos:

- **Core**: `security.py` (JWT + hashing), `config.py` (secretos y expiración)
- **API**: `deps.py` (dependencias de inyección), `routes/login.py` (endpoints públicos)
- **Módulos**: `users/service.py` (lógica de negocio), `auth/schemas.py` (schemas de tokens)

No existe documentación formal que conecte estos componentes. Los desarrolladores deben rastrear el flujo manualmente a través de imports y dependencias FastAPI.

## Goals / Non-Goals

**Goals:**
- Crear documentación técnica que describa el flujo completo de autenticación desde el login hasta la autorización en rutas protegidas
- Documentar las decisiones de seguridad implementadas (Argon2, timing attack prevention, hash migration)
- Proveer diagramas de flujo que faciliten el onboarding de nuevos desarrolladores
- Documentar el modelo de autorización (usuario activo vs superusuario vs ownership)

**Non-Goals:**
- No se modificará código existente
- No se implementarán nuevos mecanismos de auth (OAuth2 social, MFA, refresh tokens)
- No se documentará el frontend ni su manejo de tokens
- No se auditará la seguridad del sistema — solo se documenta el estado actual

## Decisions

### D1: Estructura de documentación como specs por capability

**Decisión**: Dividir la documentación en 3 specs alineadas con las capabilities del proposal: `jwt-auth-flow`, `password-security`, `authorization-model`.

**Rationale**: Cada capability cubre un aspecto ortogonal del sistema de auth. Esta separación permite que un desarrollador consulte solo la parte relevante sin leer todo el documento.

**Alternativa considerada**: Un único documento monolítico — descartado porque mezcla concerns y dificulta la navegación.

### D2: Formato de documentación como specs formales con escenarios

**Decisión**: Usar el formato de specs con requirements y scenarios WHEN/THEN para documentar comportamientos.

**Rationale**: Los escenarios WHEN/THEN sirven como documentación ejecutable — cada uno mapea directamente a un test case existente o potencial. Esto es más útil que prosa descriptiva.

**Alternativa considerada**: Documentación narrativa en markdown libre — descartada porque no es verificable contra el código.

### D3: Documentación en español alineada con el equipo

**Decisión**: Escribir la documentación en español, manteniendo términos técnicos en inglés donde sean estándar (JWT, OAuth2, hashing, bearer token).

**Rationale**: El equipo trabaja en español. Los términos técnicos se mantienen en inglés porque son la nomenclatura estándar de la industria.

## Risks / Trade-offs

- **[Desactualización]** → La documentación puede quedar desincronizada con el código. **Mitigación**: Los escenarios WHEN/THEN permiten verificar manualmente contra el comportamiento real. Incluir referencias a archivos y líneas específicas.

- **[Cobertura parcial]** → La documentación solo cubre el backend; el flujo completo incluye frontend. **Mitigación**: Declarado explícitamente como non-goal. Se puede extender en un cambio futuro.

- **[Complejidad del hashing dual]** → El sistema Argon2+Bcrypt tiene sutilezas (auto-upgrade, dummy hash) que son difíciles de documentar sin oversimplificar. **Mitigación**: Incluir escenarios específicos para cada caso edge.
