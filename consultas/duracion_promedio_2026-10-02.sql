-- SCRIPT-005
SELECT
    fecha,
    CAST(AVG(duracion_minutos) AS DECIMAL(10, 2)) AS duracion_promedio_minutos
FROM mensajeria.entregas
WHERE fecha = '2026-10-02'
  AND estado = 'entregado'
GROUP BY fecha
