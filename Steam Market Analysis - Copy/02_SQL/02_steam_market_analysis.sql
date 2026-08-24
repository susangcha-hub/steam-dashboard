-- =====================================================
-- Steam Market Opportunity Analysis 
-- =====================================================

-- Business Problem: What market opportunities exist on Steam that could help an indie game studio maximize its chances of success?
	-- Q1: Which genres have high player demand relative to the number of competing games?
    -- Q2: Which genres appear underserved or oversaturated based on current player reach and recent release growth?
    -- Q3: Which genres offer the strongest overall market opportunity when competition, demand, engagement, satisfaction, and pricing are considered together?
    -- Q4: Which categories/features are most associated with stronger performance within the finalist genres, based on prevalence,
	-- player reach, engagement, and satisfaction?
-- ----------------------------------------------------------------------------------------------------------

-- Q1: Which genres have high player demand relative to the number of competing games?
-- Approach: Evaluate genres against market-wide benchmarks for reach, engagement, competition, and satifaction.

WITH game_distribution AS (
	SELECT
		gg.genre,
        m.app_id,
		CASE
			WHEN m.estimated_owners = '0 - 0' THEN 'no data'
			WHEN m.estimated_owners = '0 - 20000' THEN 'Under 20K Owners'
			WHEN m.estimated_owners IN ('20000 - 50000', '50000 - 100000') THEN '20K–100K Owners'
			WHEN m.estimated_owners IN ('100000 - 200000', '200000 - 500000') THEN '100K–500K Owners'
			WHEN m.estimated_owners = '500000 - 1000000' THEN '500K–1M Owners'
			ELSE '1M+ Owners'
		END AS market_reach
	FROM metrics m
    JOIN game_genres gg
		ON m.app_id = gg.app_id
),

playtime_median AS (
	SELECT
		gg.genre,
        m.median_playtime_forever,
        ROW_NUMBER() OVER (
			PARTITION BY gg.genre 
            ORDER BY m.median_playtime_forever
		) AS row_num,
		COUNT(*) OVER (
			PARTITION BY gg.genre
		) AS total_games
	FROM game_genres gg
    JOIN metrics m
		ON m.app_id = gg.app_id
	WHERE m.estimated_owners NOT IN ('0 - 0', '0 - 20000')
), 

genre_saturation AS (
	SELECT
		genre,
		COUNT(DISTINCT app_id) AS total_games
	FROM game_genres
	GROUP BY genre
), 

genre_reach AS (
    SELECT
        genre,
        ROUND(SUM(CASE 
					WHEN market_reach <> 'Under 20K Owners'
					AND market_reach <> 'no data' THEN 1 ELSE 0 
				END) * 100.0 /
			SUM(CASE 
					WHEN market_reach <> 'no data' THEN 1 ELSE 0 
				END), 2) 
                AS reach_percentage
    FROM game_distribution
    GROUP BY genre
), 

genre_playtime AS (
    SELECT
        genre,
        ROUND(AVG(median_playtime_forever), 2) AS median_playtime
    FROM playtime_median
    WHERE row_num IN (
        FLOOR((total_games + 1) / 2),
        CEIL((total_games + 1) / 2))
    GROUP BY genre
),

genre_reception AS (
	SELECT
		gg.genre,
		COUNT(DISTINCT m.app_id) AS games_analyzed,
		ROUND(
			AVG(
				m.positive * 100.0 / (m.positive + m.negative)
			), 2
		) AS avg_positive_review_percentage
	FROM metrics m
	JOIN game_genres gg
		ON m.app_id = gg.app_id
	WHERE m.positive + m.negative >= 10
	GROUP BY gg.genre
), 

competition_benchmark AS (
	SELECT
		AVG(total_games) AS median_total_games
	FROM (
		SELECT
			total_games,
			ROW_NUMBER() OVER (
				ORDER BY total_games
			) AS row_num,
			COUNT(*) OVER () AS total_genres
		FROM genre_saturation
	) AS genre_counts
	WHERE row_num IN (
		FLOOR((total_genres + 1) / 2),
		CEIL((total_genres + 1) / 2))
)

SELECT
    gs.genre,
    gs.total_games,
    gr.reach_percentage,
    gp.median_playtime,
    grec.avg_positive_review_percentage,
    grec.games_analyzed
FROM genre_saturation gs
JOIN genre_reach gr
    ON gs.genre = gr.genre
JOIN genre_playtime gp
    ON gs.genre = gp.genre
JOIN genre_reception grec
    ON gs.genre = grec.genre
