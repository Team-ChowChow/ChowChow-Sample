package com.petdiet.master.repository;

import com.petdiet.master.entity.Breed;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface BreedRepository extends JpaRepository<Breed, Integer> {

    List<Breed> findByBreedNameKoIsNull(Pageable pageable);

    @Query("SELECT b FROM Breed b WHERE " +
           "(:petType IS NULL OR b.petType = :petType) AND " +
           "(LOWER(b.breedName) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
           "b.breedNameKo LIKE CONCAT('%', :keyword, '%'))" +
           " ORDER BY b.breedName")
    List<Breed> searchByKeyword(@Param("keyword") String keyword, @Param("petType") String petType);

    List<Breed> findByPetTypeOrderByBreedName(String petType);
}
