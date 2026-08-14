package com.petdiet.food.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity
@Table(name = "\"CommercialFoods\"")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CommercialFood {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "\"foodId\"")
    private Integer foodId;

    // Open Pet Food Facts의 바코드(product code) — 중복 동기화 방지용 unique key
    @Column(name = "\"barcode\"", unique = true)
    private String barcode;

    @Column(name = "\"brandName\"", nullable = false)
    private String brandName;

    @Column(name = "\"productName\"", nullable = false)
    private String productName;

    @Column(name = "\"petType\"", length = 10)
    private String petType;

    @Column(name = "\"caloriesPer100g\"", precision = 8, scale = 2)
    private BigDecimal caloriesPer100g;

    @Column(name = "\"proteinG\"", precision = 8, scale = 2)
    private BigDecimal proteinG;

    @Column(name = "\"fatG\"", precision = 8, scale = 2)
    private BigDecimal fatG;

    @Column(name = "\"carbohydrateG\"", precision = 8, scale = 2)
    private BigDecimal carbohydrateG;

    @Column(name = "\"ingredientsText\"", columnDefinition = "TEXT")
    private String ingredientsText;

    @Column(name = "\"imageUrl\"")
    private String imageUrl;

    @CreationTimestamp
    @Column(name = "\"createdAt\"", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "\"updatedAt\"", nullable = false)
    private OffsetDateTime updatedAt;
}
