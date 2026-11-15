# Document 5: Sprint Backlog 2 — Reporting, Exploration, and Civic Cartography

**Branch:** `develop` (documented in `docs/sprint-2-3-backlogs`)  
**Status:** Planned  
**Sprint Goal:** Enable citizens to explore road infrastructure incidents in their city via an interactive map and a synchronized feed, switch active cities smoothly, and publish new damage reports with photographic evidence and precise georeferencing through a guided 5-step wizard with preventive duplicate detection.

---

## 1. Sprint 2 Overview

**Sprint 2** establishes the core content loop of VIGÍA. Without reports, there is no community or social interaction. Therefore, this sprint focuses on the **report generation lifecycle and territorial exploration**.

```
┌────────────────────────────────────────────────────────────────────────┐
│                          SPRINT 2 SCOPE                                │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Core Navigation & Permissions:                                      │
│    - BottomNavigationBar: Map (Mapa), Community (Comunidad), Profile. │
│    - Location permission request upon entering the map (HU-03).        │
│                                                                        │
│ 2. Guided Reporting Wizard (5-Step Wizard):                            │
│    - HU-06: Wizard launcher and unsaved changes discard guard.         │
│    - HU-07: Step 1 - Interactive map pin placement + geocoding.        │
│    - HU-08: Step 2 - Damage typology classification + severity.        │
│    - HU-09: Step 2.1 - Preventive nearby damage detection.             │
│    - HU-10: Step 3 - Photographic evidence (camera/gallery, max 3).    │
│    - HU-11: Step 4 - Detailed description and dimensions.              │
│    - HU-12: Step 5 - Confirmation, #VIG-XXXX code, and +100 XP.        │
│                                                                        │
│ 3. Cartographic & Community Exploration:                               │
│    - HU-13: General map view with typology-specific markers.           │
│    - HU-14: Report detail inspection view.                             │
│    - HU-19: Paginated community feed (20-item chunks) with pull-refresh│
│    - HU-21: Smart City Switcher (assisted modal with fuzzy search).    │
│    - HU-22: Guest / Unauthenticated browsing mode.                    │
│                                                                        │
│ 4. Geolocation Refinements (Deferred / Post-MVP):                      │
│    - HU-26: Assisted Reverse Geocoding via Nominatim.                  │
│    - HU-27: Interactive Map Pin Picker Widget.                         │
│    - HU-28: Direct Address Geocoding.                                  │
└────────────────────────────────────────────────────────────────────────┘
```

### Sprint 2 Progress & Tracking (~50% Milestone Achieved)

