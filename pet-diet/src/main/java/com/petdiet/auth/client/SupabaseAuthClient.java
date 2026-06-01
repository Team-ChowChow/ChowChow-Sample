package com.petdiet.auth.client;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.node.JsonNodeType;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Component
public class SupabaseAuthClient {

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    private final WebClient adminWebClient;

    public SupabaseAuthClient(
            @Value("${supabase.url}") String supabaseUrl,
            @Value("${supabase.anon-key}") String anonKey,
            @Value("${supabase.service-role-key}") String serviceRoleKey,
            ObjectMapper objectMapper) {
        this.webClient = WebClient.builder()
                .baseUrl(supabaseUrl)
                .defaultHeader("apikey", anonKey)
                .defaultHeader("Content-Type", "application/json")
                .build();
        this.adminWebClient = WebClient.builder()
                .baseUrl(supabaseUrl)
                .defaultHeader("apikey", serviceRoleKey)
                .defaultHeader("Authorization", "Bearer " + serviceRoleKey)
                .defaultHeader("Content-Type", "application/json")
                .build();
        this.objectMapper = objectMapper;
    }

    public SupabaseSignupResult signup(String email, String password) {
        try {
            String response = webClient.post()
                    .uri("/auth/v1/signup")
                    .bodyValue(Map.of("email", email, "password", password))
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            JsonNode root = objectMapper.readTree(response);

            // Supabase returns {access_token, user: {id, email}} when email confirmation is OFF
            // or {user: {id, email}, session: null} when email confirmation is ON
            JsonNode userNode = root.path("user");
            String userId = str(userNode.path("id"));
            String userEmail = str(userNode.path("email"));

            if (userId == null || userId.isEmpty()) {
                // Supabase returns {user: null} when email is already registered (email enumeration protection)
                throw new IllegalArgumentException("이미 사용 중인 이메일입니다.");
            }

            UUID authUuid = UUID.fromString(userId);

            return new SupabaseSignupResult(authUuid, userEmail);

        } catch (WebClientResponseException e) {
            int status = e.getStatusCode().value();
            if (status == 400 || status == 422) {
                String body = e.getResponseBodyAsString();
                if (body != null && (body.contains("User already registered") || body.contains("user_already_exists"))) {
                    throw new IllegalArgumentException("이미 사용 중인 이메일입니다.");
                }
                throw new IllegalArgumentException("유효하지 않은 이메일 또는 비밀번호입니다.");
            }
            if (status == 429) {
                throw new IllegalStateException("요청이 너무 많습니다. 잠시 후 다시 시도해주세요.");
            }
            if (status == 500) {
                log.error("Supabase signup 500 error body: {}", e.getResponseBodyAsString());
                throw new RuntimeException("Supabase 서버 오류: " + e.getResponseBodyAsString(), e);
            }
            throw new RuntimeException("Supabase 인증 중 오류가 발생했습니다.", e);
        } catch (IllegalArgumentException | IllegalStateException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException("Supabase 인증 중 오류가 발생했습니다.", e);
        }
    }

    public SupabaseTokenResult login(String email, String password) {
        try {
            String response = webClient.post()
                    .uri("/auth/v1/token?grant_type=password")
                    .bodyValue(Map.of("email", email, "password", password))
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            JsonNode root = objectMapper.readTree(response);
            String accessToken = root.path("access_token").stringValue();
            String refreshToken = root.path("refresh_token").stringValue();
            JsonNode user = root.path("user");
            UUID authUuid = UUID.fromString(user.path("id").stringValue());
            String userEmail = user.path("email").stringValue();

            return new SupabaseTokenResult(accessToken, refreshToken, authUuid, userEmail);

        } catch (WebClientResponseException e) {
            int status = e.getStatusCode().value();
            if (status == 400) {
                String body = e.getResponseBodyAsString();
                if (body != null && body.contains("email_not_confirmed")) {
                    throw new IllegalStateException("이메일 인증이 완료되지 않았습니다. 받은 편지함을 확인해주세요.");
                }
                throw new IllegalArgumentException("이메일 또는 비밀번호가 올바르지 않습니다.");
            }
            if (status == 422) {
                throw new IllegalArgumentException("이메일 또는 비밀번호가 올바르지 않습니다.");
            }
            if (status == 429) {
                throw new IllegalStateException("요청이 너무 많습니다. 잠시 후 다시 시도해주세요.");
            }
            throw new RuntimeException("Supabase 인증 중 오류가 발생했습니다.", e);
        } catch (IllegalArgumentException | IllegalStateException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException("Supabase 인증 중 오류가 발생했습니다.", e);
        }
    }

    public Optional<UUID> findUuidByEmail(String email) {
        try {
            String response = adminWebClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/auth/v1/admin/users")
                            .queryParam("email", email)
                            .build())
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();
            JsonNode root = objectMapper.readTree(response);
            JsonNode users = root.path("users");
            if (users.isArray() && !users.isEmpty()) {
                String id = str(users.get(0).path("id"));
                if (id != null && !id.isBlank()) return Optional.of(UUID.fromString(id));
            }
        } catch (Exception e) {
            log.warn("Supabase 사용자 조회 실패 (admin): {}", e.getMessage());
        }
        return Optional.empty();
    }

    public void confirmUserEmail(UUID authUuid) {
        try {
            adminWebClient.put()
                    .uri("/auth/v1/admin/users/" + authUuid)
                    .bodyValue(Map.of("email_confirm", true))
                    .retrieve()
                    .toBodilessEntity()
                    .block();
            log.info("Supabase 이메일 인증 처리 완료: {}", authUuid);
        } catch (Exception e) {
            log.warn("Supabase 이메일 인증 처리 실패 (무시하고 계속): {}", e.getMessage());
        }
    }

    public SupabaseTokenResult refresh(String refreshToken) {
        try {
            String response = webClient.post()
                    .uri("/auth/v1/token?grant_type=refresh_token")
                    .bodyValue(Map.of("refresh_token", refreshToken))
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            JsonNode root = objectMapper.readTree(response);
            String accessToken = root.path("access_token").stringValue();
            String newRefreshToken = root.path("refresh_token").stringValue();
            JsonNode user = root.path("user");
            UUID authUuid = UUID.fromString(user.path("id").stringValue());
            String userEmail = user.path("email").stringValue();

            return new SupabaseTokenResult(accessToken, newRefreshToken, authUuid, userEmail);
        } catch (WebClientResponseException e) {
            throw new IllegalStateException("토큰 갱신에 실패했습니다. 다시 로그인해주세요.");
        } catch (Exception e) {
            throw new RuntimeException("토큰 갱신 중 오류가 발생했습니다.", e);
        }
    }

    public void logout(String accessToken) {
        try {
            webClient.post()
                    .uri("/auth/v1/logout")
                    .header("Authorization", "Bearer " + accessToken)
                    .retrieve()
                    .toBodilessEntity()
                    .block();
        } catch (Exception e) {
            log.warn("Supabase 로그아웃 실패: {}", e.getMessage());
        }
    }

    private static String str(JsonNode node) {
        return node.getNodeType() == JsonNodeType.STRING ? node.stringValue() : null;
    }

    public record SupabaseSignupResult(UUID authUuid, String email) {}

    public record SupabaseTokenResult(
            String accessToken,
            String refreshToken,
            UUID authUuid,
            String email) {
    }
}
