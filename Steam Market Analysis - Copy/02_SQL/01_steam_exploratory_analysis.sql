-- =====================================================
-- 1. MARKET OVERVIEW
-- =====================================================

-- How many games are represented?
SELECT COUNT(*) as total_games
FROM games;

-- ----------------------------------------------------------------------------------------------------------
-- What is the average price?
SELECT ROUND(AVG(price), 2) AS avg_price
FROM games
WHERE price > 0;

-- ----------------------------------------------------------------------------------------------------------
-- What percentage are free vs. paid?
SELECT
	CASE
		WHEN price = 0 THEN 'free'
        ELSE 'paid'
	END as price_type,
    COUNT(*) as game_count,
    ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM games), 2) as percentage
FROM games
GROUP BY price_type;

-- ----------------------------------------------------------------------------------------------------------
-- How have releases changed over time?
SELECT
	YEAR(release_date) as release_year,
    COUNT(*) as games_released
FROM games
GROUP BY release_year
ORDER BY release_year DESC;

-- ----------------------------------------------------------------------------------------------------------
-- What percentage support each operating system?
SELECT
    ROUND(SUM(windows) * 100.0 / COUNT(*), 2) AS windows_pct,
    ROUND(SUM(mac) * 100.0 / COUNT(*), 2) AS mac_pct,
    ROUND(SUM(linux) * 100.0 / COUNT(*), 2) AS linux_pct,
    ROUND(
        SUM(CASE
            WHEN windows = 1
             AND mac = 1
             AND linux = 1
            THEN 1
            ELSE 0
        END) * 100.0 / COUNT(*),
        2
    ) AS all_platforms_pct
FROM games;

-- ----------------------------------------------------------------------------------------------------------
-- KEY FINDINGS:
-- The dataset contains 125855 total games.
-- The average price of a paid game is $6.10, excluding free-to-play titles.
-- 78.82% of games are paid, while 21.18% are free-to-play.
-- Game releases have increased over time, with 2025 having the highest number of releases at 24973 games.
-- Windows dominates platform support, with 99% of games supporting Windows.
	-- Mac and Linux support are considerably less common, at 17.26% and 12.77%, respectively.
-- Only 9.16% of games support all three operating systems (Windows, Mac, and Linux), 
	-- indicating that cross-platform support is relatively uncommon compared with Windows-only availability.


-- =====================================================
-- 2. MARKET REACH ANALYSIS
-- =====================================================

-- What percentage of Steam games fall into each market-reach category?

WITH game_distribution as (
	SELECT
		CASE
		WHEN estimated_owners = '0 - 0'
			THEN 'no data'
		WHEN estimated_owners = '0 - 20000'
			THEN 'Under 20K Owners'
		WHEN estimated_owners IN ('20000 - 50000', '50000 - 100000')
			THEN '20K–100K Owners'
		WHEN estimated_owners IN ('100000 - 200000', '200000 - 500000')
			THEN '100K–500K Owners'
		WHEN estimated_owners = '500000 - 1000000'
			THEN '500K–1M Owners'
		ELSE '1M+ Owners'
		END AS market_reach,
		COUNT(DISTINCT app_id) AS total_games
	FROM metrics
	GROUP BY market_reach
	ORDER BY total_games
)
SELECT
    market_reach,
    total_games,
    ROUND(total_games / SUM(total_games) OVER () * 100, 2) as percentage_of_market
FROM game_distribution
WHERE market_reach <> 'no data'
;
-- 24,579 games were excluded from the market-reach analysis because they had no usable estimated ownership data (0 - 0).
-- Of games with usable ownership data, 74.75% have fewer than 20K estimated owners, making this by far the most common ownership range.
-- 16.54% fall between 20K–100K owners, while 6.23% fall between 100K–500K owners.
-- Games reaching higher ownership ranges are relatively uncommon: 1.14% fall between 500K–1M owners, and 1.34% exceed 1M owners.
-- Overall, the distribution is heavily concentrated in the lower ownership ranges, providing a Steam-wide baseline for comparing the market reach of individual genres.

