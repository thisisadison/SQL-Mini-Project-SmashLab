-- The following contains the sample data used for testing of my database, sample queries and indexing choices.

-- Insert customers data
INSERT INTO "customers" ("first_name", "last_name", "contact_number", "start_date")
VALUES
('Seo', 'Seung Jae', 12345678, '2020-01-01'),
('Li', 'Shi Feng', 23456789, '2020-02-01'),
('Anthony', 'Ginting', 34567890, '2020-02-01'),
('Yuta', 'Watanabe', 45678901, '2020-03-01');

-- Insert staff data
INSERT INTO "staff" ("first_name", "last_name", "contact_number")
VALUES
('Jane', 'Doe', 98765432),
('John', 'Smith', 87654321),
('Bob', 'Stone', 76543210);

-- Insert orders data
INSERT INTO "orders" ("customer_id", "locker_id", "locker_password", "collection_status")
VALUES
(1, NULL, NULL, 'In-Store'),
(2, 4, 444444, 'In-Store'),
(3, 1, 000000, 'Ready For Collection'),
(4, 3, 333333, 'Collected');

-- Insert strings data
INSERT INTO "strings" ("brand", "name", "specification", "pros", "cons", "endorsed_players", "price")
VALUES
('Yonex', 'BG66 Ultimax', 'Gauge = 0.65 mm, Length = 10 m (33 ft) / 200 m (656 ft), Core = High-Intensity Nylon Multifilament, Outer = Special Braided High Polymer Nylon, Made In = Japan', 'Quick repulsion, Hitting Sound, Control, Shock Absorption', 'Durability', 'Lee Chong Wei, Taufik Hidayat, Huang Dong Ping, Li Shi Feng', 23.00),
('Yonex', 'BG80', 'Gauge = 0.68 mm, Length = 10 m (33 ft) / 200 m (656 ft), Core = High Polymer Nylon Multifilament with Vectran™, Outer = Special Braided Oval Shaped High Polymer Nylon, Made In = Japan', 'Repulsion, Hitting Sound', 'Durability, Control, Shock Absorption', 'Seo Seung Jae, An Se Young, Liang Wei Keng, Wang Chang', 23.00),
('Yonex', 'Aerobite', 'Gauge = mains - 0.67 mm; crosses - 0.61 mm, Length = 10.5m / mains-5.5m(18ft); crosses-5m(16ft);200m / mains-105m(344ft); crosses-95m(311ft), Core = mains - High-Intensity Nylon Multifilament;crosses - High-Intensity Nylon Multifilament, Outer = Special Braided High Polymer Nylon, Coating = Mains - Polyurethane Coating, Made In = Japan', 'Quick Repulsion, Control, Hitting Sound', 'Shock Absorption, Durability', 'Lin Dan, Kento Momota, Chen Qing Chen, Lee So Hee', 23.00),
('Li-Ning', 'No. 1', 'Core Material = Heat Resistant & High Intensity Nylon Multi-Filament, Outer Material = Heat Resistant & High Intensity Nylon', 'Hitting Sound, Repulsion, Control', 'Durability, Shock Absorption', 'Loh Kean Yew, Anthony Ginting, Yuta Watanabe, Jonatan Christie', 23.00),
('Victor', 'VBS66 Nano', 'Core = Nano-Technology-Based, Material = High-quality Nylon Multifilament, Thickness = 0.66mm', 'Durability, Repulsion, Hitting Sound', 'Control, Shock Absorption', 'Tai Tzu Ying, Hendra Setiawan, Lee Zii Jia, Wang Tzu Wei', 23.00);

-- Insert string_job data
INSERT INTO "string_job" ("customer_id", "staff_id", "order_id", "string_id", "string_colour", "string_tension", "comments", "job_cost", "job_status")
VALUES
(1, 1, 1, 2, 'White', 30, 'Yonex Nanoflare 700 Pro', 23.00, 'Pending'),
(1, 1, 1, 2, 'White', 30, 'Yonex Nanoflare 700 Pro', 23.00, 'Pending'),
(2, 2, 2, 1, 'White', 32, 'Yonex Astrox 100zz Kurenai', 23.00, 'Completed'),
(2, 2, 2, 1, 'White', 32, 'Yonex Astrox 100zz Kurenai', 23.00, 'Completed'),
(3, 2, 3, 4, 'White', 31, 'Li-Ning Axforce 100', 23.00, 'Completed'),
(3, 2, 3, 4, 'White', 31, 'Li-Ning Axforce 100', 23.00, 'Completed'),
(4, 3, 4, 4, 'White', 32, 'Li-Ning Halbertec 9000', 23.00, 'Completed'),
(4, 3, 4, 4, 'White', 32, 'Li-Ning Halbertec 9000', 23.00, 'Completed');
