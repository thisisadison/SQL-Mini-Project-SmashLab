-- Represent customers that have made transactions with the shop
CREATE TABLE "customers" (
    "id" INTEGER,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "contact_number" INTEGER NOT NULL UNIQUE,
    "start_date" NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY("id")
);

-- Represent staff of the shop that implements Smash Lab
CREATE TABLE "staff" (
    "id" INTEGER,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "contact_number" INTEGER NOT NULL UNIQUE,
    PRIMARY KEY("id")
);

-- Represent the badminton racket strings provided by the store.
CREATE TABLE "strings" (
    "id" INTEGER,
    "brand" TEXT NOT NULL,
    "name" TEXT NOT NULL UNIQUE,
    'specification' TEXT,
    "pros" TEXT,
    "cons" TEXT,
    "endorsed_players" TEXT,
    "price" NUMERIC NOT NULL,
    PRIMARY KEY("id")
);

-- Represent orders that the shop is to fulfill or has fulfilled
CREATE TABLE "orders" (
    "id" INTEGER,
    "customer_id" INTEGER,
    "locker_id" INTEGER,
    "locker_password" INTEGER,
    "collection_status" TEXT NOT NULL CHECK("collection_status" IN ('In-Store', 'Ready For Collection', 'Collected')) DEFAULT 'In-Store',
    PRIMARY KEY("id"),
    FOREIGN KEY("customer_id") REFERENCES "customers"("id")
);

-- Represent individual stringing jobs by the store
CREATE TABLE "string_job" (
    "id" INTEGER,
    "customer_id" INTEGER,
    "staff_id" INTEGER,
    "order_id" INTEGER,
    "string_id" INTEGER,
    "string_colour" TEXT CHECK("string_colour" IN ('White', 'Red', 'Yellow', 'Blue')),
    "string_tension" INTEGER NOT NULL CHECK("string_tension" BETWEEN 22 AND 34),
    "comments" TEXT NOT NULL,
    "job_cost" REAL NOT NULL,
    "job_status" TEXT NOT NULL CHECK("job_status" IN ('Pending', 'Completed')) DEFAULT 'Pending',
    PRIMARY KEY("id"),
    FOREIGN KEY("customer_id") REFERENCES "customers"("id"),
    FOREIGN KEY("staff_id") REFERENCES "staff"("id"),
    FOREIGN KEY("order_id") REFERENCES "orders"("id"),
    FOREIGN KEY("string_id") REFERENCES "strings"("id")
);

-- The following are indexes created to speed up Smash Lab's common queries.

CREATE INDEX "search_by_orderid" ON "string_job" ("order_id");
CREATE INDEX "search_by_jobstatus" ON "string_job" ("job_status");
CREATE INDEX "search_by_collectionstatus" ON "orders" ("collection_status");

