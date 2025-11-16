package com.tpi.solicitudes.service;

import com.tpi.solicitudes.domain.EstadoTramo;
import com.tpi.solicitudes.domain.Solicitud;
import com.tpi.solicitudes.domain.Tramo;
import com.tpi.solicitudes.dto.DistanciaDTO;
import com.tpi.solicitudes.repository.SolicitudRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import com.tpi.solicitudes.repository.TramoRepository;
import com.tpi.solicitudes.client.LogisticaClient;
import com.tpi.solicitudes.client.GoogleMapsClient;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Autowired;

@Slf4j
@Service
public class TramoService {

    private final TramoRepository tramoRepository;
    private final SolicitudRepository solicitudRepository;
    private final Optional<LogisticaClient> logisticaClient;
    private final Optional<GoogleMapsClient> googleMapsClient;
    private final GoogleMapsService googleMapsService;

    public TramoService(TramoRepository tramoRepository,
                        SolicitudRepository solicitudRepository,
                        @Autowired(required = false) LogisticaClient logisticaClient,
                        @Autowired(required = false) GoogleMapsClient googleMapsClient,
                        GoogleMapsService googleMapsService) {
        this.tramoRepository = tramoRepository;
        this.solicitudRepository = solicitudRepository;
        this.logisticaClient = Optional.ofNullable(logisticaClient);
        this.googleMapsClient = Optional.ofNullable(googleMapsClient);
        this.googleMapsService = googleMapsService;
    }

    public Page<Tramo> findAll(Pageable pageable) {
        return tramoRepository.findAll(pageable);
    }

    public List<Tramo> listarPorSolicitud(Long solicitudId) { // legacy
        return tramoRepository.findBySolicitudNroSolicitud(solicitudId);
    }

    public Page<Tramo> listarPorSolicitud(Long solicitudId, Pageable pageable) {
        return tramoRepository.findBySolicitudNroSolicitud(solicitudId, pageable);
    }

    public Page<Tramo> listar(Pageable pageable, String estado, String dominioCamion,
                               LocalDateTime desde, LocalDateTime hasta) {
        boolean hasEstado = estado != null && !estado.isBlank();
        boolean hasDominio = dominioCamion != null && !dominioCamion.isBlank();

        // Normalizar rango si no viene alguno de los extremos
        LocalDateTime from = (desde != null) ? desde : LocalDateTime.of(1970, 1, 1, 0, 0);
        LocalDateTime to = (hasta != null) ? hasta : LocalDateTime.of(9999, 12, 31, 23, 59, 59);

        if (hasEstado && hasDominio) {
            return tramoRepository.findByEstadoAndDominioCamionAndFechaHoraInicioRealBetween(estado, dominioCamion, from, to, pageable);
        } else if (hasEstado) {
            return tramoRepository.findByEstadoAndFechaHoraInicioRealBetween(estado, from, to, pageable);
        } else if (hasDominio) {
            return tramoRepository.findByDominioCamionAndFechaHoraInicioRealBetween(dominioCamion, from, to, pageable);
        } else {
            return tramoRepository.findByFechaHoraInicioRealBetween(from, to, pageable);
        }
    }

    public Tramo obtener(Long id) {
        return tramoRepository.findById(id).orElseThrow(() -> new NoSuchElementException("Tramo no encontrado: " + id));
    }

    public Tramo crear(Long solicitudId, Tramo tramo) {
        Solicitud solicitud = solicitudRepository.findById(solicitudId)
                .orElseThrow(() -> new NoSuchElementException("Solicitud no encontrada: " + solicitudId));
        tramo.setIdTramo(null);
        tramo.setSolicitud(solicitud);
        return tramoRepository.save(tramo);
    }

    public Tramo actualizar(Long id, Tramo tramo) {
        Tramo actual = obtener(id);
        actual.setOrigen(tramo.getOrigen());
        actual.setDestino(tramo.getDestino());
        actual.setDominioCamion(tramo.getDominioCamion());
        actual.setEstado(tramo.getEstado());
        actual.setFechaHoraInicioReal(tramo.getFechaHoraInicioReal());
        actual.setFechaHoraFinReal(tramo.getFechaHoraFinReal());
        actual.setCostoReal(tramo.getCostoReal());
        return tramoRepository.save(actual);
    }

    public void eliminar(Long id) {
        if (!tramoRepository.existsById(id)) {
            throw new NoSuchElementException("Tramo no encontrado: " + id);
        }
        tramoRepository.deleteById(id);
    }

