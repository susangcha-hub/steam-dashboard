Create database steam_analysis;
use steam_analysis;

DROP TABLE IF EXISTS games;

CREATE TABLE games (
    app_id INT PRIMARY KEY,
    name VARCHAR(500),
    release_date DATE,
    price DECIMAL(10,2),
    dlc_count INT,
    developers TEXT,
    publishers TEXT,
    categories TEXT,
    genres TEXT,
    windows TINYINT,
    mac TINYINT,
    linux TINYINT
)
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

DESCRIBE games;


DROP TABLE IF EXISTS metrics;
CREATE TABLE metrics (
	app_id INT PRIMARY KEY,
    estimated_owners VARCHAR(50),
    peak_ccu INT,
    user_score INT,
    positive INT,
    negative INT,
    recommendations INT,
    avg_playtime_forever INT,
    avg_playtime_two_weeks INT,
    median_playtime_forever INT,
    median_playtime_two_weeks INT,
    owners_min INT,
    owners_max INT,
    
    FOREIGN KEY (app_id) REFERENCES games(app_id)
    
);

CREATE TABLE game_genres (
    app_id INT,
    genre VARCHAR(100),
    PRIMARY KEY (app_id, genre),
    FOREIGN KEY (app_id) REFERENCES games(app_id)
)
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

CREATE TABLE game_categories (
    app_id INT,
    category VARCHAR(100),
    PRIMARY KEY (app_id, category),
    FOREIGN KEY (app_id) REFERENCES games(app_id)
)
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

ALTER TABLE game_categories
MODIFY app_id INT NOT NULL,
MODIFY category VARCHAR(100) NOT NULL;

SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'D:/Steam Market Analysis/01_Data/cleaned/games.csv'
INTO TABLE games
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE
'D:/Steam Market Analysis/01_Data/cleaned/metrics.csv'
INTO TABLE metrics
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'D:/Steam Market Analysis/01_Data/cleaned/game_genres.csv'
INTO TABLE game_genres
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'D:/Steam Market Analysis/01_Data/cleaned/game_categories.csv'
INTO TABLE game_categories
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- ----------------------------------------------------------------------------------------------------------

-- Additional Data cleaning, removing the extra spaces in genres and categories.
UPDATE game_genres
SET genre = TRIM(
    REPLACE(
        REPLACE(genre, CHAR(13), ''),
        CHAR(10), ''
    )
);

SELECT
    genre,
    LENGTH(genre) AS length
FROM game_genres
WHERE genre IN (
    'RPG',
    'Strategy',
    'Casual',
    'Simulation',
    'Massively Multiplayer'
);

SELECT
    gg.app_id,
    gg.genre,
    gc.category
FROM game_genres gg
JOIN game_categories gc
    ON gg.app_id = gc.app_id
WHERE gg.genre IN (
    'RPG',
    'Strategy',
    'Massively Multiplayer',
    'Simulation',
    'Casual'
)
LIMIT 20;

UPDATE game_categories
SET category = TRIM(
    REPLACE(
        REPLACE(category, CHAR(13), ''),
        CHAR(10), ''
    )
);
