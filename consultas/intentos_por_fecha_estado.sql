-- SCRIPT-003
SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM mensajeria.entregas
GROUP BY fecha, estado
ORDER BY fecha ASC, estado ASC
