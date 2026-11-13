# Phase 2 – Database Schema Design

**Project:** BookMyShow Movie & Event Ticketing Database  
**Team:** T0112 | **Lead:** Vansh Kumar | **Date:** November 2026  
**Database:** PostgreSQL 15+

## 1. Overview

The database is designed using the 11 CSV files provided with the project. Since the original schema is not available, the tables, relationships, keys and constraints have been identified by examining the data.

The database consists of 11 tables. Each table stores information about a particular part of the booking system, such as customers, movies, venues, shows and bookings.

The tables are connected using primary keys and foreign keys. UNIQUE, NOT NULL and CHECK constraints are also used to maintain data consistency.

All tables will be created inside a PostgreSQL schema named `bms`.

```sql
CREATE SCHEMA bms;
SET search_path TO bms;
```

## 2. Table Design

### 2.1 cities

Stores the cities where BookMyShow venues and customers are located.

| Column | Data Type | Constraint | Description |
|---|---|---|---|
| city_id | INTEGER | PRIMARY KEY | Unique city ID |
| city_name | VARCHAR(30) | NOT NULL | City name |
| state | VARCHAR(30) | NOT NULL | State name |

### 2.2 venues

Stores cinema and venue information.

| Column | Data Type | Constraint | Description |
|---|---|---|---|
| venue_id | INTEGER | PRIMARY KEY | Unique venue ID |
| venue_name | TEXT | NOT NULL | Cinema name |
| city_id | INTEGER | FOREIGN KEY, NOT NULL | City of the venue |
| chain | VARCHAR(20) | NOT NULL | Cinema chain |
| address | TEXT | NOT NULL | Venue address |

### 2.3 screens

Stores the screens available inside each venue.

| Column | Data Type | Constraint | Description |
|---|---|---|---|
| screen_id | INTEGER | PRIMARY KEY | Unique screen ID |
| venue_id | INTEGER | FOREIGN KEY, NOT NULL | Venue containing the screen |
| screen_name | VARCHAR(20) | NOT NULL | Screen name |
| screen_type | VARCHAR(20) | NOT NULL | Type of screen |
| total_seats | SMALLINT | NOT NULL | Total seating capacity |

The combination of `venue_id` and `screen_name` is also unique because a venue should not have two screens with the same name.

### 2.4 seats

Stores the seating arrangement of every screen.

| Column | Data Type | Constraint | Description |
|---|---|---|---|
| seat_id | INTEGER | PRIMARY KEY | Unique seat ID |
| screen_id | INTEGER | FOREIGN KEY, NOT NULL | Screen containing the seat |
| row_label | CHAR(1) | NOT NULL | Seat row |
| seat_number | SMALLINT | NOT NULL | Seat number |
| seat_class | VARCHAR(20) | NOT NULL | Seat category |

The combination of `screen_id`, `row_label` and `seat_number` is unique. This prevents duplicate seat positions within a screen.

### 2.5 movies

Stores details about movies available on the platform.

| Column | Data Type | Constraint | Description |
|---|---|---|---|
| movie_id | INTEGER | PRIMARY KEY | Unique movie ID |
| title | VARCHAR(100) | NOT NULL | Movie title |
| language | VARCHAR(30) | NOT NULL | Movie language |
| certificate | VARCHAR(5) | NOT NULL | Movie certificate |
| duration_min | SMALLINT | NOT NULL | Duration in minutes |
| release_date | DATE | NOT NULL | Release date |

### 2.6 shows

Stores the scheduled shows of movies in different screens.

| Column | Data Type | Constraint | Description |
|---|---|---|---|
| show_id | INTEGER | PRIMARY KEY | Unique show ID |
| movie_id | INTEGER | FOREIGN KEY, NOT NULL | Movie being shown |
| screen_id | INTEGER | FOREIGN KEY, NOT NULL | Screen hosting the show |
| starts_at | TIMESTAMPTZ | NOT NULL | Show start time |
| ends_at | TIMESTAMPTZ | NOT NULL | Show end time |
| format | VARCHAR(10) | NOT NULL | Show format |
| base_price | NUMERIC(12,2) | NOT NULL | Base ticket price |

`TIMESTAMPTZ` is used because the timestamps in the CSV files contain timezone information.

### 2.7 customers

Stores information about registered customers.

