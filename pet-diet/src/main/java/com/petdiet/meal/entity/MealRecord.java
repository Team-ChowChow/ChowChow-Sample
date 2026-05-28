package com.petdiet.meal.entity;

import com.petdiet.auth.entity.User;
import com.petdiet.pet.entity.UserPet;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.OffsetDateTime;

@Entity
@Table(name = "\"MealRecords\"")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MealRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "\"mealId\"")
    private Integer mealId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "\"userId\"", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "\"petId\"")
    private UserPet pet;

    @Column(name = "\"mealTitle\"", nullable = false)
    private String mealTitle;

    @Column(name = "\"mealNote\"")
    private String mealNote;

    @Column(name = "\"imageUrl\"")
    private String imageUrl;

    @Column(name = "\"mealDate\"")
    private String mealDate;

    @CreationTimestamp
    @Column(name = "\"createdAt\"", updatable = false)
    private OffsetDateTime createdAt;
}
