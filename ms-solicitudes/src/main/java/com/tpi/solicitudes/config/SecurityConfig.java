package com.tpi.solicitudes.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.web.SecurityFilterChain;

@Slf4j
@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // Permitir Swagger y endpoints públicos sin autenticación
                .requestMatchers(
                    "/ping",
                    "/v3/api-docs/**",
                    "/swagger-ui/**",
                    "/swagger-ui.html"
                ).permitAll()
                // Permitir GET en /api/clientes/{id} sin autenticación (leer clientes)
                .requestMatchers(HttpMethod.GET, "/api/clientes/**").permitAll()
                // Permitir GET en /api/solicitudes/{id} sin autenticación (leer solicitudes)
                .requestMatchers(HttpMethod.GET, "/api/solicitudes/**").permitAll()
                // Permitir GET en /api/tramos y paths relacionados sin autenticación (leer tramos)
                .requestMatchers(HttpMethod.GET, "/api/tramos/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/solicitudes/**").permitAll()
                // Todos los endpoints /api/** requieren autenticación
                .requestMatchers("/api/**").authenticated()
                .anyRequest().permitAll()
            );
        
        // Solo configure oauth2ResourceServer si Keycloak está disponible
        // Por ahora, se deshabilita para testing sin Keycloak
        // .oauth2ResourceServer(oauth2 -> oauth2
        //     .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter()))
        // );

        return http.build();
    }

    /**
     * Convierte los roles de Keycloak (realm_access.roles) a autoridades de Spring Security.
     * Los roles se mapean con prefijo "ROLE_" para que funcionen con hasRole().
     */
    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtGrantedAuthoritiesConverter grantedAuthoritiesConverter = new JwtGrantedAuthoritiesConverter();
        // Extraer roles de "realm_access.roles" en lugar de "scope"
        grantedAuthoritiesConverter.setAuthoritiesClaimName("realm_access.roles");
        grantedAuthoritiesConverter.setAuthorityPrefix("ROLE_");

        JwtAuthenticationConverter jwtAuthenticationConverter = new JwtAuthenticationConverter();
        jwtAuthenticationConverter.setJwtGrantedAuthoritiesConverter(grantedAuthoritiesConverter);
        return jwtAuthenticationConverter;
    }
}
