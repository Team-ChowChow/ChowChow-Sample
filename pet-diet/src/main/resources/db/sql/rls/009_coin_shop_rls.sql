-- 코인 상점 인벤토리는 본인 데이터만 조회할 수 있습니다.
ALTER TABLE "UserShopItems" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_shop_items_select_own"
    ON "UserShopItems" FOR SELECT
    TO authenticated
    USING ("userId" = get_current_user_id());

-- 구매/장착 변경은 코인 차감과 함께 Spring Boot 서버에서만 처리합니다.