ORDER BY
    gr.reach_percentage DESC,
    gp.median_playtime DESC,
    grec.avg_positive_review_percentage DESC,
    gs.total_games ASC
;
-- KEY FINDINGS:
-- 'RPG' and 'Strategy' showed the strongest overall balance of reach, engagement, and satisfaction.
-- 'Massively Multiplayer' had high reach and low competition, but weaker engagement and satisfaction.
-- 'Simulation' showed strong engagement but moderate reach and satisfaction.
-- Large genres such as 'Indie', 'Casual', 'Action', and 'Adventure' faced high competition without stronger player performance.

-- ----------------------------------------------------------------------------------------------------------

-- Q2: Which genres appear underserved or oversaturated based on current player reach and recent release growth?
-- Approach: Compare current player reach against the growth in game releases from 2021 to 2025.

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
        YEAR(g.release_date)
),

five_year_release AS (
    SELECT
        genre,
        SUM(CASE
                WHEN release_year = 2021 THEN total_games ELSE 0
            END) 
            AS 2021_total_games,
        SUM(CASE
                WHEN release_year = 2025 THEN total_games ELSE 0
            END) 
            AS 2025_total_games
    FROM release_trend
    GROUP BY genre
),

genre_reach AS (
    SELECT
        gg.genre,
        ROUND(COUNT(DISTINCT 
					CASE
                    WHEN m.estimated_owners NOT IN ('0 - 0', '0 - 20000')
                    THEN m.app_id
                END
            ) * 100.0 / 
			COUNT(DISTINCT 
					CASE
                    WHEN m.estimated_owners <> '0 - 0'
                    THEN m.app_id
                END), 2) 
            AS reach_percentage
    FROM metrics m
    JOIN game_genres gg
        ON m.app_id = gg.app_id
    GROUP BY gg.genre
)

SELECT
    fyr.genre,
    gr.reach_percentage,
    fyr.2021_total_games,
    fyr.2025_total_games,
    fyr.2025_total_games - fyr.2021_total_games AS absolute_growth,
    ROUND(
        (fyr.2025_total_games - fyr.2021_total_games)
        / NULLIF(fyr.2021_total_games, 0) * 100, 2) 
        AS percentage_growth,
    CASE
        WHEN fyr.2025_total_games > fyr.2021_total_games THEN 'Growing'
        WHEN fyr.2025_total_games < fyr.2021_total_games THEN 'Shrinking'
        ELSE 'No Change'
    END AS release_trend
FROM five_year_release fyr
JOIN genre_reach gr
    ON fyr.genre = gr.genre
ORDER BY gr.reach_percentage DESC
;
-- KEY FINDINGS:
-- 'Massively Multiplayer' showed high reach (43.84%) with relatively moderate release growth (88.99%), suggesting potential unmet opportunity.
-- 'Casual' showed low reach (19.10%) despite strong release growth (111.10%), suggesting potential oversaturation.
-- 'Free To Play', 'RPG', and 'Strategy' had strong reach, but rapid release growth suggests competition is increasing.
-- 'Web Publishing' showed high reach with declining releases, but may not be relevant to a traditional indie game studio.

-- ----------------------------------------------------------------------------------------------------------

-- Q3: Which genres offer the strongest overall market opportunity when competition, demand, engagement, satisfaction, and pricing are considered together?
-- Approach: Compare promising genres identified in the previous analyses and evaluate their pricing patterns to identify the strongest overall opportunities.

WITH genre_pricing AS (
	SELECT
		gg.genre,
		CASE
			WHEN g.price = 0 THEN 'Free'
			WHEN g.price < 2 THEN 'Under $2'
			WHEN g.price < 5 THEN '$2–$4.99'
			WHEN g.price < 10 THEN '$5–$9.99'
			WHEN g.price < 20 THEN '$10–$19.99'
			WHEN g.price < 30 THEN '$20–$29.99'
			ELSE '$30+'
		END AS price_range,
		COUNT(DISTINCT g.app_id) AS games_analyzed
	FROM games g
	JOIN game_genres gg
		ON g.app_id = gg.app_id
	GROUP BY
		gg.genre,
		price_range
)

SELECT
	genre,
	price_range,
	games_analyzed,
	ROUND(
		games_analyzed * 100.0 /
		SUM(games_analyzed) OVER (PARTITION BY genre),
		2
	) AS percentage_of_genre
