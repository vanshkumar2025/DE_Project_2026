
-- BookMyShow - Load Seed Data
-- Run from the project root after 01_schema.sql
-- Command: psql -d bookmyshow -f sql/02_load_data.sql

\set ON_ERROR_STOP on

SET search_path TO bms;


-- =============================================
-- 1. Load CSV files
-- =============================================

-- Reference tables
\copy bms.cities FROM 'seed_data/cities.csv' WITH (FORMAT csv, HEADER true);
\copy bms.movies FROM 'seed_data/movies.csv' WITH (FORMAT csv, HEADER true);
\copy bms.offers FROM 'seed_data/offers.csv' WITH (FORMAT csv, HEADER true);

-- Venues and customers
\copy bms.venues FROM 'seed_data/venues.csv' WITH (FORMAT csv, HEADER true);
\copy bms.customers FROM 'seed_data/customers.csv' WITH (FORMAT csv, HEADER true);

-- Screens and seats
\copy bms.screens FROM 'seed_data/screens.csv' WITH (FORMAT csv, HEADER true);
\copy bms.seats FROM 'seed_data/seats.csv' WITH (FORMAT csv, HEADER true);

-- Shows and bookings
\copy bms.shows FROM 'seed_data/shows.csv' WITH (FORMAT csv, HEADER true);
\copy bms.bookings FROM 'seed_data/bookings.csv' WITH (FORMAT csv, HEADER true);
\copy bms.booking_seats FROM 'seed_data/booking_seats.csv' WITH (FORMAT csv, HEADER true);

-- Movie reviews
\copy bms.movie_reviews FROM 'seed_data/movie_reviews.csv' WITH (FORMAT csv, HEADER true);


-- =============================================
-- 2. Update database statistics
-- =============================================

ANALYZE;


-- =============================================
-- 3. Row Count and Integrity Checks
-- =============================================

-- Expected row counts and integrity checks
-- PASS means the actual value matches the expected value.

SELECT
    'cities row count' AS check_name,
    COUNT(*) AS actual,
    10 AS expected,
    CASE WHEN COUNT(*) = 10 THEN 'PASS' ELSE 'FAIL' END AS result
FROM bms.cities

UNION ALL

SELECT 'venues row count', COUNT(*), 140,
       CASE WHEN COUNT(*) = 140 THEN 'PASS' ELSE 'FAIL' END
FROM bms.venues

UNION ALL

SELECT 'screens row count', COUNT(*), 490,
       CASE WHEN COUNT(*) = 490 THEN 'PASS' ELSE 'FAIL' END
FROM bms.screens

UNION ALL

SELECT 'seats row count', COUNT(*), 94056,
       CASE WHEN COUNT(*) = 94056 THEN 'PASS' ELSE 'FAIL' END
FROM bms.seats

UNION ALL

SELECT 'movies row count', COUNT(*), 300,
       CASE WHEN COUNT(*) = 300 THEN 'PASS' ELSE 'FAIL' END
FROM bms.movies

UNION ALL

SELECT 'shows row count', COUNT(*), 160034,
       CASE WHEN COUNT(*) = 160034 THEN 'PASS' ELSE 'FAIL' END
FROM bms.shows

UNION ALL

SELECT 'customers row count', COUNT(*), 40000,
       CASE WHEN COUNT(*) = 40000 THEN 'PASS' ELSE 'FAIL' END
FROM bms.customers

UNION ALL

SELECT 'offers row count', COUNT(*), 25,
       CASE WHEN COUNT(*) = 25 THEN 'PASS' ELSE 'FAIL' END
FROM bms.offers

UNION ALL

SELECT 'bookings row count', COUNT(*), 150094,
       CASE WHEN COUNT(*) = 150094 THEN 'PASS' ELSE 'FAIL' END
FROM bms.bookings

UNION ALL

SELECT 'booking_seats row count', COUNT(*), 300389,
       CASE WHEN COUNT(*) = 300389 THEN 'PASS' ELSE 'FAIL' END
FROM bms.booking_seats

UNION ALL

SELECT 'movie_reviews row count', COUNT(*), 32510,
       CASE WHEN COUNT(*) = 32510 THEN 'PASS' ELSE 'FAIL' END
FROM bms.movie_reviews

UNION ALL

-- Check 1: Every booked seat belongs to the correct screen.

SELECT 'Invalid seat-screen assignments', COUNT(*), 0,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM bms.booking_seats bs
JOIN bms.shows sh ON sh.show_id = bs.show_id
JOIN bms.seats se ON se.seat_id = bs.seat_id
WHERE sh.screen_id <> se.screen_id

UNION ALL

-- Check 2: Booking and seat records have matching show IDs.

SELECT 'Mismatched booking-show references', COUNT(*), 0,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM bms.booking_seats bs
JOIN bms.bookings b ON b.booking_id = bs.booking_id
WHERE bs.show_id <> b.show_id

UNION ALL

-- Check 3: Shows on the same screen must not overlap.

SELECT 'Overlapping shows', COUNT(*), 0,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM bms.shows a
JOIN bms.shows b
    ON a.screen_id = b.screen_id
    AND a.show_id < b.show_id
    AND a.starts_at < b.ends_at
    AND b.starts_at < a.ends_at

UNION ALL

-- Check 4: Ticket count must match assigned seats.
-- Only confirmed and pending bookings are checked.

SELECT 'Mismatched ticket counts', COUNT(*), 0,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT b.booking_id
    FROM bms.bookings b
    LEFT JOIN bms.booking_seats bs
        ON b.booking_id = bs.booking_id
    WHERE b.status IN ('CONFIRMED', 'PENDING')
    GROUP BY b.booking_id, b.num_tickets
    HAVING COUNT(bs.seat_id) <> b.num_tickets
) AS mismatches

UNION ALL

-- Check 5: Booking total must match its amount components.

SELECT 'Incorrect booking totals', COUNT(*), 0,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM bms.bookings
WHERE total_amount <>
      ticket_amount + convenience_fee + fnb_amount - discount

UNION ALL

-- Check 6: Screen capacity must match the number of seats.

SELECT 'Screen capacity mismatches', COUNT(*), 0,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT sc.screen_id
    FROM bms.screens sc
    LEFT JOIN bms.seats se ON se.screen_id = sc.screen_id
    GROUP BY sc.screen_id, sc.total_seats
    HAVING COUNT(se.seat_id) <> sc.total_seats
) AS capacity_errors;


-- =============================================
-- Data loading completed
-- =============================================
