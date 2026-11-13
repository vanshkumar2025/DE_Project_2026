
-- =============================================================
-- BookMyShow Database Schema
-- PostgreSQL 15+
-- =============================================================

CREATE SCHEMA bms;

-- Required for preventing overlapping shows
CREATE EXTENSION IF NOT EXISTS btree_gist;

SET search_path TO bms, public;


-- =============================================================
-- 1. CITIES
-- =============================================================

CREATE TABLE cities (
    city_id INTEGER PRIMARY KEY,
    city_name VARCHAR(30) NOT NULL,
    state VARCHAR(30) NOT NULL
);


-- =============================================================
-- 2. MOVIES
-- =============================================================

CREATE TABLE movies (
    movie_id INTEGER PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    language VARCHAR(30) NOT NULL,
    certificate VARCHAR(5) NOT NULL
        CHECK (certificate IN ('U', 'UA', 'A')),
    duration_min SMALLINT NOT NULL
        CHECK (duration_min > 0),
    release_date DATE NOT NULL
);


-- =============================================================
-- 3. OFFERS
-- =============================================================

CREATE TABLE offers (
    offer_code VARCHAR(11) PRIMARY KEY,
    description TEXT NOT NULL,
    discount_pct NUMERIC(5,2) NOT NULL
        CHECK (discount_pct BETWEEN 0 AND 100),
    max_discount NUMERIC(12,2) NOT NULL
        CHECK (max_discount >= 0),
    valid_from DATE NOT NULL,
    valid_to DATE NOT NULL,

    CHECK (valid_to >= valid_from)
);


-- =============================================================
-- 4. VENUES
-- =============================================================

CREATE TABLE venues (
    venue_id INTEGER PRIMARY KEY,
    venue_name VARCHAR(100) NOT NULL,
    city_id INTEGER NOT NULL,
    chain VARCHAR(20) NOT NULL
        CHECK (chain IN (
            'PVR', 'INOX', 'Cinepolis',
            'Miraj', 'Independent'
        )),
    address TEXT NOT NULL,

    CONSTRAINT fk_venues_city
        FOREIGN KEY (city_id)
        REFERENCES cities(city_id)
        ON DELETE RESTRICT
);


-- =============================================================
-- 5. SCREENS
-- =============================================================

CREATE TABLE screens (
    screen_id INTEGER PRIMARY KEY,
    venue_id INTEGER NOT NULL,
    screen_name VARCHAR(20) NOT NULL,
    screen_type VARCHAR(20) NOT NULL
        CHECK (screen_type IN (
            'STANDARD', 'GOLD', 'IMAX', '4DX'
        )),
    total_seats SMALLINT NOT NULL
        CHECK (total_seats > 0),

    CONSTRAINT uq_venue_screen
        UNIQUE (venue_id, screen_name),

    CONSTRAINT fk_screens_venue
        FOREIGN KEY (venue_id)
        REFERENCES venues(venue_id)
        ON DELETE RESTRICT
);


-- =============================================================
-- 6. SEATS
-- =============================================================

CREATE TABLE seats (
    seat_id INTEGER PRIMARY KEY,
    screen_id INTEGER NOT NULL,
    row_label CHAR(1) NOT NULL
        CHECK (row_label BETWEEN 'A' AND 'P'),
    seat_number SMALLINT NOT NULL
        CHECK (seat_number > 0),
    seat_class VARCHAR(20) NOT NULL
        CHECK (seat_class IN (
            'CLASSIC', 'PRIME', 'RECLINER'
        )),

    CONSTRAINT uq_screen_seat_position
        UNIQUE (screen_id, row_label, seat_number),

    CONSTRAINT fk_seats_screen
        FOREIGN KEY (screen_id)
        REFERENCES screens(screen_id)
        ON DELETE RESTRICT
);


-- =============================================================
-- 7. SHOWS
-- =============================================================

