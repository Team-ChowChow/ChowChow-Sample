package com.petdiet.character.service;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.character.dto.CharacterRequest;
import com.petdiet.character.dto.CharacterResponse;
import com.petdiet.character.dto.GrowthLogResponse;
import com.petdiet.character.entity.CharacterGrowthLog;
import com.petdiet.character.entity.PetCharacter;
import com.petdiet.character.repository.CharacterGrowthLogRepository;
import com.petdiet.character.repository.PetCharacterRepository;
import com.petdiet.master.entity.Breed;
import com.petdiet.master.repository.BreedRepository;
import com.petdiet.pet.entity.UserPet;
import com.petdiet.pet.repository.UserPetRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CharacterService {

    private final PetCharacterRepository characterRepository;
    private final CharacterGrowthLogRepository growthLogRepository;
    private final UserPetRepository userPetRepository;
    private final UserRepository userRepository;
    private final BreedRepository breedRepository;

    @Transactional(readOnly = true)
    public CharacterResponse getCharacter(UUID authUuid, Integer petId) {
        User user = findUser(authUuid);
        UserPet pet = findPet(petId, user);
        PetCharacter character = findByPet(pet);
        return toResponse(character);
    }

    @Transactional(readOnly = true)
    public List<CharacterResponse> getCharacters(UUID authUuid) {
        User user = findUser(authUuid);
        return characterRepository.findAllByPet_UserAndCharacterStatus(user, "ACTIVE").stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public CharacterResponse getCharacterById(UUID authUuid, Integer characterId) {
        PetCharacter character = findCharacter(characterId, authUuid);
        return toResponse(character);
    }

    @Transactional
    public CharacterResponse createCharacter(UUID authUuid, CharacterRequest req) {
        if (req.getCharacterName() == null || req.getCharacterName().isBlank()) {
            throw new IllegalArgumentException("캐릭터 이름이 필요합니다.");
        }
        User user = findUser(authUuid);
        UserPet pet;
        if (req.getPetId() != null) {
            pet = findPet(req.getPetId(), user);
            if (characterRepository.existsByPet(pet)) {
                throw new IllegalStateException("이미 캐릭터가 존재하는 반려동물입니다.");
            }
            if (req.getCharacterName() != null) pet.update(req.getCharacterName(), null, null, null, null, null, req.getBreedId());
            if (req.getPetType() != null && req.getBreedId() != null) {
                // pet type is immutable in entity - only update breed/name/image via update
            }
            if (req.getCharacterImageUrl() != null) {
                pet.update(null, null, null, null, null, req.getCharacterImageUrl(), null);
            }
            userPetRepository.save(pet);
        } else {
            if (req.getPetType() == null || req.getPetType().isBlank()) {
                throw new IllegalArgumentException("petType(DOG/CAT)이 필요합니다.");
            }
            pet = userPetRepository.save(UserPet.builder()
                    .user(user)
                    .petName(req.getCharacterName())
                    .petType(req.getPetType().toUpperCase())
                    .breedId(req.getBreedId())
                    .petProfileImg(req.getCharacterImageUrl())
                    .build());
        }

        String imageUrl = req.getCharacterImageUrl() != null && !req.getCharacterImageUrl().isBlank()
                ? req.getCharacterImageUrl()
                : (pet.getPetProfileImg() != null && !pet.getPetProfileImg().isBlank()
                        ? pet.getPetProfileImg()
                        : "https://placehold.co/200x200/png?text=Character");

        PetCharacter character = characterRepository.save(PetCharacter.builder()
                .pet(pet)
                .characterName(req.getCharacterName())
                .characterImageUrl(imageUrl)
                .description(req.getDescription())
                .build());

        return toResponse(character);
    }

    @Transactional
    public CharacterResponse updateCharacterName(UUID authUuid, Integer petId, String characterName) {
        UserPet pet = findPet(petId, findUser(authUuid));
        PetCharacter character = findByPet(pet);
        character.updateName(characterName);
        pet.update(characterName, null, null, null, null, null, null);
        userPetRepository.save(pet);
        return toResponse(characterRepository.save(character));
    }

    @Transactional
    public CharacterResponse gainExp(UUID authUuid, Integer petId, String activityType) {
        UserPet pet = findPet(petId, findUser(authUuid));
        return performActivityOnCharacter(findByPet(pet), findUser(authUuid), activityType);
    }

    @Transactional
    public CharacterResponse performActivity(UUID authUuid, Integer characterId, String activityType) {
        return performActivityOnCharacter(findCharacter(characterId, authUuid), findUser(authUuid), activityType);
    }

    private CharacterResponse performActivityOnCharacter(PetCharacter character, User user, String activityType) {
        RaisingActivity activity = RaisingActivity.from(activityType);
        int levelBefore = character.getCharacterLevel();
        String statusChanges = character.formatStatChanges(activity);
        boolean leveled = character.applyActivity(activity);

        growthLogRepository.save(CharacterGrowthLog.activity(
                character, user.getUserId(), activity.name(), activity.getExpGain(), statusChanges));

        if (leveled) {
            growthLogRepository.save(CharacterGrowthLog.activity(
                    character,
                    user.getUserId(),
                    "LEVEL_UP",
                    0,
                    "레벨 " + levelBefore + " -> 레벨 " + character.getCharacterLevel()));
        }

        characterRepository.save(character);
        return toResponse(character);
    }

    @Transactional(readOnly = true)
    public List<GrowthLogResponse> getGrowthLogs(UUID authUuid, Integer petId) {
        UserPet pet = findPet(petId, findUser(authUuid));
        return mapLogs(findByPet(pet), null);
    }

    @Transactional(readOnly = true)
    public List<GrowthLogResponse> getGrowthLogsByCharacterId(UUID authUuid, Integer characterId, String filter) {
        PetCharacter character = findCharacter(characterId, authUuid);
        return mapLogs(character, filter);
    }

    @Transactional
    public CharacterResponse updateCharacter(UUID authUuid, Integer characterId, CharacterRequest request) {
        PetCharacter character = findCharacter(characterId, authUuid);
        UserPet pet = character.getPet();

        character.updateMeta(
                request.getCharacterName(),
                request.getCharacterImageUrl(),
                request.getDescription(),
                null);

        if (request.getCharacterName() != null || request.getBreedId() != null || request.getCharacterImageUrl() != null) {
            pet.update(
                    request.getCharacterName(),
                    null,
                    null,
                    null,
                    null,
                    request.getCharacterImageUrl(),
                    request.getBreedId());
            userPetRepository.save(pet);
        }

        return toResponse(characterRepository.save(character));
    }

    @Transactional
    public void deleteCharacter(UUID authUuid, Integer characterId) {
        PetCharacter character = findCharacter(characterId, authUuid);
        UserPet pet = character.getPet();
        characterRepository.delete(character);
        userPetRepository.delete(pet);
    }

    private List<GrowthLogResponse> mapLogs(PetCharacter character, String filter) {
        List<CharacterGrowthLog> logs;
        if (filter == null || filter.isBlank() || "ALL".equalsIgnoreCase(filter)) {
            logs = growthLogRepository.findAllByCharacterOrderByCreatedAtDesc(character);
        } else {
            String type = filter.toUpperCase();
            logs = growthLogRepository.findAllByCharacterAndActivityTypeOrderByCreatedAtDesc(character, type);
        }
        return logs.stream().map(GrowthLogResponse::from).toList();
    }

    private CharacterResponse toResponse(PetCharacter character) {
        Breed breed = null;
        if (character.getPet().getBreedId() != null) {
            breed = breedRepository.findById(character.getPet().getBreedId()).orElse(null);
        }
        return CharacterResponse.from(character, breed);
    }

    private User findUser(UUID authUuid) {
        return userRepository.findByAuthUuid(authUuid)
                .orElseThrow(() -> new IllegalStateException("유저를 찾을 수 없습니다."));
    }

    private UserPet findPet(Integer petId, User user) {
        return userPetRepository.findByPetIdAndUser(petId, user)
                .orElseThrow(() -> new IllegalArgumentException("반려동물을 찾을 수 없습니다."));
    }

    private PetCharacter findByPet(UserPet pet) {
        return characterRepository.findByPet(pet)
                .orElseThrow(() -> new IllegalArgumentException("캐릭터를 찾을 수 없습니다."));
    }

    private PetCharacter findCharacter(Integer characterId, UUID authUuid) {
        User user = findUser(authUuid);
        return characterRepository.findByCharacterIdAndPet_User(characterId, user)
                .filter(c -> "ACTIVE".equals(c.getCharacterStatus()))
                .orElseThrow(() -> new IllegalArgumentException("캐릭터를 찾을 수 없습니다."));
    }
}