    public Mono<Tramo> asignarACamion(Long idTramo, String dominioCamion) {
        // NOTA: No tenemos peso/volumen del contenedor en el modelo actual.
        // Por ahora, se parametriza con 0.0. Ajustar cuando haya origen real de datos.
        Double pesoContenedor = 0.0;
        Double volumenContenedor = 0.0;

        return Mono.fromCallable(() -> obtener(idTramo))
                .subscribeOn(Schedulers.boundedElastic())
                .flatMap(tramo -> {
                    if (logisticaClient.isEmpty()) {
                        return Mono.just(true);
                    }
                    return logisticaClient.get().validarCapacidadCamion(dominioCamion, pesoContenedor, volumenContenedor)
                        .defaultIfEmpty(false);
                })
                .flatMap(valido -> {
                    if (!valido) {
                        return Mono.error(new IllegalStateException("Capacidad insuficiente del camión para el contenedor"));
                    }
                    Tramo tramo = obtener(idTramo);
                    tramo.setDominioCamion(dominioCamion);
                    tramo.setEstado(EstadoTramo.ASIGNADO);
                    return Mono.fromCallable(() -> tramoRepository.save(tramo))
                            .subscribeOn(Schedulers.boundedElastic());
                });
    }

    // Alias con el nombre solicitado
    public Mono<Tramo> asignarCamion(Long idTramo, String dominioCamion) {
        return asignarACamion(idTramo, dominioCamion);
    }

    public Tramo iniciarTramo(Long idTramo) {
        Tramo tramo = obtener(idTramo);
        tramo.setEstado(EstadoTramo.INICIADO);
        tramo.setFechaHoraInicioReal(LocalDateTime.now());
        return tramoRepository.save(tramo);
    }

    public Tramo finalizarTramo(Long idTramo, LocalDateTime fechaHoraFin, Double odometroFinal, 
                                 Double costoReal, Double tiempoReal) {
        Tramo tramo = obtener(idTramo);
        tramo.setEstado(EstadoTramo.FINALIZADO);
        tramo.setFechaHoraFinReal(fechaHoraFin);
        tramo.setOdometroFinal(odometroFinal);
        tramo.setCostoReal(costoReal);
        tramo.setTiempoReal(tiempoReal);
        return tramoRepository.save(tramo);
    }

    /**
     * Calcula costo y tiempo estimado para un tramo usando Google Directions y datos del camión.
     * - Distancia (km) y duración (min) desde GoogleMapsClient.
     * - costoBaseKm del camión desde LogisticaClient.
     * Guarda costoAproximado, fechaHoraInicioEstimada y fechaHoraFinEstimada.
     */
    public Mono<Tramo> calcularCostoYTiempoEstimado(Long idTramo,
                                                    double origenLat, double origenLng,
                                                    double destinoLat, double destinoLng) {
        return Mono.fromCallable(() -> obtener(idTramo))
                .subscribeOn(Schedulers.boundedElastic())
                .flatMap(tramo -> {
                    if (tramo.getDominioCamion() == null || tramo.getDominioCamion().isBlank()) {
                        return Mono.error(new IllegalStateException("El tramo no tiene camión asignado"));
                    }
                    String dominio = tramo.getDominioCamion();
                    
                    Mono<Map<String, Object>> distanciaMono = googleMapsClient.isPresent() 
                        ? googleMapsClient.get().obtenerDistanciaYDuracion(origenLat, origenLng, destinoLat, destinoLng)
                        : Mono.just(Map.of("distanciaKm", 0.0, "duracionMinutos", 0L));
                    
                    Mono<Map<String, Object>> camionMono = logisticaClient.isPresent()
                        ? logisticaClient.get().obtenerCamion(dominio)
                        : Mono.just(Map.of());
                    
                    return distanciaMono.zipWith(camionMono)
                            .flatMap(tuple -> {
                                Map<String, Object> direccionData = tuple.getT1();
                                Map<String, Object> camion = tuple.getT2();

                                Double distanciaKm = (Double) direccionData.getOrDefault("distanciaKm", 0.0);
                                Long duracionMinutos = ((Number) direccionData.getOrDefault("duracionMinutos", 0L)).longValue();

                                Object costoBaseKmObj = camion != null ? camion.get("costoBaseKm") : null;
                                double costoBaseKm = (costoBaseKmObj instanceof Number) ? ((Number) costoBaseKmObj).doubleValue() : 0.0;
                                double costoEstimado = distanciaKm * costoBaseKm;
                                tramo.setCostoAproximado(costoEstimado);

                                // Usa la duración real de Google Maps
                                if (tramo.getFechaHoraInicioEstimada() == null) {
                                    tramo.setFechaHoraInicioEstimada(LocalDateTime.now());
                                }
                                tramo.setFechaHoraFinEstimada(tramo.getFechaHoraInicioEstimada().plusMinutes(duracionMinutos));

                                return Mono.fromCallable(() -> tramoRepository.save(tramo))
                                        .subscribeOn(Schedulers.boundedElastic());
                            });
                });
    }