CREATE TABLE shows (
    show_id INTEGER PRIMARY KEY,
    movie_id INTEGER NOT NULL,
    screen_id INTEGER NOT NULL,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    format VARCHAR(10) NOT NULL
        CHECK (format IN ('2D', '3D', 'IMAX', '4DX')),
    base_price NUMERIC(12,2) NOT NULL
        CHECK (base_price >= 0),

    CONSTRAINT chk_show_time
        CHECK (ends_at > starts_at),

    CONSTRAINT fk_shows_movie
        FOREIGN KEY (movie_id)
        REFERENCES movies(movie_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_shows_screen
        FOREIGN KEY (screen_id)
        REFERENCES screens(screen_id)
        ON DELETE RESTRICT
);


-- Prevent overlapping shows on the same screen

ALTER TABLE shows
ADD CONSTRAINT no_overlapping_shows
EXCLUDE USING GIST (
    screen_id WITH =,
    tstzrange(starts_at, ends_at, '[)') WITH &&
);


-- =============================================================
-- 8. CUSTOMERS
-- =============================================================

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(10) NOT NULL UNIQUE
        CHECK (phone ~ '^[0-9]{10}$'),
    city_id INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_customers_city
        FOREIGN KEY (city_id)
        REFERENCES cities(city_id)
        ON DELETE RESTRICT
);


-- =============================================================
-- 9. BOOKINGS
-- =============================================================

CREATE TABLE bookings (
    booking_id INTEGER PRIMARY KEY,
    booking_code VARCHAR(10) NOT NULL UNIQUE
        CHECK (booking_code ~ '^BMS[A-Z0-9]{7}$'),
    customer_id INTEGER NOT NULL,
    show_id INTEGER NOT NULL,
    booked_at TIMESTAMPTZ NOT NULL,
    num_tickets SMALLINT NOT NULL
        CHECK (num_tickets > 0),

    ticket_amount NUMERIC(12,2) NOT NULL
        CHECK (ticket_amount >= 0),

    convenience_fee NUMERIC(12,2) NOT NULL
        CHECK (convenience_fee >= 0),

    fnb_amount NUMERIC(12,2) NOT NULL
        CHECK (fnb_amount >= 0),

    offer_code VARCHAR(11),

    discount NUMERIC(12,2) NOT NULL
        CHECK (discount >= 0),

    total_amount NUMERIC(12,2) NOT NULL
        CHECK (total_amount >= 0),

    payment_method VARCHAR(20) NOT NULL
        CHECK (payment_method IN (
            'UPI', 'CARD', 'GIFT_CARD',
            'WALLET', 'NETBANKING'
        )),

    status VARCHAR(20) NOT NULL
        CHECK (status IN (
            'PENDING', 'CONFIRMED',
            'CANCELLED', 'PAYMENT_FAILED'
        )),

    -- Booking amount calculation
    CONSTRAINT chk_booking_total
        CHECK (
            total_amount =
            ticket_amount + convenience_fee + fnb_amount - discount
        ),

    CONSTRAINT chk_discount_amount
        CHECK (
            discount <= ticket_amount + convenience_fee + fnb_amount
        ),

    -- Discount requires an offer
    CONSTRAINT chk_booking_offer
        CHECK (offer_code IS NOT NULL OR discount = 0),

    -- Required for the composite FK in booking_seats
    CONSTRAINT uq_booking_show
        UNIQUE (booking_id, show_id),

    CONSTRAINT fk_bookings_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_bookings_show
        FOREIGN KEY (show_id)
        REFERENCES shows(show_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_bookings_offer
        FOREIGN KEY (offer_code)
        REFERENCES offers(offer_code)
        ON DELETE RESTRICT
);


-- =============================================================
-- 10. BOOKING_SEATS
-- =============================================================

CREATE TABLE booking_seats (
    booking_id INTEGER NOT NULL,
    show_id INTEGER NOT NULL,
    seat_id INTEGER NOT NULL,
    price NUMERIC(12,2) NOT NULL
        CHECK (price >= 0),

    -- A seat can be booked only once for a particular show
    CONSTRAINT pk_booking_seats
        PRIMARY KEY (show_id, seat_id),

    -- Booking and show must belong together
    CONSTRAINT fk_booking_seats_booking
        FOREIGN KEY (booking_id, show_id)
        REFERENCES bookings(booking_id, show_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_booking_seats_seat
        FOREIGN KEY (seat_id)
        REFERENCES seats(seat_id)
        ON DELETE RESTRICT
);


-- =============================================================
-- 11. MOVIE_REVIEWS
-- =============================================================

CREATE TABLE movie_reviews (
    review_id INTEGER PRIMARY KEY,
    movie_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    rating SMALLINT NOT NULL
        CHECK (rating BETWEEN 1 AND 10),
    review_text TEXT,
    created_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT uq_movie_customer_review
        UNIQUE (movie_id, customer_id),

    CONSTRAINT fk_reviews_movie
        FOREIGN KEY (movie_id)
        REFERENCES movies(movie_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_reviews_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE RESTRICT
);


-- =============================================================
-- END OF SCHEMA
-- =============================================================
