-- NOTE: This file is auto generated by ./sql-generator

-- SearchRepository.searchMetadata
select
  "assets".*
from
  "assets"
  inner join "exif" on "assets"."id" = "exif"."assetId"
where
  "assets"."fileCreatedAt" >= $1
  and "exif"."lensModel" = $2
  and "assets"."ownerId" = any ($3::uuid [])
  and "assets"."isFavorite" = $4
  and "assets"."isArchived" = $5
  and "assets"."deletedAt" is null
order by
  "assets"."fileCreatedAt" desc
limit
  $6
offset
  $7

-- SearchRepository.searchRandom
(
  select
    "assets".*
  from
    "assets"
    inner join "exif" on "assets"."id" = "exif"."assetId"
  where
    "assets"."fileCreatedAt" >= $1
    and "exif"."lensModel" = $2
    and "assets"."ownerId" = any ($3::uuid [])
    and "assets"."isFavorite" = $4
    and "assets"."isArchived" = $5
    and "assets"."deletedAt" is null
    and "assets"."id" < $6
  order by
    "assets"."id"
  limit
    $7
)
union all
(
  select
    "assets".*
  from
    "assets"
    inner join "exif" on "assets"."id" = "exif"."assetId"
  where
    "assets"."fileCreatedAt" >= $8
    and "exif"."lensModel" = $9
    and "assets"."ownerId" = any ($10::uuid [])
    and "assets"."isFavorite" = $11
    and "assets"."isArchived" = $12
    and "assets"."deletedAt" is null
    and "assets"."id" > $13
  order by
    "assets"."id"
  limit
    $14
)
limit
  $15

-- SearchRepository.searchSmart
select
  "assets".*
from
  "assets"
  inner join "exif" on "assets"."id" = "exif"."assetId"
  inner join "smart_search" on "assets"."id" = "smart_search"."assetId"
where
  "assets"."fileCreatedAt" >= $1
  and "exif"."lensModel" = $2
  and "assets"."ownerId" = any ($3::uuid [])
  and "assets"."isFavorite" = $4
  and "assets"."isArchived" = $5
  and "assets"."deletedAt" is null
order by
  smart_search.embedding <= > $6
limit
  $7
offset
  $8

-- SearchRepository.searchDuplicates
with
  "cte" as (
    select
      "assets"."id" as "assetId",
      "assets"."duplicateId",
      smart_search.embedding <= > $1 as "distance"
    from
      "assets"
      inner join "smart_search" on "assets"."id" = "smart_search"."assetId"
    where
      "assets"."ownerId" = any ($2::uuid [])
      and "assets"."deletedAt" is null
      and "assets"."isVisible" = $3
      and "assets"."type" = $4
      and "assets"."id" != $5::uuid
    order by
      smart_search.embedding <= > $6
    limit
      $7
  )
select
  *
from
  "cte"
where
  "cte"."distance" <= $8

-- SearchRepository.searchFaces
with
  "cte" as (
    select
      "asset_faces"."id",
      "asset_faces"."personId",
      face_search.embedding <= > $1 as "distance"
    from
      "asset_faces"
      inner join "assets" on "assets"."id" = "asset_faces"."assetId"
      inner join "face_search" on "face_search"."faceId" = "asset_faces"."id"
    where
      "assets"."ownerId" = any ($2::uuid [])
      and "assets"."deletedAt" is null
    order by
      face_search.embedding <= > $3
    limit
      $4
  )
select
  *
from
  "cte"
where
  "cte"."distance" <= $5

-- SearchRepository.searchPlaces
select
  *
from
  "geodata_places"
where
  f_unaccent (name) %>> f_unaccent ($1)
  or f_unaccent ("admin2Name") %>> f_unaccent ($2)
  or f_unaccent ("admin1Name") %>> f_unaccent ($3)
  or f_unaccent ("alternateNames") %>> f_unaccent ($4)
order by
  coalesce(f_unaccent (name) <->>> f_unaccent ($5), 0.1) + coalesce(
    f_unaccent ("admin2Name") <->>> f_unaccent ($6),
    0.1
  ) + coalesce(
    f_unaccent ("admin1Name") <->>> f_unaccent ($7),
    0.1
  ) + coalesce(
    f_unaccent ("alternateNames") <->>> f_unaccent ($8),
    0.1
  )
limit
  $9

-- SearchRepository.getAssetsByCity
with recursive
  "cte" as (
    (
      select
        "city",
        "assetId"
      from
        "exif"
        inner join "assets" on "assets"."id" = "exif"."assetId"
      where
        "assets"."ownerId" = any ($1::uuid [])
        and "assets"."isVisible" = $2
        and "assets"."isArchived" = $3
        and "assets"."type" = $4
        and "assets"."deletedAt" is null
      order by
        "city"
      limit
        $5
    )
    union all
    (
      select
        "l"."city",
        "l"."assetId"
      from
        "cte"
        inner join lateral (
          select
            "city",
            "assetId"
          from
            "exif"
            inner join "assets" on "assets"."id" = "exif"."assetId"
          where
            "assets"."ownerId" = any ($6::uuid [])
            and "assets"."isVisible" = $7
            and "assets"."isArchived" = $8
            and "assets"."type" = $9
            and "assets"."deletedAt" is null
            and "exif"."city" > "cte"."city"
          order by
            "city"
          limit
            $10
        ) as "l" on true
    )
  )
select
  "assets".*,
  to_jsonb("exif") as "exifInfo"
from
  "assets"
  inner join "exif" on "assets"."id" = "exif"."assetId"
  inner join "cte" on "assets"."id" = "cte"."assetId"
order by
  "exif"."city"

-- SearchRepository.getStates
select distinct
  on ("state") "state"
from
  "exif"
  inner join "assets" on "assets"."id" = "exif"."assetId"
where
  "ownerId" = any ($1::uuid [])
  and "isVisible" = $2
  and "deletedAt" is null
  and "state" is not null

-- SearchRepository.getCities
select distinct
  on ("city") "city"
from
  "exif"
  inner join "assets" on "assets"."id" = "exif"."assetId"
where
  "ownerId" = any ($1::uuid [])
  and "isVisible" = $2
  and "deletedAt" is null
  and "city" is not null

-- SearchRepository.getCameraMakes
select distinct
  on ("make") "make"
from
  "exif"
  inner join "assets" on "assets"."id" = "exif"."assetId"
where
  "ownerId" = any ($1::uuid [])
  and "isVisible" = $2
  and "deletedAt" is null
  and "make" is not null

-- SearchRepository.getCameraModels
select distinct
  on ("model") "model"
from
  "exif"
  inner join "assets" on "assets"."id" = "exif"."assetId"
where
  "ownerId" = any ($1::uuid [])
  and "isVisible" = $2
  and "deletedAt" is null
  and "model" is not null
