package com.petdiet.auth.service;

import com.petdiet.auth.client.EmailConfirmTokenUtil;
import com.petdiet.auth.client.ResendEmailClient;
import com.petdiet.auth.client.SupabaseAuthClient;
import com.petdiet.auth.client.SupabaseAuthClient.SupabaseSignupResult;
import com.petdiet.auth.client.SupabaseAuthClient.SupabaseTokenResult;
import com.petdiet.auth.dto.AuthResponse;
import com.petdiet.auth.dto.LoginRequest;
import com.petdiet.auth.dto.SignupRequest;
import com.petdiet.auth.entity.AuthAccount;
import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.AuthAccountRepository;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.config.SupabasePrincipal;
import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final AuthAccountRepository authAccountRepository;
    private final SupabaseAuthClient supabaseAuthClient;
    private final ResendEmailClient resendEmailClient;
    private final EmailConfirmTokenUtil emailConfirmTokenUtil;

    @Value("${app.base-url}")
    private String appBaseUrl;

    // 이메일 사전 인증 상태 저장 (메모리, 24시간 유효)
    private final Map<String, Long> preVerifiedEmails = new ConcurrentHashMap<>();

    public void sendEmailVerify(String email) {
        if (authAccountRepository.existsByAuthEmail(email)) {
            throw new IllegalArgumentException("이미 사용 중인 이메일입니다.");
        }
        String token = emailConfirmTokenUtil.generatePreVerify(email);
        String verifyUrl = appBaseUrl + "/api/auth/pre-verify?token=" + token;
        resendEmailClient.sendConfirmationEmail(email, verifyUrl);
        log.info("사전 인증 이메일 발송: {}", email);
    }

    public void confirmPreVerify(String token) {
        String email = emailConfirmTokenUtil.verifyPreVerify(token);
        preVerifiedEmails.put(email, System.currentTimeMillis());
        log.info("이메일 사전 인증 완료: {}", email);
    }

    public boolean isPreVerified(String email) {
        Long ts = preVerifiedEmails.get(email);
        if (ts == null) return false;
        return System.currentTimeMillis() - ts < 86_400_000L;
    }

    @Transactional
    public AuthResponse signup(SignupRequest req) {
        if (!isPreVerified(req.getEmail())) {
            throw new IllegalArgumentException("이메일 인증이 완료되지 않았습니다. 먼저 이메일 인증을 완료해주세요.");
        }

        List<AuthAccount> existing = authAccountRepository.findAllByAuthEmail(req.getEmail());
        if (!existing.isEmpty()) {
            boolean hasSocial = existing.stream().anyMatch(a -> !"EMAIL".equals(a.getAuthProvider()));
            boolean hasEmail = existing.stream().anyMatch(a -> "EMAIL".equals(a.getAuthProvider()));
            if (hasSocial && !hasEmail) {
                String provider = existing.stream()
                        .filter(a -> !"EMAIL".equals(a.getAuthProvider()))
                        .map(AuthAccount::getAuthProvider)
                        .findFirst().orElse("소셜");
                throw new IllegalArgumentException(
                        providerDisplayName(provider) + " 계정으로 가입된 이메일입니다. " + providerDisplayName(provider) + " 로그인을 이용해주세요.");
            }
            throw new IllegalArgumentException("이미 사용 중인 이메일입니다.");
        }

        // Supabase에 계정 생성
        UUID authUuid;
        try {
            SupabaseSignupResult result = supabaseAuthClient.signup(req.getEmail(), req.getPassword());
            authUuid = result.authUuid();
        } catch (IllegalArgumentException e) {
            // 이미 Supabase에 있는 경우 UUID 조회
            Optional<UUID> pendingUuid = supabaseAuthClient.findUuidByEmail(req.getEmail());
            authUuid = pendingUuid.orElseThrow(() -> e);
        }

        // 이메일 pre-verify가 됐으므로 Supabase에서도 confirm 처리
        supabaseAuthClient.confirmUserEmail(authUuid);

        // DB에 유저 즉시 생성
        LocalDate birthdate = null;
        String birthdateStr = req.getBirthdate();
        if (birthdateStr != null && !birthdateStr.isBlank()) {
            try { birthdate = LocalDate.parse(birthdateStr); } catch (Exception ignored) {}
        }

        String nickname = req.getNickname();
        if (userRepository.existsByUserNickname(nickname)) {
            throw new IllegalArgumentException("이미 사용 중인 닉네임입니다.");
        }
        User user = userRepository.save(User.builder()
                .authUuid(authUuid)
                .userName(req.getUserName())
                .userNickname(nickname)
                .userBirthdate(birthdate)
                .userStatus("ACTIVE")
                .build());

        AuthAccount account = authAccountRepository.save(AuthAccount.builder()
                .user(user)
                .authProvider("EMAIL")
                .authEmail(req.getEmail())
                .providerUserId(authUuid.toString())
                .authStatus("ACTIVE")
                .build());

        preVerifiedEmails.remove(req.getEmail());
        log.info("회원가입 완료: {}", req.getEmail());

        return AuthResponse.of(user, account, true).toBuilder()
                .message("회원가입이 완료됐습니다. 로그인해주세요.")
                .build();
    }

    @Transactional
    public AuthResponse refresh(String refreshToken) {
        SupabaseTokenResult result = supabaseAuthClient.refresh(refreshToken);
        User user = userRepository.findByAuthUuid(result.authUuid())
                .orElseThrow(() -> new IllegalStateException("사용자를 찾을 수 없습니다."));
        AuthAccount account = authAccountRepository.findByUserAndAuthProvider(user, "EMAIL").orElse(null);
        return AuthResponse.of(user, account, false).toBuilder()
                .accessToken(result.accessToken())
                .refreshToken(result.refreshToken())
                .build();
    }

    @Transactional
    public AuthResponse login(LoginRequest req) {
        List<AuthAccount> accounts = authAccountRepository.findAllByAuthEmail(req.getEmail());
        if (!accounts.isEmpty()) {
            boolean hasEmail = accounts.stream().anyMatch(a -> "EMAIL".equals(a.getAuthProvider()));
            if (!hasEmail) {
                String provider = accounts.stream()
                        .map(AuthAccount::getAuthProvider)
                        .findFirst().orElse("소셜");
                throw new IllegalArgumentException(
                        providerDisplayName(provider) + " 계정으로 가입된 이메일입니다. " + providerDisplayName(provider) + " 로그인을 이용해주세요.");
            }
        }

        SupabaseTokenResult result = supabaseAuthClient.login(req.getEmail(), req.getPassword());

        User user = userRepository.findByAuthUuid(result.authUuid())
                .orElseThrow(() -> new IllegalStateException("이메일 인증이 완료되지 않았습니다. 받은 편지함을 확인해주세요."));

        AuthAccount account = authAccountRepository.findByUserAndAuthProvider(user, "EMAIL").orElse(null);
        if (account != null) account.updateLoginAt();

        return AuthResponse.of(user, account, false).toBuilder()
                .accessToken(result.accessToken())
                .refreshToken(result.refreshToken())
                .build();
    }

    @Transactional
    public AuthResponse confirmEmail(String token) {
        Claims claims = emailConfirmTokenUtil.verify(token);
        UUID authUuid = UUID.fromString(claims.getSubject());
        String email = claims.get("email", String.class);
        String userName = claims.get("userName", String.class);
        String birthdateStr = claims.get("birthdate", String.class);
        LocalDate birthdate = null;
        if (birthdateStr != null && !birthdateStr.isBlank()) {
            try { birthdate = LocalDate.parse(birthdateStr); } catch (Exception ignored) {}
        }

        // 이미 인증 완료된 경우 (중복 클릭) — 기존 유저 반환
        Optional<User> existing = userRepository.findByAuthUuid(authUuid);
        if (existing.isPresent()) {
            AuthAccount account = authAccountRepository.findByUserAndAuthProvider(existing.get(), "EMAIL").orElse(null);
            return AuthResponse.of(existing.get(), account, false);
        }

        String nickname = generateNickname(email);
        User user = userRepository.save(User.builder()
                .authUuid(authUuid)
                .userName(userName != null ? userName : email)
                .userNickname(nickname)
                .userBirthdate(birthdate)
                .userStatus("ACTIVE")
                .build());

        AuthAccount account = authAccountRepository.save(AuthAccount.builder()
                .user(user)
                .authProvider("EMAIL")
                .authEmail(email)
                .providerUserId(authUuid.toString())
                .authStatus("ACTIVE")
                .build());

        supabaseAuthClient.confirmUserEmail(authUuid);

        log.info("이메일 인증 완료 — DB 등록: {}", email);
        return AuthResponse.of(user, account, true);
    }

    @Transactional
    public AuthResponse syncSocialUser(SupabasePrincipal principal) {
        String provider = principal.provider().toUpperCase();

        Optional<User> existing = userRepository.findByAuthUuid(principal.authUuid());
        if (existing.isPresent()) {
            User user = existing.get();
            AuthAccount account = authAccountRepository.findByUserAndAuthProvider(user, provider).orElse(null);
            if (account != null) account.updateLoginAt();
            return AuthResponse.of(user, account, false);
        }

        User newUser = createUser(principal);
        AuthAccount account = createAuthAccount(newUser, principal, provider);
        log.info("신규 소셜 유저 등록 [provider={}]: {}", provider, principal.email());
        return AuthResponse.of(newUser, account, true);
    }

    @Transactional(readOnly = true)
    public AuthResponse getMe(UUID authUuid) {
        User user = userRepository.findByAuthUuid(authUuid)
                .orElseThrow(() -> new IllegalStateException("등록되지 않은 유저입니다."));
        AuthAccount account = authAccountRepository.findFirstByUserOrderByAuthCreatedAtAsc(user).orElse(null);
        return AuthResponse.of(user, account, false);
    }

    @Transactional(readOnly = true)
    public boolean isEmailAvailable(String authEmail) {
        return !authAccountRepository.existsByAuthEmail(authEmail);
    }

    @Transactional(readOnly = true)
    public boolean isNicknameAvailable(String nickname) {
        return !userRepository.existsByUserNickname(nickname);
    }

    public void logout(String accessToken) {
        supabaseAuthClient.logout(accessToken);
    }

    private User createUser(SupabasePrincipal principal) {
        String nickname = generateNickname(principal.email());
        return userRepository.save(User.builder()
                .authUuid(principal.authUuid())
                .userName(principal.name().isBlank() ? principal.email() : principal.name())
                .userNickname(nickname)
                .userProfileImg(principal.avatarUrl())
                .userStatus("ACTIVE")
                .build());
    }

    private AuthAccount createAuthAccount(User user, SupabasePrincipal principal, String provider) {
        return authAccountRepository.save(AuthAccount.builder()
                .user(user)
                .authProvider(provider)
                .authEmail(principal.email())
                .providerUserId(principal.authUuid().toString())
                .authStatus("ACTIVE")
                .build());
    }

    private String providerDisplayName(String provider) {
        return switch (provider.toUpperCase()) {
            case "GOOGLE" -> "구글";
            case "KAKAO" -> "카카오";
            case "NAVER" -> "네이버";
            case "APPLE" -> "애플";
            default -> provider;
        };
    }

    private String generateNickname(String email) {
        String base = email.contains("@") ? email.split("@")[0] : email;
        String candidate = base;
        int suffix = 1;
        while (userRepository.existsByUserNickname(candidate)) {
            candidate = base + suffix++;
        }
        return candidate;
    }
}
