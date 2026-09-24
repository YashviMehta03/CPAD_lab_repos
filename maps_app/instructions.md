# Map Demo App

Create a Flutter app called `map_demo_app` that demonstrates Google Maps and the user's current location.

## Requirements

### 1. Packages

Add:

* `google_maps_flutter`
* `geolocator`

Run `flutter pub get` after adding them.

### 2. Google Maps Setup

Configure the Google Maps API key for Android in the native Android configuration.

Add the required Android permissions:

* Internet
* Fine location
* Coarse location

### 3. Map Screen

Create a single screen containing:

* App bar with the title **Map Demo App**
* A Google Map filling the rest of the screen
* A floating action button for returning to the user's location

The map should start at a reasonable default location and zoom level.

### 4. User Location

When the screen loads:

* Request location permission if necessary.
* Get the user's current GPS coordinates.
* Enable the Google Maps "my location" indicator.
* Add a marker at the user's current location titled **"You are here"**.
* Move the camera to the user's location once it is available.

Handle denied permissions without crashing.

### 5. Other Markers

Add 2–3 predefined points of interest to the map.

Each marker should have:

* A title
* A short description

Tapping a marker should display its information window.

### 6. Re-center Button

The floating action button should animate the map camera back to the user's current location.

If the location is unavailable, show a simple message instead of crashing.

### 7. Verification

Run:

```bash
flutter analyze
flutter run
```

Verify that:

* The map loads.
* Location permission is requested.
* The current location is displayed.
* POI markers appear and can be tapped.
* The re-center button works.

Keep the implementation simple. Do not add authentication, backend services, databases, or unnecessary screens/packages.

If an API key is required but not provided, leave the configuration ready for the key and clearly indicate where it needs to be added.


google maps api to be used. use a placeholder for the api key