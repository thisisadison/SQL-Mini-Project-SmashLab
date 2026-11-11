-- The following are a series of queries which I believe will be of high usage amidst the operability of Smash Lab.

-- Check for which locker is currently in use
SELECT "locker_id", "collection_status" FROM "orders"
WHERE "collection_status" = 'Ready For Collection';

-- Check for which locker can be reclaimed
SELECT "locker_id", "collection_status" FROM "orders"
WHERE "collection_status" = 'Collected';

-- Check for which order can have their `collection_status` attribute updated from "In-Store" to "Ready For Collection" once all of its jobs are completed
SELECT "o"."id" AS "order_id" FROM "orders" AS "o"
WHERE "o"."collection_status" = 'In-Store'
AND NOT EXISTS (
    SELECT 1 FROM "string_job" AS "j"
    WHERE "j"."order_id" = "o"."id" AND "j"."job_status" = 'Pending'
);

-- Check for which order can have their current workload or job queue to be fulfilled
SELECT "o"."id" AS "order_id", "j"."id" AS "job_id", "j"."job_status" FROM "string_job" AS "j"
INNER JOIN "orders" AS "o" ON "j"."order_id" = "o"."id"
WHERE "o"."collection_status" = 'In-Store' AND "j"."job_status" = 'Pending';

-- Check for the specifications of a string job by "order_id"
SELECT "s"."id" AS "string_id", "s"."name" AS "string_name", "j"."string_colour", "j"."string_tension", "j"."comments" FROM "string_job" AS "j"
INNER JOIN "strings" AS "s" ON "j"."string_id" = "s"."id"
WHERE "j"."order_id" = 2;

-- Check for the total order cost
SELECT "o"."id" AS "order_id", SUM("j"."job_cost") AS "job_cost" FROM "string_job" AS "j"
INNER JOIN "orders" AS "o" ON "j"."order_id" = "o"."id"
WHERE "j"."order_id" = 3
GROUP BY "o"."id";

-- Check for the cost breakdown for a certain order
SELECT "j"."order_id", "s"."brand", "s"."name", "j"."job_cost" FROM "string_job" AS "j"
INNER JOIN "strings" AS "s" ON "j"."string_id" = "s"."id"
WHERE "j"."order_id" = 3;