| User Story | Name | Scope / Responsibility | Status | Implementation Details |
|---|---|---|---|---|
| **HU-06** | Initiate a Report & Discard Guard | Reports / Wizard | **COMPLETED** | `ReportWizardScreen` with `PopScope` + draft discard confirmation |
| **HU-07 (MVP)** | Step 1: Location & Nomenclature | Reports / Wizard | **COMPLETED** | Real GPS (`geolocator`), nearest city (Haversine), structured Colombian address + reference point fallback |
| **HU-08** | Step 2: Typology & Severity | Reports / Wizard | **COMPLETED** | 7 Spanish categories with distinct vector icons, `SeverityChipSelector` (4 levels) |
| **HU-09** | Step 2.1: Proximity Duplicate Detection | Reports / Wizard | **COMPLETED** | Realtime 150m Haversine duplicate detection with endorsement modal |
| **HU-10** | Step 3: Photo Evidence | Reports / Wizard | **COMPLETED** | Up to 3 photos (camera/gallery), compressed, stored in Supabase `incident-evidence` |
| **HU-11** | Step 4: Description & Dimensions | Reports / Wizard | **COMPLETED** | Validated title, description, and optional dimensions |
| **HU-12** | Step 5: Review & Publish Report | Reports / Wizard | **COMPLETED** | #VIG-XXXX tracking code generation, Supabase insert, +100 XP credit |
| **HU-14** | Report Detail Inspection View | Reports / UI | **COMPLETED** | `IncidentDetailScreen` with photo carousel, tracking badge, rank seal, full audit data |
| **HU-03** | Location Permission on App Open | Explore / Shell | **COMPLETED** | The map asks for the permission on its first load (the OS stops asking once it is blocked: Android after two denials, iOS after one); granted → centered on the citizen; denied or blocked → city view, silent. The "Centrar en mi ubicación" button replaces the "Activar ubicación" banner |
| **HU-13 (MVP)** | Cartographic Map View & Markers | Explore / Map | **COMPLETED** | Shell with Mapa + Mi perfil tabs and the "Reportar daño" button; `flutter_map` (OpenStreetMap) centered on the profile city with severity-shaped markers that open the detail; a "Centrar en mi ubicación" button (top right) moves the map to the GPS position, with "Abrir ajustes" when the permission is blocked. On open it asks for the permission (HU-03) and centers on the citizen when granted; the button replaces the "Activar ubicación" banner (criterion 2); `last_city` arrives with HU-21 |
| **HU-19** | Paginated Community Feed | Explore / Feed | **PENDING** | 20-item chunks, pull-to-refresh, status badges |
| **HU-21** | Smart City Switcher | Explore / Modal | **PENDING** | Assistive modal with fuzzy search across Colombian cities |
| **HU-22** | Guest Browsing Mode | Auth / Explore | **COMPLETED** | "Explorar sin cuenta" on the login opens the shell without credentials; the map and report details read through the `anon` policies already in `schema.sql`; without a session the map opens on the covered city nearest to the GPS, or on Cali when there is no position (the HU-21 city prompt is still pending); "Reportar daño" stays visible and opens the "Necesitas iniciar sesión" modal (Ahora no · Crear cuenta · Iniciar sesión) without opening the wizard; "Mi perfil" shows the sign-in invitation and hides "Cerrar sesión"; signing in from there lands on the map like any citizen. Upvote and comment buttons do not exist yet (HU-19/HU-15): they must reuse the same modal |
| **HU-26** | Reverse Geocoding (Nominatim) | Reports / Location | **COMPLETED** | Opening the wizard with the location permission granted, every GPS reading ("Centrar en mi ubicación" on the Step 1 map) and every point confirmed on the map (HU-27) asks Nominatim (3 s timeout, identifying User-Agent) and overwrites road type, main road, cross street and number (when the plate comes as "5-37") and the neighborhood; the plate may use a hyphen or a typographic dash; without a plate, the cross street comes from a nearby corner: Nominatim returns the street's line, and up to four probes beside it (30 m to each side, 30 m ahead of and behind the citizen) answer a crossing street when a corner is within about 60 m, which must run the other way (on a Calle, a Carrera); a tap sends at most 6 requests; the address fills in first and the cross street afterwards, with the dotted ring and "Buscando…" in the main road and cross street fields meanwhile; requests are spaced 1.1 s apart (Nominatim's 1 per second rule); a failure or a missing cross street shows a notice asking to type it by hand; every field stays editable, with a "review it" notice (the OpenStreetMap credit stays on the map) |
| **HU-27** | Interactive Map Pin Picker | Reports / Location | **COMPLETED** | In Step 1 the "Seleccionar ubicación" button (it replaced "Mi GPS") swaps the address form for an OpenStreetMap map inside the same step, so the "Paso 1 de 5" header stays; the citizen pans the map under a fixed center pin, the coordinates update live, and "Confirmar punto" takes the point, resolves its city and suggests its address (HU-26) back in the form, which keeps what was typed; "Volver" returns without changes; the GPS lives on the map as the "Centrar en mi ubicación" button (blocked permission → HU-29 modal) |
| **HU-28** | Direct Address Geocoding | Reports / Location | **PENDING** | Text address to coordinates calculation |
| **HU-29** | Recover a Blocked Location Permission | Auth + Reports / Location | **COMPLETED** | Fixes KI-01: "Abrir ajustes" button when the permission is blocked |

---

## 2. Detailed User Stories

### HU-03: Request Location Permission Upon Entering Main Screen
**As a** user,  
**I want** the application to request location permissions upon entering the main screen (Map),  
**So that** I can view the map and feed centered on my physical location.

