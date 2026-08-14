package com.petdiet.food.repository;

import com.petdiet.food.entity.CommercialFood;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CommercialFoodRepository extends JpaRepository<CommercialFood, Integer> {
    Optional<CommercialFood> findByBarcode(String barcode);
    List<CommercialFood> findTop30ByProductNameContainingIgnoreCaseOrBrandNameContainingIgnoreCase(
            String productName, String brandName);
}