    /**
     * Calcula costo y tiempo estimado usando la nueva integración con Google Maps Service.
     * Este método es más directo y sincrónico que calcularCostoYTiempoEstimado.
     * 
     * @param idTramo ID del tramo a actualizar
     * @param origen Dirección o coordenadas de origen (ej: "Buenos Aires")
     * @param destino Dirección o coordenadas de destino (ej: "Córdoba")
     * @return Mono con el Tramo actualizado con costos y tiempos estimados
     */
    public Mono<Tramo> calcularCostoYTiempoEstimadoConGoogleMaps(Long idTramo,
                                                                 String origen,
                                                                 String destino) {
        return Mono.fromCallable(() -> obtener(idTramo))
                .subscribeOn(Schedulers.boundedElastic())
                .flatMap(tramo -> {
                    if (tramo.getDominioCamion() == null || tramo.getDominioCamion().isBlank()) {
                        return Mono.error(new IllegalStateException("El tramo no tiene camión asignado"));
                    }
                    
                    String dominio = tramo.getDominioCamion();
                    
                    try {
                        // Paso 1: Obtener distancia y duración desde Google Maps
                        DistanciaDTO distancia = googleMapsService.calcularDistancia(origen, destino);
                        log.info("Distancia obtenida: {} km, Duración: {}", distancia.getKilometros(), distancia.getDuracionTexto());
                        
                        // Paso 2: Obtener datos del camión (costoBaseKm)
                        Mono<Map<String, Object>> camionMono = logisticaClient.isPresent()
                            ? logisticaClient.get().obtenerCamion(dominio)
                            : Mono.just(Map.of());
                            
                        return camionMono.flatMap(camion -> {
                                    Object costoBaseKmObj = camion != null ? camion.get("costoBaseKm") : null;
                                    double costoBaseKm = (costoBaseKmObj instanceof Number) ? ((Number) costoBaseKmObj).doubleValue() : 0.0;
                                    
                                    // Paso 3: Calcular costo estimado
                                    double costoEstimado = distancia.getKilometros() * costoBaseKm;
                                    tramo.setCostoAproximado(costoEstimado);
                                    
                                    // Paso 4: Actualizar tiempos estimados
                                    if (tramo.getFechaHoraInicioEstimada() == null) {
                                        tramo.setFechaHoraInicioEstimada(LocalDateTime.now());
                                    }
                                    
                                    // Extraer minutos de duracionTexto (ej: "7 hours 15 mins" o "30 mins")
                                    long duracionMinutos = extraerMinutosDeDuracion(distancia.getDuracionTexto());
                                    tramo.setFechaHoraFinEstimada(tramo.getFechaHoraInicioEstimada().plusMinutes(duracionMinutos));
                                    
                                    // Paso 5: Guardar en base de datos
                                    log.info("Tramo actualizado - Costo: ${}, Duración: {} minutos", costoEstimado, duracionMinutos);
                                    return Mono.fromCallable(() -> tramoRepository.save(tramo))
                                            .subscribeOn(Schedulers.boundedElastic());
                                });
                        
                    } catch (RuntimeException e) {
                        log.error("Error al calcular distancia y costo para tramo {}: {}", idTramo, e.getMessage(), e);
                        return Mono.error(e);
                    }
                });
    }

    /**
     * Extrae la cantidad de minutos de una cadena de duración de Google Maps.
     * Ejemplos:
     * - "7 hours 15 mins" → 435 minutos
     * - "30 mins" → 30 minutos
     * - "2 hours" → 120 minutos
     * 
     * @param duracionTexto Texto de duración desde Google Maps
     * @return Cantidad de minutos
     */
    private long extraerMinutosDeDuracion(String duracionTexto) {
        if (duracionTexto == null || duracionTexto.isEmpty()) {
            log.warn("Duración en texto vacía, retornando 0");
            return 0L;
        }
        
        long totalMinutos = 0;
        String[] partes = duracionTexto.split(" ");
        
        for (int i = 0; i < partes.length; i++) {
            try {
                if (i + 1 < partes.length) {
                    String numero = partes[i];
                    String unidad = partes[i + 1];
                    
                    long valor = Long.parseLong(numero);
                    
                    if (unidad.startsWith("hour")) {
                        totalMinutos += valor * 60;
                        i++; // Saltar la unidad
                    } else if (unidad.startsWith("min")) {
                        totalMinutos += valor;
                        i++; // Saltar la unidad
                    }
                }
            } catch (NumberFormatException e) {
                log.warn("No se pudo parsear duración en: {}", duracionTexto);
            }
        }
        
        return totalMinutos;
    }
}