-- ----------------------------------------------------------------------------------------------------------

-- What percentage of Steam games fall into each market-reach category by genre?
WITH genre_market_reach AS (
	SELECT 
		gg.genre,
        COUNT(DISTINCT(gg.app_id)) as game_count,
        CASE
		WHEN m.estimated_owners = '0 - 20000'
			THEN 'Under 20K Owners'
		WHEN m.estimated_owners IN ('20000 - 50000', '50000 - 100000')
			THEN '20K–100K Owners'
		WHEN m.estimated_owners IN ('100000 - 200000', '200000 - 500000')
			THEN '100K–500K Owners'
		WHEN m.estimated_owners = '500000 - 1000000'
			THEN '500K–1M Owners'
		ELSE '1M+ Owners'
		END AS market_reach
	FROM game_genres gg
    JOIN metrics m
		ON gg.app_id = m.app_id
	WHERE estimated_owners <> '0 - 0'
	GROUP BY
    genre,
    market_reach
)

SELECT
	genre,
    game_count,
    market_reach,
    ROUND(game_count / SUM(game_count) OVER(PARTITION BY genre) * 100, 2) as percentage_of_genre 
FROM genre_market_reach
;
-- KEY FINDINGS:
-- To compare market reach across genres fairly, I calculated the percentage of games within each genre that fall into each estimated ownership range.
-- Games without usable ownership estimates (0 - 0) were excluded. Because genres vary significantly in size, percentages were used instead of raw game counts.
-- This allows each genre's ownership distribution to be compared against the overall Steam market baseline.
-- Calculation: Games in each ownership range ÷ total games within the genre × 100.
	
-- ----------------------------------------------------------------------------------------------------------

-- How does each genre's ownership distribution differ from the overall Steam baseline? 
   
WITH steam_baseline AS (
    SELECT
        market_reach,
        total_games,
        ROUND(total_games / SUM(total_games) OVER () * 100, 2) AS steam_percentage
    FROM (
        SELECT
            CASE
                WHEN estimated_owners = '0 - 20000'
                    THEN 'Under 20K Owners'
                WHEN estimated_owners IN ('20000 - 50000', '50000 - 100000')
                    THEN '20K–100K Owners'
                WHEN estimated_owners IN ('100000 - 200000', '200000 - 500000')
                    THEN '100K–500K Owners'
                WHEN estimated_owners = '500000 - 1000000'
                    THEN '500K–1M Owners'
                ELSE '1M+ Owners'
            END AS market_reach,
            COUNT(DISTINCT app_id) AS total_games
        FROM metrics
        WHERE estimated_owners <> '0 - 0'
        GROUP BY market_reach
    ) baseline_counts
),

genre_market_reach AS (
    SELECT
        gg.genre,
        CASE
            WHEN m.estimated_owners = '0 - 20000'
                THEN 'Under 20K Owners'
            WHEN m.estimated_owners IN ('20000 - 50000', '50000 - 100000')
                THEN '20K–100K Owners'
            WHEN m.estimated_owners IN ('100000 - 200000', '200000 - 500000')
                THEN '100K–500K Owners'
            WHEN m.estimated_owners = '500000 - 1000000'
                THEN '500K–1M Owners'
            ELSE '1M+ Owners'
        END AS market_reach,
        COUNT(DISTINCT gg.app_id) AS game_count
    FROM game_genres gg
    JOIN metrics m
        ON gg.app_id = m.app_id
    WHERE m.estimated_owners <> '0 - 0'
    GROUP BY
        gg.genre,
        market_reach
),

genre_distribution AS (
    SELECT
        genre,
        market_reach,
        game_count,
        SUM(game_count) OVER (PARTITION BY genre) AS total_genre_games,
        ROUND(game_count / SUM(game_count) OVER (PARTITION BY genre) * 100, 2) AS genre_percentage
    FROM genre_market_reach
)