#### Acceptance Criteria
1. **Given that** I navigate to the main screen (HU-13), **when** I have not yet responded to the permission prompt, **then** the native OS dialog requests "while using the app" location access.
2. **Given that** I granted location access, **when** I open the map (HU-13) or community feed (HU-19), **then** both center dynamically on my current coordinates.
3. **Given that** I denied location access, **when** I open the screen, **then** the application operates without blocking or crashing and stays on my city (`last_city` (HU-21); today the reference city), with no error and no banner.
4. **Given that** I tap *"Centrar en mi ubicación"* on the map, **when** the operating system permits re-prompting, **then** permission is requested again; otherwise the *"Ubicación bloqueada"* modal offers *"Abrir ajustes"*. (Changed in Sprint 2: this button replaces the *"Activar ubicación"* banner.)
5. **Given that** my GPS coordinates are outside covered municipalities, **when** I enter the main screen with the permission granted, **then** the map still centers on my current position (RN-14, point 4; changed in Sprint 2).

---

### HU-06: Initiate a Report
**As a** registered citizen,  
**I want** to start a report from anywhere in the app,  
**So that** I can record road damage as soon as I spot it.

#### Acceptance Criteria
1. **Given that** I am in Map (HU-13) or Community (HU-19), **when** I tap the floating action button *"Reportar"*, **then** the wizard opens at Step 1 (HU-07).
2. **Given that** I navigate through the wizard, **when** I move forward or backward, **then** the step indicator displays the current step (e.g., *"Paso 2 de 5"*).
3. **Given that** I have already entered data in the wizard, **when** I attempt to exit or navigate back, **then** a confirmation dialog prompts me before discarding entered data.
4. **Given that** I have not entered any data yet, **when** I exit, **then** I return to the previous screen immediately without prompt.
5. **Given that** I am not authenticated (HU-22), **when** I tap *"Reportar"*, **then** a modal invites me to sign in or register, preventing wizard initialization.

---

### HU-07: Step (1) - Pinpoint Damage on Map
**As a** registered citizen,  
**I want** to mark the exact location of road damage on an interactive map,  
**So that** fellow citizens and auditors can accurately locate it.

#### Acceptance Criteria
1. **Given that** I granted location permissions, **when** I open Step 1, **then** the map centers on my coordinates with a target crosshair in the center.
2. **Given that** I denied location permissions, **when** I open Step 1, **then** the map centers on my last active city (`last_city`) (HU-21), allows manual panning/repositioning, and does not block the user.
3. **Given that** I set a map pin, **when** reverse geocoding is queried, **then** an approximate address and neighborhood (*barrio*) are proposed and can be edited.
4. **Given that** reverse geocoding lookup fails or is unavailable, **when** I attempt to proceed, **then** I can type the address and neighborhood manually, both being mandatory to advance.
5. **Given that** the pinned location falls outside Colombia's bounding box (Lat -4.2° to 13.5°, Lng -79.0° to -66.8°) or outside covered cities, **when** I attempt to continue, **then** an explanatory error prevents advancing.
6. **Given that** I do not have GPS or prefer manual lookup, **when** I search an approximate text address, **then** the map moves to that location and allows fine-tuning the pin.

---

### HU-08: Step (2) - Classify Damage Typology and Severity
**As a** registered citizen,  
**I want** to indicate the damage category and perceived severity,  
**So that** the community can quickly identify the problem type and urgency.

#### Acceptance Criteria
1. **Given that** I am in Step 2, **when** the screen loads, **then** I see the catalog categories in Spanish, each with its official icon and label.
2. **Given that** I must select severity, **when** I choose between *Baja*, *Media*, *Alta*, and *Crítica*, **then** each option is distinctly differentiated by shape, color, and text (per Design System §3.3).
3. **Given that** I have not selected a category or a severity level, **when** I attempt to proceed, **then** the missing fields are highlighted and advancing is blocked.
4. **Given that** category catalog loading fails, **when** the error is shown, **then** I can retry without losing the location data entered in Step 1 (HU-07).
5. **Given that** I type in the category search box, **then** the list dynamically filters matching types ignoring accents and case.
6. **Given that** I select a category and existing reports of that type exist near the pinned location, **when** proximity inspection completes, **then** a notice displays *"Hay N daños cercanos"* that can be tapped to inspect (HU-09).
7. **Given that** I change category, **when** a new category is selected, **then** the nearby count updates to match the newly selected type.
8. **Given that** no nearby reports of that type exist or check fails, **when** verification finishes, **then** no banner is shown and I can advance normally.

