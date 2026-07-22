-- =====================================================================
-- Consultas SQL - Sistema de emisión de licencias de conducir
-- 775 - Sistemas de Bases de Datos 2 - Tarea de Fortalecimiento Académico
-- =====================================================================
USE licencias_guatemala;

-- 1. Listado general de licencias con datos del titular y tipo de licencia
SELECT
    l.id_licencia,
    CONCAT(p.primer_nombre, ' ', IFNULL(p.segundo_nombre,''), ' ', p.primer_apellido, ' ', IFNULL(p.segundo_apellido,'')) AS titular,
    tl.codigo AS tipo_licencia,
    l.fecha_emision,
    l.fecha_vencimiento,
    l.estado
FROM licencia l
JOIN persona p        ON p.id_persona = l.id_persona
JOIN tipo_licencia tl ON tl.id_tipo_licencia = l.id_tipo_licencia
ORDER BY l.fecha_vencimiento;

-- 2. Licencias vencidas o próximas a vencer (dentro de los siguientes 30 días)
SELECT
    l.id_licencia,
    CONCAT(p.primer_nombre, ' ', p.primer_apellido) AS titular,
    tl.codigo AS tipo_licencia,
    l.fecha_vencimiento,
    DATEDIFF(l.fecha_vencimiento, CURDATE()) AS dias_para_vencer
FROM licencia l
JOIN persona p        ON p.id_persona = l.id_persona
JOIN tipo_licencia tl ON tl.id_tipo_licencia = l.id_tipo_licencia
WHERE l.fecha_vencimiento <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)
ORDER BY l.fecha_vencimiento;

-- 3. Historial de exámenes realizados por una licencia específica
SELECT
    er.id_examen,
    te.nombre AS tipo_examen,
    er.fecha_examen,
    er.resultado,
    er.calificacion
FROM examen_realizado er
JOIN tipo_examen te ON te.id_tipo_examen = er.id_tipo_examen
WHERE er.id_licencia = 1
ORDER BY er.fecha_examen;

-- 4. Verificar si un titular cumplió los 3 exámenes requeridos para su primera licencia
SELECT
    l.id_licencia,
    COUNT(DISTINCT er.id_tipo_examen) AS examenes_aprobados
FROM licencia l
JOIN examen_realizado er ON er.id_licencia = l.id_licencia AND er.resultado = 'APROBADO'
GROUP BY l.id_licencia
HAVING COUNT(DISTINCT er.id_tipo_examen) = 3;

-- 5. Licencias de titulares menores de edad con su autorización de padre/tutor
SELECT
    l.id_licencia,
    CONCAT(p.primer_nombre, ' ', p.primer_apellido) AS titular,
    TIMESTAMPDIFF(YEAR, p.fecha_nacimiento, l.fecha_emision) AS edad_al_emitir,
    am.nombre_padre_tutor,
    am.parentesco,
    am.fecha_autorizacion
FROM licencia l
JOIN persona p ON p.id_persona = l.id_persona
JOIN autorizacion_menor am ON am.id_licencia = l.id_licencia
WHERE TIMESTAMPDIFF(YEAR, p.fecha_nacimiento, l.fecha_emision) < 18;

-- 6. Historial de renovaciones y pagos por licencia
SELECT
    r.id_renovacion,
    l.id_licencia,
    r.anios_renovados,
    r.fecha_renovacion,
    r.fecha_vencimiento_anterior,
    r.fecha_vencimiento_nueva,
    pg.monto,
    pg.metodo_pago
FROM renovacion r
JOIN licencia l ON l.id_licencia = r.id_licencia
JOIN pago pg    ON pg.id_renovacion = r.id_renovacion
ORDER BY r.fecha_renovacion;

-- 7. Total recaudado por pagos de renovación, agrupado por año
SELECT
    YEAR(fecha_pago) AS anio,
    COUNT(*) AS cantidad_pagos,
    SUM(monto) AS total_recaudado
FROM pago
GROUP BY YEAR(fecha_pago)
ORDER BY anio;

-- 8. Cantidad de licencias vigentes por tipo
SELECT
    tl.codigo,
    tl.descripcion,
    COUNT(l.id_licencia) AS total_licencias_vigentes
FROM tipo_licencia tl
LEFT JOIN licencia l ON l.id_tipo_licencia = tl.id_tipo_licencia AND l.estado = 'VIGENTE'
GROUP BY tl.id_tipo_licencia, tl.codigo, tl.descripcion
ORDER BY total_licencias_vigentes DESC;

-- 9. Validar que el vencimiento de una renovación coincide con el cumpleaños del titular
SELECT
    r.id_renovacion,
    l.id_licencia,
    p.fecha_nacimiento,
    r.fecha_vencimiento_nueva,
    MONTH(p.fecha_nacimiento) = MONTH(r.fecha_vencimiento_nueva)
        AND DAY(p.fecha_nacimiento) = DAY(r.fecha_vencimiento_nueva) AS coincide_con_cumpleanos
FROM renovacion r
JOIN licencia l ON l.id_licencia = r.id_licencia
JOIN persona p  ON p.id_persona = l.id_persona;

-- 10. Personas con más de una licencia activa (ej. licencia A y B simultáneas)
SELECT
    p.id_persona,
    CONCAT(p.primer_nombre, ' ', p.primer_apellido) AS titular,
    COUNT(l.id_licencia) AS total_licencias
FROM persona p
JOIN licencia l ON l.id_persona = p.id_persona
WHERE l.estado = 'VIGENTE'
GROUP BY p.id_persona
HAVING COUNT(l.id_licencia) > 1;
