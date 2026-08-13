package com.petdiet.pet.service;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.master.entity.Breed;
import com.petdiet.master.repository.BreedRepository;
import com.petdiet.pet.dto.PetRequest;
import com.petdiet.pet.dto.PetResponse;
import com.petdiet.pet.entity.PetAllergy;
import com.petdiet.pet.entity.PetDisease;
import com.petdiet.pet.entity.UserPet;
import com.petdiet.pet.repository.UserPetRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PetService {

    private final UserPetRepository userPetRepository;
    private final UserRepository userRepository;
    private final BreedRepository breedRepository;

    @Transactional(readOnly = true)
    public List<PetResponse> getMyPets(UUID authUuid) {
        User user = findUser(authUuid);
        return userPetRepository.findAllByUser(user).stream()
                .map(this::buildPetResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public PetResponse getPet(UUID authUuid, Integer petId) {
        User user = findUser(authUuid);
        UserPet pet = findPet(petId, user);
        return buildPetResponse(pet);
    }

    @Transactional
    public PetResponse createPet(UUID authUuid, PetRequest req) {
        User user = findUser(authUuid);
        UserPet pet = userPetRepository.save(UserPet.builder()
                .user(user)
                .petName(req.getPetName())
                .petType(req.getPetType())
                .breedId(req.getBreedId())
                .petGender(req.getPetGender())
                .petBirthdate(req.getPetBirthdate())
                .petWeight(req.getPetWeight())
                .isNeutered(req.getIsNeutered())
                .petProfileImg(req.getPetProfileImg())
                .petBodyConditionScore(req.getPetBodyConditionScore())
                .petBodyScoreDate(req.getPetBodyConditionScore() != null ? java.time.LocalDate.now() : null)
                .petActivityLevel(req.getPetActivityLevel())
                .healthFocusAreas(joinHealthFocusAreas(req.getHealthFocusAreas()))
                .build());

        addAllergies(pet, req.getAllergyIds());
        addDiseases(pet, req.getDiseaseIds());
        return PetResponse.from(userPetRepository.save(pet));
    }

    @Transactional
    public PetResponse updatePet(UUID authUuid, Integer petId, PetRequest req) {
        User user = findUser(authUuid);
        UserPet pet = findPet(petId, user);
        pet.update(req.getPetName(), req.getPetGender(), req.getPetBirthdate(),
                req.getPetWeight(), req.getIsNeutered(), req.getPetProfileImg(), req.getBreedId(),
                req.getPetBodyConditionScore(), req.getPetActivityLevel(),
                joinHealthFocusAreas(req.getHealthFocusAreas()));

        if (req.getAllergyIds() != null) {
            pet.getAllergies().clear();
            addAllergies(pet, req.getAllergyIds());
        }
        if (req.getDiseaseIds() != null) {
            pet.getDiseases().clear();
            addDiseases(pet, req.getDiseaseIds());
        }
        return PetResponse.from(userPetRepository.save(pet));
    }

    @Transactional
    public void deletePet(UUID authUuid, Integer petId) {
        User user = findUser(authUuid);
        UserPet pet = findPet(petId, user);
        userPetRepository.delete(pet);
    }

    private String joinHealthFocusAreas(List<String> areas) {
        if (areas == null) return null;
        if (areas.size() > 3) throw new IllegalArgumentException("관심 건강 부위는 최대 3개까지 선택할 수 있습니다.");
        return String.join(",", areas);
    }

    private void addAllergies(UserPet pet, List<Integer> allergyIds) {
        if (allergyIds == null) return;
        allergyIds.forEach(id -> pet.getAllergies().add(
                PetAllergy.builder().pet(pet).allergyId(id).build()));
    }

    private void addDiseases(UserPet pet, List<Integer> diseaseIds) {
        if (diseaseIds == null) return;
        diseaseIds.forEach(id -> pet.getDiseases().add(
                PetDisease.builder().pet(pet).diseaseId(id).build()));
    }

    private User findUser(UUID authUuid) {
        return userRepository.findByAuthUuid(authUuid)
                .orElseThrow(() -> new IllegalStateException("유저를 찾을 수 없습니다."));
    }

    private UserPet findPet(Integer petId, User user) {
        return userPetRepository.findByPetIdAndUser(petId, user)
                .orElseThrow(() -> new IllegalArgumentException("반려동물을 찾을 수 없습니다."));
    }

    private PetResponse buildPetResponse(UserPet pet) {
        PetResponse.PetResponseBuilder builder = PetResponse.builder()
                .petId(pet.getPetId())
                .userId(pet.getUser().getUserId())
                .petName(pet.getPetName())
                .petType(pet.getPetType())
                .breedId(pet.getBreedId())
                .petGender(pet.getPetGender())
                .petBirthdate(pet.getPetBirthdate())
                .petWeight(pet.getPetWeight())
                .petBodyConditionScore(pet.getPetBodyConditionScore())
                .petBodyScoreDate(pet.getPetBodyScoreDate())
                .petActivityLevel(pet.getPetActivityLevel())
                .isNeutered(pet.getIsNeutered())
                .petProfileImg(pet.getPetProfileImg())
                .petProfileImageUrl(pet.getPetProfileImg())
                .allergyIds(pet.getAllergies().stream().map(a -> a.getAllergyId()).toList())
                .diseaseIds(pet.getDiseases().stream().map(d -> d.getDiseaseId()).toList())
                .healthFocusAreas(pet.getHealthFocusAreas() == null || pet.getHealthFocusAreas().isBlank()
                        ? List.of()
                        : java.util.Arrays.stream(pet.getHealthFocusAreas().split(",")).map(String::trim).toList());

        if (pet.getBreedId() != null) {
            Optional<Breed> breed = breedRepository.findById(pet.getBreedId());
            if (breed.isPresent()) {
                builder.breedName(breed.get().getBreedName())
                        .groupName(breed.get().getGroupName());
            }
        }

        return builder.build();
    }
}