---

### HU-09: Step (2.1) - Inspect Nearby Damage Reports
**As a** registered citizen,  
**I want** to view nearby damage reports of the same category without losing my current draft,  
**So that** I can verify whether the issue is already reported before submitting a duplicate.

#### Acceptance Criteria
1. **Given that** the notice *"Hay N daños cercanos"* is displayed (HU-08), **when** I tap it, **then** I can inspect those reports in a modal/sheet without exiting Step 2.
2. **Given that** I am inspecting nearby reports, **when** I view an item, **then** I see its primary photo, typology icon, severity, and relative distance; if it lacks photos, a placeholder with its typology icon appears.
3. **Given that** I recognize my damage among the list, **when** I tap *"Es este daño"*, **then** I endorse that existing report (+1 upvote) and exit the wizard without publishing a duplicate; if I had already voted, my vote is preserved; if it is my own report, I exit without voting.
4. **Given that** my damage is distinct, **when** I tap *"Es otro daño"* or dismiss the view, **then** I return to Step 2 with my entered location, category, and severity intact.

---

### HU-10: Step (3) - Attach Photographic Evidence
**As a** registered citizen,  
**I want** to attach photographs of the road damage,  
**So that** my report is backed by verifiable visual evidence.

#### Acceptance Criteria
1. **Given that** I am in Step 3, **when** I choose to add a photo, **then** I can take a photo with the device camera or pick from the gallery.
2. **Given that** I have already attached 3 photos, **when** viewing Step 3, **then** the add button is disabled and the maximum limit is indicated.
3. **Given that** I select an invalid file type or an image exceeding 5 MB, **when** validated, **then** it is rejected with an explanatory message while preserving previously attached photos.
4. **Given that** I have no photos available, **when** I choose to skip this step, **then** I can advance without attachments.
5. **Given that** I attached multiple photos, **when** reviewing them, **then** I can remove any photo individually, and the first remaining photo acts as the primary cover image.

---

### HU-11: Step (4) - Describe Damage Details
**As a** registered citizen,  
**I want** to provide a title and detailed description of the road damage,  
**So that** the community understands the issue and its mobility impact.

#### Acceptance Criteria
1. **Given that** I attached or skipped photos (HU-10), **when** I reach Step 4, **then** fields for title, description, and optional dimensions are presented.
2. **Given that** I leave title or description empty or containing only whitespace, **when** I attempt to proceed, **then** validation errors appear and advancing is blocked.
3. **Given that** I enter a title exceeding 180 characters, **when** typing or attempting to continue, **then** character limit feedback is displayed.
4. **Given that** approximate dimensions are optional, **when** left blank, **then** I can continue without error.

---

### HU-12: Step (5) - Review and Publish Report
**As a** registered citizen,  
**I want** to review a consolidated summary and confirm publication,  
**So that** I obtain a public civic tracking code to track and share the issue.

#### Acceptance Criteria
1. **Given that** I completed previous steps (HU-07, HU-08, HU-10, HU-11), **when** I reach Step 5, **then** location, photos, category, severity, title, and description are summarized, and I can navigate back to edit any step without losing data.
2. **Given that** I confirm publication, **when** successfully saved in Supabase, **then** the report is created in `REPORTED` status with a unique tracking code (e.g., `#VIG-8492`) displayed on screen.
3. **Given that** the report is published, **when** I check my profile, **then** I have earned **+100 XP** and am registered as an automatic follower of my report.
4. **Given that** publication is processing, **when** the submit button is tapped repeatedly, **then** duplicate requests are prevented (loading state guard).
5. **Given that** network error or photo upload fails, **when** the error is reported, **then** all entered data is retained for retry, leaving no partial records or unearned XP.

---

### HU-13: View Incidents on Cartographic Map
**As a** citizen,  
**I want** to view reports as markers on an interactive map,  
**So that** I can visualize damage density across urban areas.

