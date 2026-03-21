## 1. Spec de item-crud

- 1.1 Crear directorio `openspec/specs/item-crud/` y copiar spec final desde el cambio
- 1.2 Verificar que cada scenario del spec corresponde a un test existente en `tests/api/routes/test_items.py`
- 1.3 Agregar tests faltantes para scenarios no cubiertos (validación de título vacío, título largo, paginación personalizada, listado vacío, cascada de eliminación)

## 2. Delta de authorization-model

- 2.1 Verificar que los scenarios de control de acceso a items en el delta corresponden a tests existentes
- 2.2 Agregar tests faltantes para scenarios de autorización no cubiertos

## 3. Archivado

- 3.1 Ejecutar `openspec archive` para fusionar specs delta con los specs base existentes
- 3.2 Verificar que `openspec/specs/item-crud/spec.md` y `openspec/specs/authorization-model/spec.md` reflejan los cambios correctamente