| Column | Data Type | Constraint | Description |
|---|---|---|---|
| customer_id | INTEGER | PRIMARY KEY | Unique customer ID |
| full_name | VARCHAR(100) | NOT NULL | Customer name |
| email | VARCHAR(255) | UNIQUE, NOT NULL | Customer email |
| phone | VARCHAR(10) | UNIQUE, NOT NULL | Mobile number |
| city_id | INTEGER | FOREIGN KEY, NOT NULL | Customer's city |
| created_at | TIMESTAMPTZ | NOT NULL | Account creation time |

Phone numbers are stored as VARCHAR because they are identifiers and are not used for mathematical calculations.

### 2.8 offers

Stores discount offers available to customers.

| Column | Data Type | Constraint | Description |
|---|---|---|---|
| offer_code | VARCHAR(11) | PRIMARY KEY | Unique offer code |
| description | TEXT | NOT NULL | Offer description |
| discount_pct | NUMERIC(5,2) | NOT NULL | Discount percentage |
| max_discount | NUMERIC(12,2) | NOT NULL | Maximum discount amount |
| valid_from | DATE | NOT NULL | Offer start date |
| valid_to | DATE | NOT NULL | Offer expiry date |

### 2.9 bookings

Stores booking and payment details.

| Column | Data Type | Constraint | Description |
|---|---|---|---|
| booking_id | INTEGER | PRIMARY KEY | Unique booking ID |
| booking_code | VARCHAR(10) | UNIQUE, NOT NULL | Booking reference code |
| customer_id | INTEGER | FOREIGN KEY, NOT NULL | Customer who booked |
| show_id | INTEGER | FOREIGN KEY, NOT NULL | Booked show |
| booked_at | TIMESTAMPTZ | NOT NULL | Booking date and time |
| num_tickets | SMALLINT | NOT NULL | Number of tickets |
| ticket_amount | NUMERIC(12,2) | NOT NULL | Total ticket amount |
| convenience_fee | NUMERIC(12,2) | NOT NULL | Convenience fee |
| fnb_amount | NUMERIC(12,2) | NOT NULL | Food and beverage amount |
| offer_code | VARCHAR(11) | FOREIGN KEY, NULL allowed | Applied offer |
| discount | NUMERIC(12,2) | NOT NULL | Discount amount |
| total_amount | NUMERIC(12,2) | NOT NULL | Final booking amount |
| payment_method | VARCHAR(20) | NOT NULL | Payment method |
| status | VARCHAR(20) | NOT NULL | Booking status |

The `offer_code` column allows NULL because customers do not always use an offer while booking.

### 2.10 booking_seats

Connects bookings with the seats assigned to them.

| Column | Data Type | Constraint | Description |
|---|---|---|---|
| booking_id | INTEGER | FOREIGN KEY, NOT NULL | Related booking |
| show_id | INTEGER | FOREIGN KEY, NOT NULL | Related show |
| seat_id | INTEGER | FOREIGN KEY, NOT NULL | Assigned seat |
| price | NUMERIC(12,2) | NOT NULL | Price of the seat |

The composite primary key is `(show_id, seat_id)`.

This ensures that the same seat cannot be booked more than once for the same show.

An additional composite foreign key `(booking_id, show_id)` will ensure that the show in this table matches the show recorded in the corresponding booking.

### 2.11 movie_reviews

Stores movie ratings and reviews submitted by customers.

| Column | Data Type | Constraint | Description |
|---|---|---|---|
| review_id | INTEGER | PRIMARY KEY | Unique review ID |
| movie_id | INTEGER | FOREIGN KEY, NOT NULL | Reviewed movie |
| customer_id | INTEGER | FOREIGN KEY, NOT NULL | Customer who submitted the review |
| rating | SMALLINT | NOT NULL | Movie rating |
| review_text | TEXT | NULL allowed | Written review |
| created_at | TIMESTAMPTZ | NOT NULL | Review date and time |

The combination of `movie_id` and `customer_id` is unique in the supplied data. `review_text` allows NULL because a customer can submit a rating without writing a review.

## 3. Keys and Relationships

### Primary Keys

| Table | Primary Key |
|---|---|
| cities | city_id |
| venues | venue_id |
| screens | screen_id |
| seats | seat_id |
| movies | movie_id |
| shows | show_id |
| customers | customer_id |
| offers | offer_code |
| bookings | booking_id |
| booking_seats | show_id, seat_id |
| movie_reviews | review_id |

### Foreign Keys

