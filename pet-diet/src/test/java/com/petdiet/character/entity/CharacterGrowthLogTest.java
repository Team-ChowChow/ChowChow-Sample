package com.petdiet.character.entity;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class CharacterGrowthLogTest {

    @Test
    void activityStoresTheCurrentGrowthSnapshot() {
        PetCharacter character = mock(PetCharacter.class);
        when(character.getCurrentExp()).thenReturn(35);
        when(character.getCharacterLevel()).thenReturn(2);

        CharacterGrowthLog log = CharacterGrowthLog.activity(
                character, 14, "FEED", 20, "행복 +5, 배고픔 -30");

        assertEquals(35, log.getCurrentExp());
        assertEquals(2, log.getCurrentLevel());
        assertEquals(20, log.getExpGained());
    }
}
