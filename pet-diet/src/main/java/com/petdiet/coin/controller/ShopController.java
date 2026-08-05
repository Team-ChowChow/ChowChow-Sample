package com.petdiet.coin.controller;

import com.petdiet.coin.dto.ShopCatalogResponse;
import com.petdiet.coin.service.ShopService;
import com.petdiet.config.SupabasePrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/shop")
@RequiredArgsConstructor
public class ShopController {

    private final ShopService shopService;

    @GetMapping
    public ResponseEntity<ShopCatalogResponse> getCatalog(
            @AuthenticationPrincipal SupabasePrincipal principal) {
        return ResponseEntity.ok(shopService.getCatalog(principal.authUuid()));
    }

    @PostMapping("/{itemKey}/purchase")
    public ResponseEntity<ShopCatalogResponse> purchase(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable String itemKey) {
        return ResponseEntity.ok(shopService.purchase(principal.authUuid(), itemKey));
    }

    @PostMapping("/{itemKey}/equip")
    public ResponseEntity<ShopCatalogResponse> equip(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable String itemKey) {
        return ResponseEntity.ok(shopService.equip(principal.authUuid(), itemKey));
    }
}
