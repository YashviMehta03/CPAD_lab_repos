-- room_bookings: students can no longer book rooms (find-only), so nothing writes to it.
-- help_pings: the 30-minute ping limit now reads the notifications table instead.
DROP TABLE IF EXISTS room_bookings;
DROP TABLE IF EXISTS help_pings;
