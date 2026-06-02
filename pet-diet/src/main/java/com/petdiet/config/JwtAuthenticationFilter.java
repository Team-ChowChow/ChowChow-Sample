package com.petdiet.config;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.reactive.function.client.WebClient;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.security.spec.ECGenParameterSpec;
import java.security.spec.ECParameterSpec;
import java.security.spec.ECPoint;
import java.security.spec.ECPublicKeySpec;
import java.util.Arrays;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final byte[] secretKeyBytes;
    private final String supabaseUrl;
    private final ObjectMapper objectMapper;

    private volatile List<PublicKey> ecPublicKeys = List.of();
    private volatile boolean ecKeyFetched = false;

    public JwtAuthenticationFilter(
            @Value("${supabase.jwt-secret}") String jwtSecret,
            @Value("${supabase.url}") String supabaseUrl,
            ObjectMapper objectMapper) {
        this.secretKeyBytes = decodeSecret(jwtSecret);
        this.supabaseUrl = supabaseUrl;
        this.objectMapper = objectMapper;
    }

    private static byte[] decodeSecret(String secret) {
        try {
            return Base64.getDecoder().decode(secret);
        } catch (Exception e) {
            return secret.getBytes();
        }
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String token = extractToken(request);
        if (token != null) {
            try {
                SupabasePrincipal principal = parseToken(token);
                UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                        principal, null, List.of(new SimpleGrantedAuthority("ROLE_USER"))
                );
                SecurityContextHolder.getContext().setAuthentication(auth);
            } catch (Exception e) {
                log.debug("JWT 검증 실패: {}", e.getMessage());
            }
        }
        filterChain.doFilter(request, response);
    }

    private SupabasePrincipal parseToken(String token) throws Exception {
        String[] parts = token.split("\\.");
        if (parts.length != 3) throw new IllegalArgumentException("Invalid JWT format");

        String headerJson = new String(base64UrlDecode(parts[0]), StandardCharsets.UTF_8);
        JsonNode header = objectMapper.readTree(headerJson);
        String alg = textOrNull(header.path("alg"));
        log.debug("JWT alg: {}", alg);

        if ("ES256".equals(alg)) {
            return parseEs256Token(parts);
        } else {
            return parseHs256Token(token);
        }
    }

    private SupabasePrincipal parseEs256Token(String[] parts) throws Exception {
        byte[] signingInput = (parts[0] + "." + parts[1]).getBytes(StandardCharsets.UTF_8);
        byte[] rawSig = base64UrlDecode(parts[2]);
        byte[] derSig = rawSignatureToDer(rawSig);

        boolean verified = false;
        for (PublicKey pk : getEcPublicKeys()) {
            try {
                Signature sig = Signature.getInstance("SHA256withECDSA");
                sig.initVerify(pk);
                sig.update(signingInput);
                if (sig.verify(derSig)) {
                    verified = true;
                    break;
                }
            } catch (Exception e) {
                log.debug("EC key verification attempt failed: {}", e.getMessage());
            }
        }
        if (!verified) throw new SecurityException("ES256 signature verification failed");

        String payloadJson = new String(base64UrlDecode(parts[1]), StandardCharsets.UTF_8);
        JsonNode payload = objectMapper.readTree(payloadJson);
        return extractPrincipal(payload);
    }

    private SupabasePrincipal parseHs256Token(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(Keys.hmacShaKeyFor(secretKeyBytes))
                .build()
                .parseSignedClaims(token)
                .getPayload();

        UUID authUuid = UUID.fromString(claims.getSubject());
        String email = claims.get("email", String.class);

        @SuppressWarnings("unchecked")
        Map<String, Object> userMeta = (Map<String, Object>) claims.get("user_metadata");
        @SuppressWarnings("unchecked")
        Map<String, Object> appMeta = (Map<String, Object>) claims.get("app_metadata");

        String name = "";
        String avatarUrl = null;
        if (userMeta != null) {
            name = (String) userMeta.getOrDefault("full_name", userMeta.getOrDefault("name", ""));
            avatarUrl = (String) userMeta.get("avatar_url");
        }
        String provider = appMeta != null ? appMeta.getOrDefault("provider", "email").toString() : "email";

        return new SupabasePrincipal(authUuid, email, name, avatarUrl, provider);
    }

    private SupabasePrincipal extractPrincipal(JsonNode payload) {
        String sub = textOrNull(payload.path("sub"));
        if (sub == null) throw new IllegalArgumentException("JWT에 sub claim이 없습니다");
        UUID authUuid = UUID.fromString(sub);
        String email = textOrNull(payload.path("email"));

        JsonNode userMeta = payload.path("user_metadata");
        String name = textOrNull(userMeta.path("full_name"));
        if (name == null || name.isEmpty()) {
            name = textOrNull(userMeta.path("name"));
        }
        if (name == null) name = "";
        String avatarUrl = textOrNull(userMeta.path("avatar_url"));

        JsonNode appMeta = payload.path("app_metadata");
        String provider = textOrNull(appMeta.path("provider"));
        if (provider == null) provider = "email";

        return new SupabasePrincipal(authUuid, email, name, avatarUrl, provider);
    }

    private static String textOrNull(JsonNode node) {
        if (node == null || node.isMissingNode() || node.isNull()) return null;
        return node.isString() ? node.stringValue() : null;
    }

    private List<PublicKey> getEcPublicKeys() {
        if (!ecKeyFetched || ecPublicKeys.isEmpty()) {
            synchronized (this) {
                if (!ecKeyFetched || ecPublicKeys.isEmpty()) {
                    List<PublicKey> fetched = fetchEcPublicKeys();
                    if (!fetched.isEmpty()) {
                        ecPublicKeys = fetched;
                        ecKeyFetched = true;
                    }
                }
            }
        }
        return ecPublicKeys;
    }

    private List<PublicKey> fetchEcPublicKeys() {
        try {
            String jwksJson = WebClient.create(supabaseUrl)
                    .get()
                    .uri("/auth/v1/.well-known/jwks.json")
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            JsonNode keysNode = objectMapper.readTree(jwksJson).path("keys");
            List<PublicKey> result = new java.util.ArrayList<>();

            AlgorithmParameters params = AlgorithmParameters.getInstance("EC");
            params.init(new ECGenParameterSpec("secp256r1"));
            ECParameterSpec ecSpec = params.getParameterSpec(ECParameterSpec.class);
            KeyFactory kf = KeyFactory.getInstance("EC");

            for (JsonNode key : keysNode) {
                if (!"EC".equals(key.path("kty").stringValue())) continue;
                try {
                    byte[] xBytes = base64UrlDecode(key.path("x").stringValue());
                    byte[] yBytes = base64UrlDecode(key.path("y").stringValue());
                    ECPoint point = new ECPoint(new BigInteger(1, xBytes), new BigInteger(1, yBytes));
                    result.add(kf.generatePublic(new ECPublicKeySpec(point, ecSpec)));
                } catch (Exception e) {
                    log.warn("JWKS 키 파싱 실패: {}", e.getMessage());
                }
            }

            log.info("Supabase JWKS에서 EC 공개키 {}개 로드 성공", result.size());
            return result;
        } catch (Exception e) {
            log.warn("Supabase JWKS 조회 실패, HS256으로 fallback: {}", e.getMessage());
            return List.of();
        }
    }

    private String extractToken(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            return header.substring(7);
        }
        return null;
    }

    // JWS 서명(R||S 64바이트)을 Java Signature가 요구하는 DER 형식으로 변환
    private static byte[] rawSignatureToDer(byte[] rawSig) {
        int half = rawSig.length / 2;
        byte[] r = stripLeadingZeros(Arrays.copyOfRange(rawSig, 0, half));
        byte[] s = stripLeadingZeros(Arrays.copyOfRange(rawSig, half, rawSig.length));

        byte[] rDer = toDerInteger(r);
        byte[] sDer = toDerInteger(s);

        int seqLen = rDer.length + sDer.length;
        byte[] der = new byte[2 + seqLen];
        der[0] = 0x30;
        der[1] = (byte) seqLen;
        System.arraycopy(rDer, 0, der, 2, rDer.length);
        System.arraycopy(sDer, 0, der, 2 + rDer.length, sDer.length);
        return der;
    }

    private static byte[] stripLeadingZeros(byte[] value) {
        int start = 0;
        while (start < value.length - 1 && value[start] == 0) start++;
        return start == 0 ? value : Arrays.copyOfRange(value, start, value.length);
    }

    private static byte[] toDerInteger(byte[] value) {
        // 최상위 비트가 1이면 0x00을 앞에 붙여 양수로 만듦
        if ((value[0] & 0x80) != 0) {
            byte[] padded = new byte[value.length + 1];
            System.arraycopy(value, 0, padded, 1, value.length);
            value = padded;
        }
        byte[] result = new byte[2 + value.length];
        result[0] = 0x02;
        result[1] = (byte) value.length;
        System.arraycopy(value, 0, result, 2, value.length);
        return result;
    }

    // Base64URL 디코딩 (패딩 없는 경우도 처리)
    private static byte[] base64UrlDecode(String s) {
        if (s == null || s.isEmpty()) return new byte[0];
        switch (s.length() % 4) {
            case 2: s += "=="; break;
            case 3: s += "="; break;
            default: break;
        }
        return Base64.getUrlDecoder().decode(s);
    }
}