| Table | Foreign Key | References |
|---|---|---|
| venues | city_id | cities(city_id) |
| screens | venue_id | venues(venue_id) |
| seats | screen_id | screens(screen_id) |
| shows | movie_id | movies(movie_id) |
| shows | screen_id | screens(screen_id) |
| customers | city_id | cities(city_id) |
| bookings | customer_id | customers(customer_id) |
| bookings | show_id | shows(show_id) |
| bookings | offer_code | offers(offer_code) |
| booking_seats | booking_id, show_id | bookings(booking_id, show_id) |
| booking_seats | show_id | shows(show_id) |
| booking_seats | seat_id | seats(seat_id) |
| movie_reviews | movie_id | movies(movie_id) |
| movie_reviews | customer_id | customers(customer_id) |

### Relationships

- One city can have multiple venues and customers.
- One venue can contain multiple screens.
- One screen can have multiple seats and multiple shows.
- One movie can have multiple shows.
- One customer can make multiple bookings.
- One show can have multiple bookings.
- One booking can contain multiple seats.
- One offer can be used in multiple bookings.
- One movie can receive multiple reviews.
- One customer can submit multiple reviews.

The `booking_seats` table handles the relationship between bookings and seats for individual shows.

### ON DELETE Rules

| Relationship | Rule | Reason |
|---|---|---|
| cities → venues | RESTRICT | Prevent deleting cities that have venues. |
| cities → customers | RESTRICT | Preserve customer city references. |
| venues → screens | RESTRICT | Preserve existing screen records. |
| screens → seats | RESTRICT | Preserve existing seat layouts. |
| screens → shows | RESTRICT | Preserve show history. |
| movies → shows | RESTRICT | Preserve movie information for existing shows. |
| customers → bookings | RESTRICT | Preserve booking history. |
| shows → bookings | RESTRICT | Preserve booking references. |
| offers → bookings | RESTRICT | Preserve historical offer references. |
| bookings → booking_seats | CASCADE | Remove dependent seat records when a booking is deleted. |
| shows → booking_seats | RESTRICT | Prevent deletion of shows referenced by seat records. |
| seats → booking_seats | RESTRICT | Prevent deletion of seats referenced by bookings. |
| movies → movie_reviews | RESTRICT | Preserve movie reviews. |
| customers → movie_reviews | RESTRICT | Preserve review ownership. |

Bookings should normally be cancelled by updating their status and releasing the seats instead of deleting the booking record.

## 4. Constraints

The following constraints will be used to prevent invalid records.

### UNIQUE Constraints

- `customers.email`
- `customers.phone`
- `bookings.booking_code`
- `screens(venue_id, screen_name)`
- `seats(screen_id, row_label, seat_number)`
- `booking_seats(show_id, seat_id)`
- `movie_reviews(movie_id, customer_id)`

### CHECK Constraints

| Table | Condition | Purpose |
|---|---|---|
| venues | chain IN ('PVR', 'INOX', 'Cinepolis', 'Miraj', 'Independent') | Valid cinema chains |
| screens | screen_type IN ('STANDARD', 'GOLD', 'IMAX', '4DX') | Valid screen types |
| screens | total_seats > 0 | Positive screen capacity |
| seats | row_label BETWEEN 'A' AND 'P' | Valid row labels |
| seats | seat_number > 0 | Positive seat number |
| seats | seat_class IN ('CLASSIC', 'PRIME', 'RECLINER') | Valid seat classes |
| movies | certificate IN ('U', 'UA', 'A') | Valid certificates |
| movies | duration_min > 0 | Positive movie duration |
| shows | ends_at > starts_at | Valid show timings |
| shows | base_price >= 0 | Non-negative ticket price |
| shows | format IN ('2D', '3D', 'IMAX', '4DX') | Valid show formats |
| offers | discount_pct BETWEEN 0 AND 100 | Valid discount percentage |
| offers | max_discount >= 0 | Non-negative maximum discount |
| offers | valid_to >= valid_from | Valid offer dates |
| customers | phone matches 10 digits | Valid mobile number format |
| bookings | num_tickets > 0 | At least one ticket |
| bookings | monetary amounts >= 0 | Prevent negative amounts |
| bookings | total_amount = ticket_amount + convenience_fee + fnb_amount - discount | Correct booking total |
| bookings | status IN ('PENDING', 'CONFIRMED', 'CANCELLED', 'PAYMENT_FAILED') | Valid booking status |
| bookings | payment_method IN ('UPI', 'CARD', 'GIFT_CARD', 'WALLET', 'NETBANKING') | Valid payment method |
| booking_seats | price >= 0 | Non-negative seat price |
| movie_reviews | rating BETWEEN 1 AND 10 | Valid movie rating |

