package com.petdiet.llm.controller;

import com.petdiet.llm.dto.TipResponse;
import com.petdiet.llm.service.TipService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/llm")
@RequiredArgsConstructor
public class TipController {

    private final TipService tipService;

    @GetMapping("/tip")
    public ResponseEntity<TipResponse> getDailyTip() {
        return ResponseEntity.ok(tipService.getDailyTip());
    }
}
