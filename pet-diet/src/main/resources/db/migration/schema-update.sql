ALTER TABLE "Breeds" ADD COLUMN IF NOT EXISTS "breedNameKo" VARCHAR(100);

-- 어드민 시드 레시피는 특정 유저/펫 없이 삽입 가능하도록 nullable 허용
ALTER TABLE "Recipes" ALTER COLUMN "userId" DROP NOT NULL;
ALTER TABLE "Recipes" ALTER COLUMN "petId" DROP NOT NULL;