SELECT
    gd.genre,
    gd.market_reach,
    gd.game_count,
    gd.total_genre_games,
    gd.genre_percentage,
    sb.steam_percentage,
    ROUND(gd.genre_percentage - sb.steam_percentage, 2) AS market_reach_difference
FROM genre_distribution gd
JOIN steam_baseline sb
    ON gd.market_reach = sb.market_reach
WHERE gd.total_genre_games >= 100
ORDER BY
    gd.genre,
    gd.market_reach
;
-- KEY FINDINGS:
-- 'Free To Play' and 'Massively Multiplayer' show the strongest market reach, with substantially fewer games in the Under-20K tier 
-- and greater representation in higher ownership tiers than the Steam baseline.
-- 'RPG' and 'Strategy' also trend toward higher ownership ranges, though less dramatically.
-- High player reception does NOT necessarily translate to greater market reach. For example:
-- 'Casual' ranked highly in reception but had a larger share of games under 20K owners than the Steam baseline.
-- ----------------------------------------------------------------------------------------------------------


-- =====================================================
-- 3. PLAYER RECEPTION ANALYSIS
-- =====================================================

-- How did players respond?
SELECT
    COUNT(*) AS total_games,
    SUM(positive = 0 AND negative = 0) AS no_review_data,
    SUM(recommendations = 0) AS zero_recommendations
FROM metrics
;
-- KEY FINDINGS:
-- 42,899 games have no positive or negative review data.
-- Recommendations were excluded because approximately 83% of games
-- have a value of 0, making the metric too sparse for this analysis.
-- ----------------------------------------------------------------------------------------------------------

SELECT
    CASE
        WHEN positive + negative = 0 THEN 'No Reviews'
        WHEN positive + negative BETWEEN 1 AND 9 THEN '1-9'
        WHEN positive + negative BETWEEN 10 AND 49 THEN '10-49'
        WHEN positive + negative BETWEEN 50 AND 99 THEN '50-99'
        WHEN positive + negative BETWEEN 100 AND 499 THEN '100-499'
        WHEN positive + negative BETWEEN 500 AND 999 THEN '500-999'
        WHEN positive + negative BETWEEN 1000 AND 4999 THEN '1K-5K'
        WHEN positive + negative BETWEEN 5000 AND 9999 THEN '5K-10K'
        ELSE '10K+'
    END AS review_volume,
    COUNT(*) AS game_count
FROM metrics
GROUP BY review_volume
ORDER BY MIN(positive + negative)
;
-- KEY FINDINGS:
-- Review counts were highly skewed, and many games had little or no review activity. 
-- Games with fewer than 10 total reviews were excluded from the reception analysis 
-- to reduce the influence of extremely small samples while retaining broad market coverage.
-- ----------------------------------------------------------------------------------------------------------

SELECT
    app_id,
    positive + negative AS total_reviews,
    ROUND(
        positive * 100.0 / (positive + negative),
        2
    ) AS positive_review_percentage
FROM metrics
WHERE positive + negative >= 10
ORDER BY positive_review_percentage DESC
;
-- KEY FINDINGS:
-- Player reception was measured using the percentage of positive reviews:
-- Positive Review % = Positive Reviews ÷ Total Reviews × 100
-- After applying the 10-review minimum, 56,662 games were eligible.

-- ----------------------------------------------------------------------------------------------------------

-- For games with at least 10 reviews, which genres have the highest average positive-review percentage?
WITH genre_reception AS (
    SELECT
        gg.genre,
        COUNT(DISTINCT m.app_id) AS games_analyzed,
        ROUND(AVG(
                m.positive * 100.0 / (m.positive + m.negative)),2) 
            AS avg_positive_review_percentage
    FROM metrics m
    JOIN game_genres gg
        ON m.app_id = gg.app_id
    WHERE m.positive + m.negative >= 10
    GROUP BY gg.genre
)