### Preventing Show Overlap

Two shows on the same screen must never overlap. A normal CHECK constraint cannot compare the timing of different rows, so PostgreSQL's exclusion constraint can be used.

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;

ALTER TABLE shows
ADD CONSTRAINT no_overlapping_shows
EXCLUDE USING GIST (
    screen_id WITH =,
    tstzrange(starts_at, ends_at, '[)') WITH &&
);
```

The `[)` range allows one show to end at exactly the same time another show starts, without treating them as overlapping.

No additional performance indexes will be created in this phase. PostgreSQL automatically creates indexes for primary keys and UNIQUE constraints.

## 5. Functional Dependencies

A functional dependency describes how one column or a combination of columns determines other columns in a table.

The following dependencies are identified from the primary keys and candidate keys.

| Table | Functional Dependency |
|---|---|
| cities | city_id → city_name, state |
| venues | venue_id → venue_name, city_id, chain, address |
| screens | screen_id → venue_id, screen_name, screen_type, total_seats |
| seats | seat_id → screen_id, row_label, seat_number, seat_class |
| movies | movie_id → title, language, certificate, duration_min, release_date |
| shows | show_id → movie_id, screen_id, starts_at, ends_at, format, base_price |
| customers | customer_id → full_name, email, phone, city_id, created_at |
| offers | offer_code → description, discount_pct, max_discount, valid_from, valid_to |
| bookings | booking_id → booking_code, customer_id, show_id, booked_at, num_tickets, ticket_amount, convenience_fee, fnb_amount, offer_code, discount, total_amount, payment_method, status |
| booking_seats | (show_id, seat_id) → booking_id, price |
| movie_reviews | review_id → movie_id, customer_id, rating, review_text, created_at |

Other candidate keys include:

- `customers`: email and phone.
- `screens`: (venue_id, screen_name).
- `seats`: (screen_id, row_label, seat_number).
- `bookings`: booking_code.
- `booking_seats`: (show_id, seat_id).
- `movie_reviews`: (movie_id, customer_id).

## 6. Normalization

Normalization helps organize tables and reduce unnecessary duplication of data.

### First Normal Form (1NF)

Every table has a primary key, and each column stores a single value.

For example, a booking containing multiple seats does not store all seat IDs in one column. Each seat is stored as a separate record in `booking_seats`.

### Second Normal Form (2NF)

All tables are in 1NF, and non-key attributes depend on the complete candidate key.

This is especially important in `booking_seats`, where the primary key consists of both `show_id` and `seat_id`.

### Third Normal Form (3NF)

Non-key attributes should depend on the key and should not depend on other non-key attributes.

For example, city information is stored separately in `cities`. The `venues` and `customers` tables store only `city_id` instead of repeating city names and state information.

### BCNF

The tables are designed to satisfy BCNF where every determinant is a candidate key. The functional dependencies and candidate keys listed above should be used to verify this.

Some derived values are intentionally stored in the database for the given workload. These are discussed separately below.

## 7. Derived and Redundant Columns

Some columns contain values that can be calculated from other tables or columns. However, they are retained because they are useful for the project's queries and historical records.

| Column | Can Be Derived From | Reason for Keeping It |
|---|---|---|
| screens.total_seats | COUNT of seats for each screen | Useful for occupancy calculations. |
| bookings.ticket_amount | SUM of booking_seats.price for a booking | Stores the original ticket amount and supports revenue reports. |
| bookings.total_amount | ticket_amount + convenience_fee + fnb_amount - discount | Stores the final amount charged and is used in finance reports. |
| booking_seats.show_id | bookings.show_id | Helps enforce uniqueness of a seat for a particular show. |
| shows.ends_at | starts_at and movies.duration_min | Useful for show-overlap and cleaning-gap calculations. |

These values should remain consistent with their source data. For example, changing the seat prices should not leave the booking's stored ticket amount outdated.

The supplied data shows that `ends_at` is consistently 15 minutes after the movie duration added to `starts_at`. It is still stored because show end times are directly needed by the project queries.