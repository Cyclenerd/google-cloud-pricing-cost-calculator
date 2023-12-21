/*
 * Do mapping
 */

CREATE TEMPORARY TABLE IF NOT EXISTS "ordered_mapping" (
	"id"               INTEGER PRIMARY KEY AUTOINCREMENT,
	"MAPPING"          TEXT,
	"SVC_DISPLAY_NAME" TEXT,
	"FAMILY"           TEXT,
	"GROUP"            TEXT,
	"SKU_DESCRIPTION"  TEXT
);

INSERT INTO "ordered_mapping" ("MAPPING", "SVC_DISPLAY_NAME", "FAMILY", "GROUP", "SKU_DESCRIPTION")
	SELECT "MAPPING", "SVC_DISPLAY_NAME", "FAMILY", "GROUP", "SKU_DESCRIPTION"
	FROM "mapping";

CREATE INDEX IF NOT EXISTS "mapping_index" ON "skus" ("SVC_DISPLAY_NAME", "FAMILY", "GROUP", "SKU_DESCRIPTION");

CREATE TEMPORARY TABLE "ranked_mapping" AS
	SELECT
		s."rowid" AS "skus_rowid",
		m."MAPPING",
		ROW_NUMBER() OVER (
			PARTITION BY s."rowid"
			ORDER BY m."id" DESC
		) AS "rn"
	FROM "skus" s
	INNER JOIN "ordered_mapping" m ON
		s."SVC_DISPLAY_NAME" = m."SVC_DISPLAY_NAME"
		AND s."FAMILY" = m."FAMILY"
		AND s."GROUP" = m."GROUP"
		AND s."SKU_DESCRIPTION" LIKE m."SKU_DESCRIPTION"
	WHERE m."SVC_DISPLAY_NAME" IS NOT NULL;

UPDATE "skus"
SET "MAPPING" = (
	SELECT "MAPPING"
	FROM "ranked_mapping"
	WHERE
		"skus"."rowid" = "ranked_mapping"."skus_rowid"
		AND "ranked_mapping"."rn" = 1
);

CREATE INDEX IF NOT EXISTS "pricing_index" ON "skus" ("MAPPING", "REGIONS") WHERE "MAPPING" IS NOT NULL;
