# 팔로워·팔로잉 API 연동 계약

Flutter 클라이언트의 연결 지점은
`ChowChow-Front/flutter_app/lib/services/follow_service.dart`입니다.
인증은 기존 API와 동일하게 `Authorization: Bearer <token>` 헤더를 사용합니다.

## 1. 프로필 통계

기존 `GET /api/users/me/stats` 응답에 아래 두 필드를 추가합니다.

```json
{
  "savedRecipes": 3,
  "completedCooking": 2,
  "writtenPosts": 1,
  "writtenReviews": 0,
  "followerCount": 12,
  "followingCount": 8
}
```

- `followerCount`: 로그인 사용자를 팔로우하는 활성 사용자의 수
- `followingCount`: 로그인 사용자가 팔로우하는 활성 사용자의 수
- 두 값은 음수가 아닌 정수여야 합니다.
- 필드가 없으면 현재 클라이언트는 안전하게 `0`으로 표시합니다.

## 2. 팔로워 목록

`GET /api/users/me/followers?page=0&size=50`

로그인 사용자를 팔로우하는 사용자 목록을 반환합니다.

## 3. 팔로잉 목록

`GET /api/users/me/following?page=0&size=50`

로그인 사용자가 팔로우하는 사용자 목록을 반환합니다.

## 4. 목록 응답 형식

Spring Data `Page`와 같은 아래 형식을 권장합니다.

```json
{
  "content": [
    {
      "userId": 17,
      "userName": "홍길동",
      "userNickname": "멍냥집사",
      "userProfileImg": "https://example.com/profile/17.jpg",
      "isFollowing": true
    }
  ],
  "totalElements": 1,
  "number": 0,
  "last": true
}
```

필수 필드는 `userId`이며 이름과 이미지 필드는 `null`을 허용합니다.
`isFollowing`은 해당 사용자를 현재 로그인 사용자가 팔로우 중인지 나타내는 선택
필드입니다. 누락 시 클라이언트는 `false`로 처리합니다.

목록 순서는 최근 팔로우한 사용자 우선으로 정렬하는 것을 권장합니다. 탈퇴하거나
비활성화된 사용자는 통계와 목록에서 제외해야 합니다.

## 5. 클라이언트 라우트

- `/profile/followers`: 나를 팔로우한 사용자
- `/profile/following`: 내가 팔로우한 사용자

백엔드가 위 계약으로 응답하면 별도의 화면 코드 변경 없이 목록과 수치가 표시됩니다.