#### Acceptance Criteria
1. **Given that** I open the Map screen with location enabled and the permission granted, **when** loaded, **then** it centers on my current position and displays the markers of my city.
2. **Given that** location permissions were denied, **when** I open Map, **then** it centers on `last_city` (HU-21; today the reference city) and the *"Centrar en mi ubicación"* button lets me ask again (changed in Sprint 2: it replaces the *"Activar ubicación"* banner, HU-03).
3. **Given that** markers are rendered, **when** compared, **then** each marker displays a typology-specific icon (HU-08) without relying solely on color.
4. **Given that** my position is outside covered areas, **when** Map opens with the permission granted, **then** it still centers on my current position (RN-14, point 4; changed in Sprint 2 — previously it kept the `last_city` view with a banner).

---

### HU-14: View Report Details
**As a** citizen,  
**I want** to view comprehensive details of a report,  
**So that** I can assess the issue before endorsing or commenting on it.

#### Acceptance Criteria
1. **Given that** I tap a map marker, **when** the preview card opens, **then** summary information and vote count are displayed, with a button to open the full detail screen.
2. **Given that** I tap a report in Community feed (HU-19) or Map (HU-13), **when** detail opens, **then** tracking code, status, category, severity, title, description, dimensions, address, coordinates, and date are shown.
3. **Given that** the report includes photos (HU-10), **when** inspecting them, **then** I can swipe through a photo gallery; if none exist, a category placeholder is displayed.
4. **Given that** author information is rendered, **then** their full name (or *"Ciudadano anónimo"* if privacy is active) and civic rank are shown, and their email is never exposed.
5. **Given that** the endorsement progress bar is displayed, **when** the report has fewer than 10 votes, **then** progress is displayed as *"X de 10"* with a numerical and visual indicator.
6. **Given that** loading fails or the report no longer exists, **when** the error is surfaced, **then** a clear notice allows retrying or returning.

---

### HU-19: View Community Feed
**As a** citizen,  
**I want** to browse a chronological list of reports in my city,  
**So that** I can stay informed about neighborhood road conditions.

#### Acceptance Criteria
1. **Given that** I am authenticated, **when** using the bottom navigation bar, **then** I can navigate between Mapa (HU-13), Comunidad, and Mi perfil, with **Mapa** as the landing tab after authentication (RN-14; changed from Profile during Sprint 2).
2. **Given that** I open Comunidad, **when** data loads, **then** reports from my active city (HU-21) are displayed newest-first in 20-item chunks that expand as I scroll (infinite scroll).
3. **Given that** a report card is rendered, **when** inspected, **then** it displays primary photo, title, neighborhood (*barrio*), author name and rank, severity badge (HU-08), vote counter, and comment counter.
4. **Given that** a report has no photos, **when** its card is rendered, **then** a reserved space shows its category icon.
5. **Given that** I perform a pull-to-refresh, **when** update fails, **then** the existing list remains visible with a retry notice.
6. **Given that** the city has no reports yet, **when** loaded, **then** an empty state encourages publishing the first report (HU-06).

---

### HU-21: Switch Active City (Smart City Switcher)
**As a** citizen,  
**I want** to switch the city I am consulting,  
**So that** I can explore reports in other municipalities without traveling.

#### Acceptance Criteria
1. **Given that** I tap the city in the header, **when** the bottom sheet opens without search input, **then** up to 3 recent cities and quick chips for Bogotá, Medellín, Cali, Barranquilla, and Bucaramanga are displayed.
2. **Given that** I type in the search bar, **when** matching city or department names (ignoring accents and case, e.g., *"bogota"*), **then** 5 to 8 matching results appear in `City, Department` format.
3. **Given that** I select a city, **when** the sheet closes, **then** Map (HU-13) and Feed (HU-19) update to show that municipality.
4. **Given that** I am logged in and GPS is disabled, **when** I switch city, **then** `last_city` is updated in `user_profile` so subsequent sessions open in that city.
5. **Given that** I have active GPS and explore another city, **when** I tap *"Centrar en mi ubicación"*, **then** map returns to my physical location without altering `last_city`.

---

### HU-22: Browse Without an Account (Guest Mode)
**As a** visitor,  
**I want** to explore reports without registering,  
**So that** I can evaluate VIGÍA before creating an account.

