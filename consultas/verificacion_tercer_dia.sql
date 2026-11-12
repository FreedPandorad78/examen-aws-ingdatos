-- SCRIPT-006
SELECT
    e.fecha,
    e.id_envio,
    e.ciudad,
    e.transportadora,
    e.estado,
    e.duracion_minutos,
    t.total_tabla
FROM mensajeria.entregas AS e
CROSS JOIN (
    SELECT COUNT(*) AS total_tabla
    FROM mensajeria.entregas
) AS t
WHERE e.fecha = '2026-10-03'
ORDER BY e.id_envio ASC
