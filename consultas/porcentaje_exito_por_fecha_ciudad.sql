-- SCRIPT-004
SELECT
    fecha,
    ciudad,
    CAST(
        100 * CAST(SUM(CASE WHEN estado = 'entregado' THEN 1 ELSE 0 END) AS DOUBLE) / COUNT(*)
        AS DECIMAL(5, 2)
    ) AS porcentaje_exito
FROM mensajeria.entregas
GROUP BY fecha, ciudad
ORDER BY fecha ASC, ciudad ASC