#### Acceptance Criteria
1. **Given that** I am on the Login screen, **when** I tap *"Explorar sin cuenta"*, **then** I enter Map (HU-13) and Community (HU-19) without credentials.
2. **Given that** I am a guest and grant location, **when** I enter, **then** I see the nearest covered city; if denied or out of coverage, city selection is prompted (HU-21).
3. **Given that** I am a guest, **when** I attempt to Report (HU-06), Upvote, or Comment, **then** an authentication prompt invites me to sign in or register without performing the action.
4. **Given that** I am a guest, **when** I tap Perfil, **then** the same sign-in invitation replaces the civic dashboard.
5. **Given that** I sign in from the invitation modal, **when** completed, **then** I land on the map like any authenticated citizen.

---

### HU-26: Assisted Reverse Geocoding via OpenStreetMap (Nominatim)
**As a** citizen reporting road damage with GPS active,  
**I want** the application to automatically suggest the road type, main road number, and neighborhood based on my GPS coordinates,  
**So that** I do not have to type the street name manually when I am standing right at the scene.

#### Acceptance Criteria
1. **Given that** I open the wizard, use *"Centrar en mi ubicación"* or confirm a point on the Step 1 map (HU-27), **when** valid coordinates are detected, **then** the app asynchronously queries the free OpenStreetMap Nominatim reverse geocoding endpoint with compliant headers (User-Agent).
2. **Given that** Nominatim returns structured address tokens (`road`, `suburb`/`neighbourhood`, `city`), **when** received, **then** the form pre-populates the road type, road number, and neighborhood automatically.
3. **Given that** reverse geocoding is slow (>3s), rate-limited, or unavailable offline, **when** it fails, **then** the app keeps manual entry enabled without blocking the user and a notice says why the suggestion is missing or incomplete. (Changed in Sprint 2: the failure was silent; the citizen now gets feedback.)
4. **Given that** the suggested address is populated, **when** viewed by the user, **then** all fields remain fully editable for human verification.

---

### HU-27: Interactive Map Pin Picker Widget
**As a** citizen reporting road damage from a distance or without precise GPS,  
**I want** an interactive cartographic map widget in Step 1 where I can drag and drop a pin on the damaged street,  
**So that** I can accurately report issues located blocks away from my current physical position.

#### Acceptance Criteria
1. **Given that** I am on Step 1, **when** I tap *"Seleccionar ubicación"*, **then** an interactive map (`flutter_map` with OpenStreetMap raster tiles) renders centered on the current coordinates or default city center.
2. **Given that** I pan the map, **when** movement stops, **then** the central crosshair/pin updates the active report coordinates.
3. **Given that** I tap *"Confirmar punto"*, **when** pressed, **then** the coordinates are locked into the wizard draft and the user returns to address confirmation.

---

### HU-28: Direct Address Geocoding (Address to Estimated Coordinates)
**As a** citizen who knows the address but does not have GPS turned on,  
**I want** the app to calculate approximate coordinates when I type a Colombian street address,  
**So that** my report is positioned on the civic map without manual GPS calibration.

#### Acceptance Criteria
1. **Given that** I enter a structured Colombian address (e.g. `Carrera 9 # 45, Popayán`), **when** I tap *"Confirmar ubicación"*, **then** the system queries forward geocoding to resolve approximate latitude and longitude.
2. **Given that** forward geocoding succeeds, **when** resolved, **then** the coordinates card updates to show the resolved location.
3. **Given that** geocoding yields no results, **when** it fails, **then** the system defaults to the city center and allows the user to proceed with manual description.

---

### HU-29: Recover a Blocked Location Permission (KI-01)
**As a** citizen who blocked location access by mistake,  
**I want** the app to tell me that location is blocked and take me to the place where I can turn it back on,  
**So that** I can use GPS detection again without reinstalling the app or searching the phone settings on my own.

