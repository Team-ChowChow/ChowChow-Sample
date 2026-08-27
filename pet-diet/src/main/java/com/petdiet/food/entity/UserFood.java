package com.petdiet.food.entity;

import com.petdiet.auth.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

/** 사용자가 직접 입력한 사료 정보. CommercialFoods와 달리 본인에게만 보이는 개인 데이터. */
@Entity
@Table(name = "\"UserFoods\"")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserFood {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "\"userFoodId\"")
    private Integer userFoodId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "\"userId\"", nullable = false)
    private User user;

    @Column(name = "\"brandName\"")
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

    @CreationTimestamp
    @Column(name = "\"createdAt\"", nullable = false, updatable = false)
    private OffsetDateTime createdAt;
}