SELECT
    genre,
    games_analyzed,
    avg_positive_review_percentage,
    RANK() OVER (
        ORDER BY avg_positive_review_percentage DESC
    ) AS reception_rank
FROM genre_reception
ORDER BY reception_rank
;
-- KEY FINDINGS:
-- Casual, Indie, and Adventure ranked highest in average positive-review percentage; however, 
-- differences between the leading genres were relatively small. 
-- For example, Casual ranked #1 at 77.96%, while RPG ranked #5 at 76.61%, a difference of only 1.35 percentage points.
-- ----------------------------------------------------------------------------------------------------------


-- =====================================================
-- 4. GENRE COMPETITION & RELEASE TRENDS
-- =====================================================

-- What does the saturation distribution look like?
WITH genre_saturation AS (
	SELECT
	genre,
	COUNT(DISTINCT app_id) as total_games
FROM game_genres
GROUP BY genre
),
genre_reception AS (
    SELECT
        gg.genre,
        COUNT(DISTINCT m.app_id) AS games_analyzed,
        ROUND(AVG(
                m.positive * 100.0 / (m.positive + m.negative)),2) 
            AS avg_positive_review_percentage
    FROM metrics m
    JOIN game_genres gg
        ON m.app_id = gg.app_id
    WHERE m.positive + m.negative >= 10
    GROUP BY gg.genre
)
SELECT
    gr.genre,
    gr.games_analyzed,
    gr.avg_positive_review_percentage,
    RANK() OVER (
        ORDER BY avg_positive_review_percentage DESC
    ) AS reception_rank,
    gs.total_games,
    ROUND(gr.games_analyzed / gs.total_games * 100, 2) as percentage_analyzed
FROM genre_reception gr
JOIN genre_saturation gs
	ON gr.genre = gs.genre
WHERE games_analyzed >= 100
ORDER BY reception_rank
;
-- KEY FINDINGS:
-- Indie is the most saturated genre with 82,884 games.
-- High saturation does not necessarily mean poor reception.
-- Game Development stands out with low competition and 77.03% positive reviews.
-- Massively Multiplayer, Gore, and Violent show relatively weaker reception.
-- ----------------------------------------------------------------------------------------------------------

-- What are the Top 3 genres with the most amount of releases per year?
WITH release_trend AS (
	SELECT 
		YEAR(g.release_date) as release_year,
		gg.genre as genre,
		COUNT(DISTINCT(g.app_id)) as total_games
	FROM games g
	JOIN game_genres gg
		ON g.app_id = gg.app_id
	GROUP BY 
		gg.genre,
		release_year
)
SELECT *
FROM ( 
	SELECT
        release_year,
		genre,
        total_games,
		RANK() OVER(
			PARTITION BY release_year
			ORDER BY total_games DESC
			)
			AS ranking
            FROM release_trend
            ) as ranking
WHERE ranking <= 3
;
-- KEY FINDINGS:
-- 'Action', 'Indie', and 'Casual' were the most consistently dominant genres, 
-- appearing among the top three genres for annual releases 25, 21, and 16 times, respectively.

-- ----------------------------------------------------------------------------------------------------------

-- Which genres experienced the largest growth or decline in releases from 2021 to 2025?
WITH release_trend AS (
    SELECT 
        YEAR(g.release_date) AS release_year,
        gg.genre,
        COUNT(DISTINCT g.app_id) AS total_games
    FROM games g
    JOIN game_genres gg
        ON g.app_id = gg.app_id
    WHERE YEAR(g.release_date) BETWEEN 2021 AND 2025
    GROUP BY 
        gg.genre,
        release_year
),

five_year_release AS (
    SELECT
        genre,
        SUM(CASE
            WHEN release_year = 2021 THEN total_games
            ELSE 0
        END) AS 2021_total_games,
        SUM(CASE
            WHEN release_year = 2025 THEN total_games
            ELSE 0
        END) AS 2025_total_games
    FROM release_trend
    GROUP BY genre
)

