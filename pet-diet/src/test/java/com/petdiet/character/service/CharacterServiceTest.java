package com.petdiet.character.service;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.character.entity.CharacterGrowthLog;
import com.petdiet.character.entity.PetCharacter;
import com.petdiet.character.repository.CharacterGrowthLogRepository;
import com.petdiet.character.repository.PetCharacterRepository;
import com.petdiet.coin.service.CoinService;
import com.petdiet.master.repository.BreedRepository;
import com.petdiet.pet.repository.UserPetRepository;
import org.junit.jupiter.api.Test;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

class CharacterServiceTest {

    @Test
    void feedCannotRunAgainBeforeThreeHourCooldownExpires() {
        UUID authUuid = UUID.randomUUID();
        User user = User.builder().userId(1).authUuid(authUuid).build();
        PetCharacter character = mock(PetCharacter.class);
        CharacterGrowthLog lastFeed = mock(CharacterGrowthLog.class);
        PetCharacterRepository characterRepository = mock(PetCharacterRepository.class);
        CharacterGrowthLogRepository growthLogRepository = mock(CharacterGrowthLogRepository.class);
        UserPetRepository userPetRepository = mock(UserPetRepository.class);
        UserRepository userRepository = mock(UserRepository.class);
        BreedRepository breedRepository = mock(BreedRepository.class);
        CoinService coinService = mock(CoinService.class);
        CharacterService service = new CharacterService(
                characterRepository,
                growthLogRepository,
                userPetRepository,
                userRepository,
                breedRepository,
                coinService);

        when(userRepository.findByAuthUuid(authUuid)).thenReturn(Optional.of(user));
        when(characterRepository.findByCharacterIdAndPet_User(7, user))
                .thenReturn(Optional.of(character));
        when(character.getCharacterStatus()).thenReturn("ACTIVE");
        when(growthLogRepository
                .findFirstByCharacterAndActivityTypeOrderByCreatedAtDesc(character, "FEED"))
                .thenReturn(Optional.of(lastFeed));
        when(lastFeed.getCreatedAt()).thenReturn(OffsetDateTime.now().minusHours(2));

        assertThrows(
                IllegalStateException.class,
                () -> service.performActivity(authUuid, 7, "FEED"));
        verify(character, never()).applyActivity(any());
        verify(growthLogRepository, never()).save(any());
    }

    @Test
    void paidActivityDoesNotRunWhenCoinsAreInsufficient() {
        UUID authUuid = UUID.randomUUID();
        User user = User.builder().userId(1).authUuid(authUuid).build();
        PetCharacter character = mock(PetCharacter.class);
        PetCharacterRepository characterRepository = mock(PetCharacterRepository.class);
        CharacterGrowthLogRepository growthLogRepository = mock(CharacterGrowthLogRepository.class);
        UserPetRepository userPetRepository = mock(UserPetRepository.class);
        UserRepository userRepository = mock(UserRepository.class);
        BreedRepository breedRepository = mock(BreedRepository.class);
        CoinService coinService = mock(CoinService.class);
        CharacterService service = new CharacterService(
                characterRepository,
                growthLogRepository,
                userPetRepository,
                userRepository,
                breedRepository,
                coinService);

        when(userRepository.findByAuthUuid(authUuid)).thenReturn(Optional.of(user));
        when(characterRepository.findByCharacterIdAndPet_User(7, user))
                .thenReturn(Optional.of(character));
        when(character.getCharacterStatus()).thenReturn("ACTIVE");
        when(coinService.spendCoins(
                authUuid,
                CoinService.ACTIVITY_EXERCISE_COST,
                "운동하기 활동"))
                .thenReturn(false);

        assertThrows(
                IllegalStateException.class,
                () -> service.performActivity(authUuid, 7, "EXERCISE"));
        verify(character, never()).applyActivity(any());
        verify(growthLogRepository, never()).save(any());
    }
}
