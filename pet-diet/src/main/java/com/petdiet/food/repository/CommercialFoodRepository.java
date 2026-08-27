package com.petdiet.food.repository;

import com.petdiet.food.entity.CommercialFood;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface CommercialFoodRepository extends JpaRepository<CommercialFood, Integer> {
    Optional<CommercialFood> findByBarcode(String barcode);

    // 인기순(급여 기록에서 이 사료가 선택된 횟수) 정렬, 동률이면 최신 등록순
    // brand 조건은 LIMIT(페이지 크기) 적용 전 SQL 단계에서 걸러야 한다 — 인기순 상위 N개를
    // 먼저 자른 뒤 Java에서 브랜드로 필터링하면, 그 브랜드 제품이 상위 N개 밖에 있을 때
    // 결과가 비어버리는 버그가 생긴다(종 필터가 없어 후보군이 넓을수록 더 잘 발생).
    @Query("""
            SELECT c FROM CommercialFood c WHERE
            (:petType IS NULL OR :petType = '' OR c.petType = :petType)
            AND (:brand IS NULL OR :brand = '' OR c.brandName = :brand)
            AND (LOWER(c.productName) LIKE LOWER(CONCAT('%', :query, '%'))
                 OR LOWER(c.brandName) LIKE LOWER(CONCAT('%', :query, '%')))
            ORDER BY (SELECT COUNT(m) FROM MealRecord m WHERE m.commercialFoodId = c.foodId) DESC, c.foodId DESC
            """)
    List<CommercialFood> searchByPopularity(
            @Param("query") String query, @Param("petType") String petType,
            @Param("brand") String brand, Pageable pageable);

    @Query("""
            SELECT DISTINCT c.brandName FROM CommercialFood c WHERE
            (:petType IS NULL OR :petType = '' OR c.petType = :petType)
            ORDER BY c.brandName
            """)
    List<String> findDistinctBrandNames(@Param("petType") String petType);

    long deleteBySource(String source);
    boolean existsByBrandNameAndProductName(String brandName, String productName);
    List<CommercialFood> findBySourceAndImageUrlIsNull(String source);
}
