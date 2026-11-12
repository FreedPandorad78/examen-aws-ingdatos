# Respuestas

## 1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?

Porque la tabla usa partition projection: el catálogo no guarda particiones, solo
reglas (fechas `yyyy-MM-dd`, rango `2026-10-01,2026-10-03`, intervalo de 1 día) y
una plantilla de ubicación. Athena calcula las fechas y rutas al consultar. El día 3
ya estaba dentro del rango, pero sin archivo. Al subir `fecha=2026-10-03/entregas.csv`,
la ruta que Athena ya calculaba pasó a tener datos. Evidencia: sin crawler, `MSCK`,
`ALTER TABLE` ni `terraform apply`, la verificación devolvió los 6 registros del día 3
y `total_tabla = 18`.

## 2. Si se subiera un archivo para el 4 de octubre, ¿qué se esperaría y qué se debería modificar?

El archivo quedaría en S3, pero las consultas no lo devolverían: el rango termina el
2026-10-03, así que Athena no genera esa fecha. Se esperaría cero filas del día 4,
los totales iguales (18) y ningún error. Para incluirlo hay que cambiar en Terraform
`projection.fecha.range` a `2026-10-01,2026-10-04` y aplicar. No haría falta registrar
la partición. Esto sale de la documentación de Athena, no lo probé con un archivo del día 4.
