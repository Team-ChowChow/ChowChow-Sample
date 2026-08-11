-- 사용자는 본인의 산책 기록만 조회할 수 있습니다.
ALTER TABLE "WalkRecords" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "walk_records_select_own"
    ON "WalkRecords" FOR SELECT
    TO authenticated
    USING ("userId" = get_current_user_id());

-- 산책 저장과 코인 지급은 Spring Boot 서버에서만 처리합니다.
