package com.petdiet.coin.service;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.coin.entity.UserShopItem;
import com.petdiet.coin.repository.UserShopItemRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class ShopServiceTest {

    private final UUID authUuid = UUID.randomUUID();
    private User user;
    private UserRepository userRepository;
    private UserShopItemRepository shopItemRepository;
    private CoinService coinService;
    private ShopService shopService;

    @BeforeEach
    void setUp() {
        user = User.builder().userId(1).authUuid(authUuid).build();
        userRepository = mock(UserRepository.class);
        shopItemRepository = mock(UserShopItemRepository.class);
        coinService = mock(CoinService.class);
        shopService = new ShopService(userRepository, shopItemRepository, coinService);

        when(userRepository.findByAuthUuid(authUuid)).thenReturn(Optional.of(user));
        when(shopItemRepository.save(any(UserShopItem.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(shopItemRepository.findByUser(user)).thenReturn(List.of());
        when(shopItemRepository.findByUserAndItemTypeAndIsEquippedTrue(any(), anyString()))
                .thenReturn(List.of());
        when(coinService.getBalance(authUuid)).thenReturn(500);
    }

    @Test
    void purchaseUsesServerCatalogPrice() {
        when(shopItemRepository.findByUserAndItemKey(user, "room_forest"))
                .thenReturn(Optional.empty());
        when(coinService.spendCoins(authUuid, 150, "상점 구매: 초록 정원"))
                .thenReturn(true);

        var result = shopService.purchase(authUuid, "room_forest");

        verify(coinService).spendCoins(authUuid, 150, "상점 구매: 초록 정원");
        verify(shopItemRepository, atLeastOnce()).save(any(UserShopItem.class));
        assertEquals(500, result.balance());
    }

    @Test
    void insufficientBalanceDoesNotCreateInventoryItem() {
        when(shopItemRepository.findByUserAndItemKey(user, "room_night"))
                .thenReturn(Optional.empty());
        when(coinService.spendCoins(authUuid, 240, "상점 구매: 별빛 캠핑"))
                .thenReturn(false);

        assertThrows(
                IllegalStateException.class,
                () -> shopService.purchase(authUuid, "room_night")
        );
        verify(shopItemRepository, never()).save(any(UserShopItem.class));
    }
}