SELECT
    genre,
    2021_total_games,
    2025_total_games,
    2025_total_games - 2021_total_games AS absolute_growth,

    ROUND(
        (2025_total_games - 2021_total_games) 
        / 2021_total_games * 100,
        2
    ) AS percentage_growth,

    CASE
        WHEN 2025_total_games > 2021_total_games THEN 'Growing'
        WHEN 2025_total_games < 2021_total_games THEN 'Shrinking'
        ELSE 'No Change'
    END AS release_trend

FROM five_year_release
ORDER BY absolute_growth DESC
;
-- KEY FINDINGS:
-- 'Indie' experienced the largest absolute increase in releases from 2021 to 2025, adding 8,036 games. 
-- 'Casual' followed with 5,326 additional releases, while 'Adventure', 'Action', and 'Simulation' also experienced substantial growth.
-- 'Free To Play' grew the fastest proportionally at 216.86%, followed by 'Early Access' at 172.23% and 'Simulation' at 156.57%.

-- ----------------------------------------------------------------------------------------------------------
-- =========================================================
-- 5. CATEGORY EXPLORATION & ANALYSIS
-- =========================================================

SELECT
    COUNT(DISTINCT category) AS total_categories
FROM game_categories;

-- ----------------------------------------------------------------------------------------------------------

SELECT
    gc.category,
    COUNT(DISTINCT gc.app_id) AS total_games,
    ROUND(
        COUNT(DISTINCT gc.app_id) * 100.0 /
        (SELECT COUNT(DISTINCT app_id) FROM games),
        2
    ) AS percentage_of_games
FROM game_categories gc
GROUP BY gc.category
ORDER BY total_games DESC;

-- KEY FINDINGS:
-- 59 total categories
-- 'Single-player' makes up 88.26% of the games with 'Family-Sharing' at 78.42%.
-- Percentages do NOT add up to 100% as the games can have multiple categories.

-- ----------------------------------------------------------------------------------------------------------
-- =====================================================
-- 6. PLAYER ENGAGEMENT ANALYSIS
-- =====================================================

-- How is player engagement distributed and can it be measured?
SELECT
    MIN(peak_ccu),
    MAX(peak_ccu),
    AVG(peak_ccu)
FROM metrics
WHERE estimated_owners <> '0 - 0';

SELECT
    CASE
        WHEN peak_ccu = 0 THEN '0'
        WHEN peak_ccu BETWEEN 1 AND 10 THEN '1-10'
        WHEN peak_ccu BETWEEN 11 AND 50 THEN '11-50'
        WHEN peak_ccu BETWEEN 51 AND 100 THEN '51-100'
        WHEN peak_ccu BETWEEN 101 AND 500 THEN '101-500'
        WHEN peak_ccu BETWEEN 501 AND 1000 THEN '501-1K'
        WHEN peak_ccu BETWEEN 1001 AND 5000 THEN '1K-5K'
        WHEN peak_ccu BETWEEN 5001 AND 10000 THEN '5K-10K'
        ELSE '10K+'
    END AS ccu_range,
    COUNT(*) AS game_count,
    estimated_owners
FROM metrics
WHERE estimated_owners <> '0 - 0'
GROUP BY ccu_range, estimated_owners
ORDER BY MIN(peak_ccu)
;

SELECT
    COUNT(*) AS total_games,
    SUM(median_playtime_forever = 0) AS zero_lifetime,
    SUM(median_playtime_two_weeks = 0) AS zero_recent
FROM metrics
WHERE estimated_owners = '0 - 0'
;

SELECT
    CASE
        WHEN peak_ccu > 0 AND median_playtime_forever > 0
            THEN 'Both Metrics Available'
        WHEN peak_ccu > 0 AND median_playtime_forever = 0
            THEN 'CCU Only'
        WHEN peak_ccu = 0 AND median_playtime_forever > 0
            THEN 'Playtime Only'
        ELSE 'No Engagement Metrics'
    END AS metric_availability,
    COUNT(*) AS game_count
