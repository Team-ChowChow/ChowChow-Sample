package com.petdiet.coin.repository;

import com.petdiet.auth.entity.User;
import com.petdiet.coin.entity.UserShopItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserShopItemRepository extends JpaRepository<UserShopItem, Long> {
    List<UserShopItem> findByUser(User user);
    Optional<UserShopItem> findByUserAndItemKey(User user, String itemKey);
    List<UserShopItem> findByUserAndItemTypeAndIsEquippedTrue(User user, String itemType);
}
