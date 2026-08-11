package com.petdiet.coin.entity;

import com.petdiet.auth.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.OffsetDateTime;

@Entity
@Table(name = "\"UserShopItems\"")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserShopItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "\"userShopItemId\"")
    private Long userShopItemId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "\"userId\"", nullable = false)
    private User user;

    @Column(name = "\"itemKey\"", nullable = false, length = 60)
    private String itemKey;

    @Column(name = "\"itemType\"", nullable = false, length = 30)
    private String itemType;

    @Builder.Default
    @Column(name = "\"isEquipped\"", nullable = false)
    private Boolean isEquipped = false;

    @CreationTimestamp
    @Column(name = "\"purchasedAt\"", nullable = false, updatable = false)
    private OffsetDateTime purchasedAt;

    @Column(name = "\"equippedAt\"")
    private OffsetDateTime equippedAt;

    public boolean isEquipped() {
        return Boolean.TRUE.equals(isEquipped);
    }

    public void equip() {
        this.isEquipped = true;
        this.equippedAt = OffsetDateTime.now();
    }

    public void unequip() {
        this.isEquipped = false;
        this.equippedAt = null;
    }
}
