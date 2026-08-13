-- Replace the deprecated disease-information category with recipe.
UPDATE "CommunityPosts"
SET "postCategory" = '자유'
WHERE "postCategory" = '질환정보';

ALTER TABLE "CommunityPosts"
    ALTER COLUMN "petId" DROP NOT NULL,
    ALTER COLUMN "recipeId" DROP NOT NULL;

ALTER TABLE "CommunityPosts"
    DROP CONSTRAINT IF EXISTS "CommunityPosts_postCategory_check";

ALTER TABLE "CommunityPosts"
    ADD CONSTRAINT "CommunityPosts_postCategory_check"
    CHECK ("postCategory" IN ('자유', '후기', '질문', '레시피'));
