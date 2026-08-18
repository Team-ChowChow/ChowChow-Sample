package com.petdiet.food.repository;

import com.petdiet.food.entity.CommercialFood;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface CommercialFoodRepository extends JpaRepository<CommercialFood, Integer> {
    Optional<CommercialFood> findByBarcode(String barcode);
    List<CommercialFood> findTop30ByProductNameContainingIgnoreCaseOrBrandNameContainingIgnoreCaseOrderByFoodIdDesc(
            String productName, String brandName);
    List<CommercialFood> findTop30ByPetTypeAndProductNameContainingIgnoreCaseOrPetTypeAndBrandNameContainingIgnoreCaseOrderByFoodIdDesc(
            String petType1, String productName, String petType2, String brandName);

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