FROM metrics
WHERE estimated_owners <> '0 - 0'
GROUP BY metric_availability
;
-- KEY FINDINGS:
-- Peak CCU will be excluded as an engagement metric because the data had limited coverage.
-- Of the games analyzed, 69,463 had no usable engagement data, while only 14,040 had both CCU and playtime data.
-- Additionally, Peak CCU measures a game's highest concurrent player count rather than sustained activity, 
-- making it unreliable for measuring overall engagement.

-- ----------------------------------------------------------------------------------------------------------

-- As ownership increases, does the likelihood of having recorded playtime also increase?
SELECT
    COUNT(*) AS total_games,
    SUM(CASE 
		WHEN peak_ccu > 0 THEN 1 ELSE 0 END) 
        AS usable_peak_ccu,
	SUM(CASE
		WHEN median_playtime_forever > 0 THEN 1 ELSE 0 END)
        AS usable_median_playtime
FROM metrics;

WITH game_playtime AS (
	SELECT
		estimated_owners,
		COUNT(*) AS total_games,
		SUM(CASE
				WHEN median_playtime_forever > 0 THEN 1
				ELSE 0
			END) 
			AS games_with_playtime
	FROM metrics
	GROUP BY estimated_owners
	ORDER BY estimated_owners
 )
 SELECT
	estimated_owners,
    total_games,
    games_with_playtime,
    ROUND(games_with_playtime / total_games * 100, 2) as percentage
FROM game_playtime
;
-- KEY FINDINGS:
-- 26,173 games have median lifetime playtime greater than zero, but zero values cannot be assumed to represent missing data.
-- Because nonzero playtime coverage is extremely low for games below 20K owners, engagement analysis will be limited to games with 20K+ estimated owners.
-- Median lifetime playtime, including zero values, will be used to measure engagement.

-- ----------------------------------------------------------------------------------------------------------

-- Which genres have the highest median player engagement among games with at least 20,000 estimated owners?
WITH playtime_median AS (
	SELECT
		genre,
        median_playtime_forever,
        ROW_NUMBER() OVER(
			PARTITION BY genre 
            ORDER BY median_playtime_forever)
            AS row_num,
		COUNT(*) OVER(
			PARTITION BY genre)
            AS total_games
	FROM game_genres gg
    JOIN metrics m
		ON m.app_id = gg.app_id
	WHERE estimated_owners NOT IN ('0 - 0', '0 - 20000')
)
SELECT
	genre,
    ROUND(AVG(median_playtime_forever), 1)
    AS median_playtime,
    MAX(total_games) as games_analyzed
FROM playtime_median
WHERE row_num BETWEEN
	FLOOR((total_games + 1)/ 2)
    AND CEIL((total_games + 1)/ 2)
GROUP BY genre
HAVING MAX(total_games) >= 100
ORDER BY 
	median_playtime DESC,
    games_analyzed DESC
;
-- KEY FINDINGS:
-- Simulation had the highest median playtime at 167 minutes, followed by RPG (154) and Strategy (142).
-- Genres with fewer than 100 qualifying games were excluded to reduce the impact of small sample sizes.
-- High-volume genres such as Action (96 min), Adventure (100.5 min), and Indie (77 min) showed lower median engagement despite having substantially more qualifying games.
-- Free-to-Play had a median lifetime playtime of 0, indicating that at least half of qualifying games in this category recorded a median playtime of zero.

-- ----------------------------------------------------------------------------------------------------------


-- =====================================================
-- 6. PRICING & MARKET REACH
-- =====================================================

