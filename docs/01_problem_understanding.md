# Phase 1 – Problem Understanding

**Project:** BookMyShow Movie & Event Ticketing Database  
**Team:** T0112 | **Lead:** Vansh Kumar | **Date:** November 2026  
**Database:** PostgreSQL 15+

## What is the system?

BookMyShow is a movie and event ticket booking platform where customers can search for movies, check showtimes and book cinema seats. A venue can have multiple screens, each with its own seating arrangement. Customers can select seats, make payments, use discount offers and optionally purchase food and beverages.

The existing database has no documented schema, and only 11 CSV files containing the exported data are available. Several teams have reported slow queries, delays in booking operations and reports that return incorrect or empty results.

The main objectives of this project are to rebuild the database schema, measure the performance of the 30 provided SQL queries, optimize them without changing their results, and test whether the database can handle 20× more data.

## Problem-by-Problem Analysis

### P1 — Now Showing, Showtimes and Search pages are slow
- **Queries:** R01, R02, R06
- **Stakeholder:** Movie-goers (Customer app)
- **Business need:** Customers need to quickly find movies showing in their city, check showtimes and search for movies by title. These pages are particularly important on Friday mornings when customer activity is high.
- **Type:** Customer-facing / real-time

### P2 — Seat layout and seat locking are too slow
- **Queries:** R03, W01, W02
- **Stakeholder:** Movie-goers and Booking engine
- **Business need:** Customers should be able to view available seats and book them without delays. The system must also prevent two customers from booking the same seat for the same show.
- **Type:** Customer-facing / real-time

### P3 — Payments and seat-lock expiry jobs are delayed
- **Queries:** R09, W03, W04
- **Stakeholder:** Payments / Seat-lock service
- **Business need:** Pending payments, booking confirmations and seat-lock expiry operations should happen on time. Seats held by bookings that do not complete payment should be released so other customers can book them.
- **Type:** Customer-facing / real-time

### P4 — My Bookings, booking lookup and sign-in are slow
- **Queries:** R04, R05, R22, R23
- **Stakeholder:** Movie-goers and Support team
- **Business need:** Customers should be able to access their bookings and sign in using their mobile numbers quickly. Support staff also need to find booking details using a booking code.
- **Type:** Customer-facing / real-time

### P5 — Cinema managers need occupancy and seat information
- **Queries:** R07, R10, R17, R25
- **Stakeholder:** Cinema / Venue managers and Programming team
- **Business need:** Cinema managers need to check show occupancy, identify seats that have never been sold and ensure there is enough time between consecutive shows for cleaning. Programming teams also need information about late-night show occupancy.
- **Type:** Reporting / analytics

### P6 — Offers that have never been redeemed
- **Queries:** R13
- **Stakeholder:** Partnerships team
- **Business need:** The partnerships team needs to identify offers that have never been used by customers. The current report always returns an empty result, making it difficult to track unused offers.
- **Type:** Reporting / analytics

### P7 — Distributors need box-office and per-show reports
- **Queries:** R08, R19, W05
- **Stakeholder:** Distributors
- **Business need:** Distributors need movie collections and ticket counts for individual shows, especially during release weekends. W05 also covers updating prices for July weekend shows of movie 2.
- **Type:** Reporting / analytics

### P8 — Finance and analytical reports are timing out
- **Queries:** R11, R12, R14, R15, R16, R18, R20, R21, R24
- **Stakeholder:** Finance and Insights teams
- **Business need:** These teams need reports about ticket revenue, customer booking patterns, movie ratings, regional collections, cancellation rates, loyalty and ticket pricing. The existing reports are slow, and the expected 20× growth in data may make them even slower.
- **Type:** Reporting / analytics

## Assumptions

1. A venue can have multiple screens, and each screen has a fixed seating arrangement.
2. Every show belongs to one movie and one screen. Two shows on the same screen must not overlap.
3. A seat can be sold only once for a particular show.
4. A customer can make multiple bookings, and each booking belongs to one customer and one show.
5. Applying an offer is optional, so `offer_code` may be NULL.
6. Review text is optional, so `review_text` may be NULL.
7. All database constraints must be checked against the 11 CSV files to ensure that the existing data loads without errors.