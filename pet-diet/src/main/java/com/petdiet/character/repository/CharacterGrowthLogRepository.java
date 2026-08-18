package com.petdiet.character.repository;

import com.petdiet.character.entity.CharacterGrowthLog;
import com.petdiet.character.entity.PetCharacter;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.time.OffsetDateTime;

public interface CharacterGrowthLogRepository extends JpaRepository<CharacterGrowthLog, Integer> {

    List<CharacterGrowthLog> findAllByCharacterOrderByCreatedAtDesc(PetCharacter character);

    List<CharacterGrowthLog> findAllByCharacterAndActivityTypeOrderByCreatedAtDesc(
            PetCharacter character, String activityType);

    long countByUserIdAndActivityTypeAndCreatedAtGreaterThanEqualAndCreatedAtLessThan(
            Integer userId, String activityType, OffsetDateTime from, OffsetDateTime to);
}