-- How does market reach vary across different price ranges?
WITH game_distribution as (
	SELECT
		CASE
		WHEN m.estimated_owners = '0 - 0'
			THEN 'no data'
		WHEN m.estimated_owners = '0 - 20000'
			THEN 'Under 20K Owners'
		WHEN m.estimated_owners IN ('20000 - 50000', '50000 - 100000')
			THEN '20K–100K Owners'
		WHEN m.estimated_owners IN ('100000 - 200000', '200000 - 500000')
			THEN '100K–500K Owners'
		WHEN m.estimated_owners = '500000 - 1000000'
			THEN '500K–1M Owners'
		ELSE '1M+ Owners'
		END AS market_reach,
        CASE
			WHEN g.price = 0 THEN 'Free'
			WHEN g.price < 2 THEN 'Under $2'
			WHEN g.price < 5 THEN '$2-$4.99'
			WHEN g.price < 10 THEN '$5-$9.99'
			WHEN g.price < 20 THEN '$10-$19.99'
			WHEN g.price < 30 THEN '$20-$29.99'
		ELSE '$30+'
	END AS price_range,
		COUNT(DISTINCT m.app_id) AS games_analyzed
	FROM metrics m
    JOIN games g
		ON m.app_id = g.app_id
	GROUP BY 
		market_reach, 
        price_range
	ORDER BY games_analyzed
)
SELECT
    market_reach,
    price_range,
    games_analyzed,
    ROUND(
		games_analyzed / SUM(games_analyzed) OVER (
		PARTITION BY price_range) * 100, 2)
        AS percentage -- refers to the percentage out of all games in the database
FROM game_distribution
WHERE market_reach <> 'no data'
ORDER BY percentage DESC
;
-- KEY FINDINGS:
-- Free games showed the strongest overall market reach, with 39% reaching 20K+ owners.
-- Among paid games, the $20-$29.99 range had the highest share reaching 20K+ owners (29.39%).
-- Most games remained below 20K owners across every price range, suggesting price alone is not a strong indicator of market reach.

-- ----------------------------------------------------------------------------------------------------------
-- How does pricing vary across genres?
WITH genre_pricing AS (
    SELECT
        gg.genre,
        CASE
            WHEN g.price = 0 THEN 'Free'
            WHEN g.price < 2 THEN 'Under $2'
            WHEN g.price < 5 THEN '$2-$4.99'
            WHEN g.price < 10 THEN '$5-$9.99'
            WHEN g.price < 20 THEN '$10-$19.99'
            WHEN g.price < 30 THEN '$20-$29.99'
            ELSE '$30+'
        END AS price_range,
        COUNT(DISTINCT g.app_id) AS games_analyzed
    FROM games g
    JOIN game_genres gg
        ON g.app_id = gg.app_id
    GROUP BY
        gg.genre,
        price_range
),
genre_totals AS (
    SELECT
        genre,
        price_range,
        games_analyzed,
        SUM(games_analyzed) OVER (
            PARTITION BY genre
        ) AS total_genre_games
    FROM genre_pricing
)
SELECT
    genre,
    price_range,
    games_analyzed,
    total_genre_games,
    ROUND(
        games_analyzed / total_genre_games * 100, 2) 
        AS percent_of_genre
FROM genre_totals
WHERE total_genre_games >= 100
ORDER BY
    genre,
    percent_of_genre DESC
;
-- KEY FINDINGS:
-- Low-cost pricing dominates across most genres, with games under $5 representing the largest share of releases.
-- Action, Adventure, Indie, and Casual games are particularly concentrated in lower price ranges.
-- RPG, Strategy, and Simulation have a greater presence in the $10–$19.99 range compared with other major genres.
-- Games priced $20+ represent a relatively small share across most genres.

-- =====================================================
-- APPENDIX: EXPLORATORY / DATA CHECKS
-- =====================================================

-- Use these only when inspecting the raw data. They are kept out of the main analysis flow.

SELECT *
FROM games;

SELECT *
FROM game_genres gg
JOIN metrics m
    ON gg.app_id = m.app_id;
