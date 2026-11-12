# Partition projection en Athena con Glue, S3 y Terraform

Consulta de CSV de entregas en S3 desde Athena, con tabla externa en Glue y
partition projection por fecha. Una fecha nueva se incorpora subiendo el archivo,
sin crawlers ni particiones manuales. El enunciado está en `ENUNCIADO.md`.

## Contenido de la entrega

Este repositorio reúne los dos puntos del examen:

| Punto | Dónde está | Qué contiene |
| --- | --- | --- |
| AWS: Athena, Glue y Terraform con partition projection | Raíz del repo | `infraestructura/`, `consultas/`, `resultados/`, `evidencias/`, `scripts/` y `respuestas.md` |
| Local: dbt y Airflow con source freshness | Carpeta `punto-local/` | `ventas_diarias.sql`, `sources.yml`, `examen_ventas.py`, `capturas_ejecuciones.pdf`, `resumen_antes.txt`, `resumen_despues.txt`, `evidencia_build_no_corrio.txt`, `respuestas.md` y `LEEME.txt` |

- Cada punto tiene su propio `respuestas.md`: el de la raíz es del punto de AWS y `punto-local/respuestas.md` es del punto local.
- `punto-local/LEEME.txt` indica el identificador de cada ejecución de Airflow.
- Las instrucciones de este README (prerrequisitos, despliegue, consultas y limpieza) corresponden al punto de AWS.


## Prerrequisitos

- Terraform >= 1.5 (probado con 1.16.4), AWS CLI v2, git y bash.
- Credenciales de AWS configuradas en la CLI (usuario `user_cli`). No se guardan en el repo.
- Región: `us-east-2`.
- Permisos del usuario sobre S3, Glue y Athena. Además, para etiquetas:
  `glue:GetTags`, `glue:TagResource`, `glue:UntagResource`,
  `athena:ListTagsForResource`, `athena:TagResource` y `athena:UntagResource`.

## Configuración

```bash
cp infraestructura/terraform.tfvars.example infraestructura/terraform.tfvars
# editar terraform.tfvars y poner un nombre de bucket único en AWS
```

`terraform.tfvars` está ignorado por git.

## Despliegue

```bash
cd infraestructura
terraform init
terraform plan -out=plan.tfplan
terraform apply plan.tfplan | tee ../evidencias/aplicacion_terraform.txt
terraform output -json > ../evidencias/outputs.json
cd ..
```

Crea el bucket privado, la base de datos `mensajeria`, la tabla `entregas` con
partition projection (formato `yyyy-MM-dd`, rango `2026-10-01,2026-10-03`, 1 día)
y el workgroup `wg_mensajeria` con resultados en `resultados-athena/`.

## Etapa inicial: días 1 y 2

Se sube cada archivo por separado (sin `sync` ni `--recursive`):

```bash
aws s3 cp "data/entregas/fecha=2026-10-01/entregas.csv" "s3://<bucket>/entregas/fecha=2026-10-01/entregas.csv" --region us-east-2
aws s3 cp "data/entregas/fecha=2026-10-02/entregas.csv" "s3://<bucket>/entregas/fecha=2026-10-02/entregas.csv" --region us-east-2
```

Consultas (cada una se ejecuta en el workgroup, guarda su resultado y se registra
en `evidencias/ejecuciones_athena.csv`):

```bash
bash scripts/ejecutar_consulta.sh inicial consultas/intentos_por_fecha_estado.sql resultados/inicial/intentos_por_fecha_estado.csv
bash scripts/ejecutar_consulta.sh inicial consultas/porcentaje_exito_por_fecha_ciudad.sql resultados/inicial/porcentaje_exito_por_fecha_ciudad.csv
bash scripts/ejecutar_consulta.sh inicial consultas/duracion_promedio_2026-10-02.sql resultados/inicial/duracion_promedio_2026-10-02.csv
```

Los resultados se compararon con `diff` contra `resultados_esperados/*_inicial.csv`
y con `duracion_promedio_2026-10-02.csv`: idénticos.

## Etapa final: día 3

Sin cambiar la infraestructura ni la tabla, y sin crawler, `MSCK REPAIR TABLE`
ni `ALTER TABLE ADD PARTITION`:

```bash
aws s3 cp "data/entregas/fecha=2026-10-03/entregas.csv" "s3://<bucket>/entregas/fecha=2026-10-03/entregas.csv" --region us-east-2
bash scripts/ejecutar_consulta.sh final consultas/verificacion_tercer_dia.sql resultados/final/verificacion_tercer_dia.csv
bash scripts/ejecutar_consulta.sh final consultas/intentos_por_fecha_estado.sql resultados/final/intentos_por_fecha_estado.csv
bash scripts/ejecutar_consulta.sh final consultas/porcentaje_exito_por_fecha_ciudad.sql resultados/final/porcentaje_exito_por_fecha_ciudad.csv
```

La verificación devuelve los 6 registros del 2026-10-03 y `total_tabla = 18`.
Los resultados finales coinciden con `resultados_esperados/*_final.csv`.

## Script de consultas

`scripts/ejecutar_consulta.sh` lanza la consulta en Athena, espera, descarga el
resultado desde `resultados-athena/`, le quita las comillas que Athena agrega
(los datos no tienen comas) y añade una fila a `evidencias/ejecuciones_athena.csv`
con `etapa`, `archivo_sql`, `id_ejecucion` y `archivo_resultado`.

## Limpieza

Primero se guardan las evidencias. Luego:

```bash
cd infraestructura
terraform destroy -auto-approve -no-color 2>&1 | tee ../evidencias/eliminacion_terraform.txt
```

El bucket tiene `force_destroy`, así que se elimina con sus datos y resultados.

## Notas

- El primer `terraform apply` falló a mitad por permisos de etiquetas
  (`evidencias/aplicacion_terraform_intento1.txt`). Se agregaron los permisos y
  un nuevo plan recreó la base de datos y el workgroup, que habían quedado
  marcados como dañados.
- Se usa `LazySimpleSerDe` con `skip.header.line.count = 1`. `OpenCSVSerDe` se
  descartó porque no respeta los tipos de columna.
- Respuestas conceptuales en `respuestas.md`.
