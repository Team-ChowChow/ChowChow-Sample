package com.petdiet.ingredient.dto;

import com.petdiet.ingredient.client.NaverShoppingClient.NaverProduct;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class LowestPriceResponse {
    private boolean found;
    private String productName;
    private Long price;
    private String imageUrl;
    private String productUrl;
    private String mallName;

    public static LowestPriceResponse notFound() {
        return LowestPriceResponse.builder().found(false).build();
    }

    public static LowestPriceResponse from(NaverProduct product) {
        return LowestPriceResponse.builder()
                .found(true)
                .productName(product.productName())
                .price(product.price())
                .imageUrl(product.imageUrl())
                .productUrl(product.productUrl())
                .mallName(product.mallName())
                .build();
    }
}
