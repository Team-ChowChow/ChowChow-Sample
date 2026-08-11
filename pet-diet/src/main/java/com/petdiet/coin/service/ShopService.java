package com.petdiet.coin.service;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.coin.dto.ShopCatalogResponse;
import com.petdiet.coin.dto.ShopItemResponse;
import com.petdiet.coin.entity.UserShopItem;
import com.petdiet.coin.repository.UserShopItemRepository;
import com.petdiet.coin.shop.ShopCatalog;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ShopService {

    private final UserRepository userRepository;
    private final UserShopItemRepository shopItemRepository;
    private final CoinService coinService;

    @Transactional
    public ShopCatalogResponse getCatalog(UUID authUuid) {
        User user = findUser(authUuid);
        return buildCatalog(authUuid, user);
    }

    @Transactional
    public ShopCatalogResponse purchase(UUID authUuid, String itemKey) {
        User user = findUser(authUuid);
        ShopCatalog.Item item = ShopCatalog.require(itemKey);

        UserShopItem ownedItem = shopItemRepository.findByUserAndItemKey(user, itemKey)
                .orElse(null);
        if (ownedItem == null) {
            if (item.price() > 0 && !coinService.spendCoins(
                    authUuid, item.price(), "상점 구매: " + item.name())) {
                throw new IllegalStateException("코인이 부족합니다.");
            }

            ownedItem = shopItemRepository.save(UserShopItem.builder()
                    .user(user)
                    .itemKey(item.itemKey())
                    .itemType(item.itemType())
                    .build());
        }

        equipPurchasedItem(user, ownedItem, item);
        return buildCatalog(authUuid, user);
    }

    @Transactional
    public ShopCatalogResponse equip(UUID authUuid, String itemKey) {
        User user = findUser(authUuid);
        ShopCatalog.Item item = ShopCatalog.require(itemKey);

        UserShopItem ownedItem = shopItemRepository.findByUserAndItemKey(user, itemKey)
                .orElseGet(() -> {
                    if (item.price() > 0) {
                        throw new IllegalStateException("구매한 아이템만 장착할 수 있습니다.");
                    }
                    return shopItemRepository.save(UserShopItem.builder()
                            .user(user)
                            .itemKey(item.itemKey())
                            .itemType(item.itemType())
                            .build());
                });

        if (ShopCatalog.ROOM_DECOR.equals(item.itemType())) {
            if (ownedItem.isEquipped()) {
                ownedItem.unequip();
            } else {
                ownedItem.equip();
            }
            shopItemRepository.save(ownedItem);
        } else {
            equipExclusive(user, ownedItem, item.itemType());
        }

        return buildCatalog(authUuid, user);
    }

    private void equipPurchasedItem(User user, UserShopItem ownedItem, ShopCatalog.Item item) {
        if (ShopCatalog.isExclusive(item.itemType())) {
            equipExclusive(user, ownedItem, item.itemType());
            return;
        }
        if (!ownedItem.isEquipped()) {
            ownedItem.equip();
            shopItemRepository.save(ownedItem);
        }
    }

    private void equipExclusive(User user, UserShopItem itemToEquip, String itemType) {
        List<UserShopItem> equipped = shopItemRepository
                .findByUserAndItemTypeAndIsEquippedTrue(user, itemType);
        equipped.stream()
                .filter(item -> !item.getItemKey().equals(itemToEquip.getItemKey()))
                .forEach(UserShopItem::unequip);
        shopItemRepository.saveAll(equipped);

        itemToEquip.equip();
        shopItemRepository.save(itemToEquip);
    }

    private ShopCatalogResponse buildCatalog(UUID authUuid, User user) {
        Map<String, UserShopItem> ownedByKey = shopItemRepository.findByUser(user).stream()
                .collect(Collectors.toMap(UserShopItem::getItemKey, Function.identity()));

        boolean hasBackgroundEquipped = ownedByKey.values().stream()
                .anyMatch(item -> ShopCatalog.ROOM_BACKGROUND.equals(item.getItemType()) && item.isEquipped());
        boolean hasProfileFrameEquipped = ownedByKey.values().stream()
                .anyMatch(item -> ShopCatalog.PROFILE_FRAME.equals(item.getItemType()) && item.isEquipped());

        List<ShopItemResponse> items = ShopCatalog.items().stream()
                .map(item -> {
                    UserShopItem owned = ownedByKey.get(item.itemKey());
                    boolean isOwned = item.price() == 0 || owned != null;
                    boolean isEquipped = owned != null && owned.isEquipped();

                    if (ShopCatalog.DEFAULT_BACKGROUND.equals(item.itemKey()) && !hasBackgroundEquipped) {
                        isEquipped = true;
                    }
                    if (ShopCatalog.DEFAULT_PROFILE_FRAME.equals(item.itemKey()) && !hasProfileFrameEquipped) {
                        isEquipped = true;
                    }
                    return ShopItemResponse.from(item, isOwned, isEquipped);
                })
                .toList();

        return new ShopCatalogResponse(coinService.getBalance(authUuid), items);
    }

    private User findUser(UUID authUuid) {
        return userRepository.findByAuthUuid(authUuid)
                .orElseThrow(() -> new IllegalStateException("유저를 찾을 수 없습니다."));
    }
}
