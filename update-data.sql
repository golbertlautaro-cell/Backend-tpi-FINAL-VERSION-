-- Actualizar solicitudes con datos más completos
UPDATE solicitudes SET 
  costo_estimado = 150.50 + (nro_solicitud * 10),
  costo_final = 165.75 + (nro_solicitud * 11),
  fecha_actualizacion = fecha_creacion + interval '1 day',
  id_contenedor = nro_solicitud + 1000,
  tiempo_real = (30 + (nro_solicitud * 5))::double precision
WHERE nro_solicitud >= 1;

-- Insertar 20 tramos (1 tramo por solicitud)
INSERT INTO tramos (nro_solicitud, origen, destino, tipo, estado, costo_aproximado, costo_real, 
                    fecha_hora_inicio_estimada, fecha_hora_inicio_real, 
                    fecha_hora_fin_estimada, fecha_hora_fin_real, tiempo_real, odometro_final, dominio_camion)
SELECT 
  s.nro_solicitud,
  'Buenos Aires Centro',
  'La Plata',
  CASE WHEN (s.nro_solicitud % 3 = 0) THEN 'ENTREGA' ELSE 'RECOGIDA' END,
  CASE WHEN (s.nro_solicitud % 2 = 0) THEN 'FINALIZADO' ELSE 'ASIGNADO' END,
  100.00 + (s.nro_solicitud * 5),
  110.00 + (s.nro_solicitud * 5.5),
  s.fecha_creacion,
  s.fecha_creacion + interval '30 minutes',
  s.fecha_creacion + interval '90 minutes',
  s.fecha_creacion + interval '85 minutes',
  85.0,
  85000.0 + (s.nro_solicitud * 1000),
  'DOM-' || LPAD((s.nro_solicitud % 20 + 1)::text, 3, '0')
FROM solicitudes s
WHERE s.nro_solicitud <= 20;