FROM genre_pricing
WHERE genre LIKE '%RPG%'
   OR genre LIKE '%Strategy%'
   OR genre LIKE '%Multiplayer%'
   OR genre LIKE '%Simulation%'
   OR genre LIKE '%Casual%'
ORDER BY
	genre,
	percentage_of_genre DESC
;
-- KEY FINDINGS:
-- 'Massively Multiplayer' was heavily Free-to-Play (55.62%), suggesting a different monetization model than the other candidate genres.
-- 'RPG', 'Strategy', and 'Simulation' were primarily concentrated below $10, with paid pricing more common than Free-to-Play.
-- 'Casual' was heavily concentrated below $5, suggesting strong price competition alongside its previously identified market saturation.
-- 'RPG' showed the most balanced pricing distribution among the candidate genres.

-- ----------------------------------------------------------------------------------------------------------

-- Q4: Which categories/features are most associated with stronger performance within the finalist genres, based on prevalence,
	-- player reach, engagement, and satisfaction?
-- Approach: Compare categories within the finalist genres based on prevalence, player reach, median playtime, and 
	-- player satisfaction to identify features associated with stronger-performing games.

WITH genre_totals AS (
    SELECT
        genre,
        COUNT(DISTINCT app_id) AS total_genre_games
    FROM game_genres
    WHERE genre IN (
        'RPG',
        'Strategy',
        'Massively Multiplayer',
        'Simulation',
        'Casual')
    GROUP BY genre
),

category_base AS (
    SELECT
        gg.genre,
        gc.category,
        gc.app_id,
        m.estimated_owners,
        m.median_playtime_forever,
        m.positive,
        m.negative
    FROM game_categories gc
    JOIN game_genres gg
        ON gc.app_id = gg.app_id
    JOIN metrics m
        ON gc.app_id = m.app_id
    WHERE gg.genre IN (
        'RPG',
        'Strategy',
        'Massively Multiplayer',
        'Simulation',
        'Casual')
),

category_metrics AS (
    SELECT
        cb.genre,
        cb.category,
        COUNT(DISTINCT cb.app_id) 
			AS games_analyzed,
        ROUND(COUNT(DISTINCT 
			cb.app_id) * 100.0 /
            gt.total_genre_games, 2) 
            AS category_share_pct,
        ROUND(COUNT(DISTINCT 
			CASE
                WHEN cb.estimated_owners NOT IN ('0 - 0', '0 - 20000')
                THEN cb.app_id
            END) * 100.0 /
            NULLIF(
                COUNT(DISTINCT CASE
                    WHEN cb.estimated_owners <> '0 - 0'
                    THEN cb.app_id
                END), 0), 2) 
                AS reach_pct,
        ROUND(AVG(CASE
                    WHEN (cb.positive + cb.negative) >= 10
                    THEN cb.positive * 100.0 /(cb.positive + cb.negative)
                END),2) 
                AS avg_positive_review_pct
    FROM category_base cb
    JOIN genre_totals gt
        ON cb.genre = gt.genre
    GROUP BY
        cb.genre,
        cb.category,
        gt.total_genre_games
),

playtime_ranked AS (
    SELECT
        genre,
        category,
        median_playtime_forever,
        ROW_NUMBER() OVER (
            PARTITION BY genre, category
            ORDER BY median_playtime_forever) AS row_num,
        COUNT(*) OVER (
            PARTITION BY genre, category) AS total_rows
    FROM category_base
    WHERE estimated_owners NOT IN ('0 - 0', '0 - 20000')
      AND median_playtime_forever IS NOT NULL
),

median_playtime AS (
    SELECT
        genre,
        category,
        ROUND(AVG(median_playtime_forever), 2) AS median_playtime
    FROM playtime_ranked
    WHERE row_num IN (
        FLOOR((total_rows + 1) / 2),
        FLOOR((total_rows + 2) / 2))
    GROUP BY
        genre,
        category
)

SELECT
    cm.genre,
    cm.category,
    cm.games_analyzed,
    cm.category_share_pct,
    cm.reach_pct,
    mp.median_playtime,
    cm.avg_positive_review_pct
FROM category_metrics cm
LEFT JOIN median_playtime mp
    ON cm.genre = mp.genre
   AND cm.category = mp.category
WHERE cm.games_analyzed >= 100
ORDER BY
    cm.genre,
    cm.reach_pct DESC
;

-- Key Findings:
-- RPG and Strategy show strong reach and engagement across feature-rich games.
-- Trading Cards and Workshop features stand out, while accessibility/customization features show higher satisfaction.
-- Massively Multiplayer continues to show comparatively weaker satisfaction.
