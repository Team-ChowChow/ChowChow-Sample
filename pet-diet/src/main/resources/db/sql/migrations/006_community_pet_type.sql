-- Preserve the pet-type choice made while creating a community post.
ALTER TABLE "CommunityPosts"
    ADD COLUMN IF NOT EXISTS "petType" VARCHAR(3);

ALTER TABLE "CommunityPosts"
    DROP CONSTRAINT IF EXISTS "CommunityPosts_petType_check";

ALTER TABLE "CommunityPosts"
    ADD CONSTRAINT "CommunityPosts_petType_check"
    CHECK ("petType" IN ('DOG', 'CAT'));
