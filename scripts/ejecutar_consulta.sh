#!/usr/bin/env bash
# Uso: bash scripts/ejecutar_consulta.sh <etapa> <archivo_sql> <archivo_resultado>
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "$#" -ne 3 ]; then
  echo "Uso: bash scripts/ejecutar_consulta.sh <etapa> <archivo_sql> <archivo_resultado>" >&2
  exit 1
fi

ETAPA="$1"
SQL="$2"
SALIDA="$3"
REGION="${REGION:-us-east-2}"
WORKGROUP="${WORKGROUP:-wg_mensajeria}"
BASE_DATOS="${BASE_DATOS:-mensajeria}"
BUCKET="${BUCKET:-dor-0302-de-mensajeria}"
REGISTRO="evidencias/ejecuciones_athena.csv"

ID=$(aws athena start-query-execution \
  --region "$REGION" \
  --work-group "$WORKGROUP" \
  --query-execution-context "Database=$BASE_DATOS" \
  --query-string="$(cat "$SQL")" \
  --query QueryExecutionId --output text)
echo "Ejecución: $ID"

while true; do
  ESTADO=$(aws athena get-query-execution --region "$REGION" \
    --query-execution-id "$ID" --query QueryExecution.Status.State --output text)
  [ "$ESTADO" = "SUCCEEDED" ] && break
  if [ "$ESTADO" = "FAILED" ] || [ "$ESTADO" = "CANCELLED" ]; then
    echo "La consulta terminó en $ESTADO" >&2
    aws athena get-query-execution --region "$REGION" --query-execution-id "$ID" \
      --query QueryExecution.Status.StateChangeReason --output text >&2
    exit 1
  fi
  sleep 2
done

mkdir -p "$(dirname "$SALIDA")"
# Athena entrecomilla los valores; se quitan las comillas (los datos no tienen comas)
aws s3 cp "s3://$BUCKET/resultados-athena/$ID.csv" - --region "$REGION" | tr -d '"' > "$SALIDA"

[ -f "$REGISTRO" ] || echo "etapa,archivo_sql,id_ejecucion,archivo_resultado" > "$REGISTRO"
echo "$ETAPA,$SQL,$ID,$SALIDA" >> "$REGISTRO"
echo "Resultado guardado en $SALIDA"