#### Acceptance Criteria
1. **Given that** location permission is blocked (Android: denied twice; iOS: denied once), **when** I tap *"Detectar mi ciudad por GPS"* at registration or *"Centrar en mi ubicación"* on the Step 1 map of the wizard (HU-07, HU-27), **then** I see *"El permiso de ubicación está bloqueado. Toca "Abrir ajustes" y luego Permisos → Ubicación."* with an *"Abrir ajustes"* button.
2. **Given that** I tap *"Abrir ajustes"*, **when** the operating system allows it, **then** the app's system settings screen opens.
3. **Given that** I enabled location in the settings, **when** I return to the app and tap the GPS button again, **then** the location is detected normally, with no restart.
4. **Given that** I return without enabling location, **when** I come back to the app, **then** the blocked notice remains and the city list or the manual address stays fully usable.
5. **Given that** the settings screen cannot be opened (e.g., on the web), **when** I tap *"Abrir ajustes"*, **then** a message explains how to enable location manually, and nothing crashes.
6. **Given that** location is only denied (not blocked), **when** I tap the GPS button, **then** the native permission dialog appears again and no settings button is shown.

---

## 3. Additional Work: Unplanned but Important

### KI-01 — Blocked location permission has no way out from the app
**Platform:** Android 11+

**Symptom:** If the user taps **"No permitir"** twice in the location dialog, the dialog never appears again. The app only shows *"El permiso de ubicación está bloqueado. Usa la lista de ciudades."* and offers no way to turn location back on.

---

## 4. Technical & Architectural Decisions for Sprint 2

### 4.1. Wizard Step Order Swap (UX Decision)
- **Previous Flow:** Location $\rightarrow$ Photos $\rightarrow$ Classification $\rightarrow$ Description $\rightarrow$ Publish.
- **Adopted Flow:** **Location (HU-07) $\rightarrow$ Classification & Severity (HU-08) $\rightarrow$ Nearby Duplicates Check (HU-09) $\rightarrow$ Photos (HU-10) $\rightarrow$ Description (HU-11) $\rightarrow$ Confirmation (HU-12).**
- **Rationale:** Prevents citizens from capturing and uploading heavy photos before learning that an identical issue was already reported nearby.

### 4.2. Business Rules Impacted in Sprint 2
1. **RN-01 (Report Integrity):** Title (≤ 180 chars), description, valid category, severity (`LOW`, `MEDIUM`, `HIGH`, `CRITICAL`), coordinates, address, and neighborhood are mandatory.
2. **RN-02 (Photographic Evidence):** 0 to 3 images in JPG, PNG, or WebP format, max 5 MB each, stored in Supabase Storage.
3. **RN-08 (Initial XP):** Atomic reward of **+100 XP** upon successful report publication.
4. **RN-12 (Geographic Delimitation):** Coordinates strictly validated within Colombia's continental bounding box and coverage catalog.
5. **RN-14 (Launch Location):** Location permissions requested upon entering Map; application remains 100% operational on denial via `last_city`.

### 4.3. Target Clean Architecture Structure
```text
lib/features/reports/
├── domain/
│   ├── entities/ (Incident, IncidentCategory, IncidentPhoto, NearbyIncident)
│   ├── repositories/ (IncidentRepository, CategoryRepository)
│   └── usecases/ (CreateIncidentUseCase, GetNearbyIncidentsUseCase, GetCategoriesUseCase, ReverseGeocodeUseCase)
├── data/
│   ├── datasources/ (IncidentRemoteDataSource, CategoryRemoteDataSource, GeocodingDataSource)
│   ├── models/ (IncidentModel, IncidentCategoryModel)
│   └── repositories/ (IncidentRepositoryImpl, CategoryRepositoryImpl)
└── ui/
    ├── bloc/ (ReportWizardBloc, IncidentDetailBloc)
    ├── screens/ (ReportWizardScreen, IncidentDetailScreen)
    └── widgets/ (SeveritySelector, LocationPinPicker, PhotoUploadBox)

lib/features/explore/
├── domain/
│   ├── repositories/ (FeedRepository)
│   └── usecases/ (GetCityIncidentsUseCase, SwitchCityUseCase)
├── data/
│   └── repositories/ (FeedRepositoryImpl)
└── ui/
    ├── bloc/ (ExploreBloc, CitySwitcherBloc)
    ├── screens/ (HomeScreen, MapTab, FeedTab)
    └── widgets/ (IncidentCard, SmartCitySwitcherSheet, LiquidIncidentCard)
```
