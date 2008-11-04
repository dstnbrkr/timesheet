CREATE TABLE `tasks` (
 `id` INTEGER PRIMARY KEY,
 `name` TEXT
);
CREATE TABLE `entries` (
 `id` INTEGER PRIMARY KEY,
 `task_id` INTEGER,
 `started_at` INTEGER,
 `stopped_at` INTEGER
);

