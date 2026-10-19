# Document 4: Architecture Resolutions, Backlog, and Design Decisions

Status as of October 2026 (`develop` branch).  
This document consolidates product, architecture, and data model decisions established by the engineering team, serving as the **single source of truth** regarding technical specifications and resolving discrepancies with exploratory UI mockups.

---

## 4.1. Primary Architectural Decision: VIGÍA Scope (100% Citizen-Led)
- **Adopted Decision: Option A (Exclusively Citizen-Led / Open Civic Oversight).**
- **Justification & Rationale:**
  - VIGÍA is created as a civic empowerment platform for peaceful citizen oversight, rather than a governmental single-window petition/grievance system (*PQRSD*).
  - Direct integration with public entities would require non-existent public APIs, administrative bureaucracy, and institutional agreements far beyond the scope and independence of an academic mobile engineering project.
  - The system focuses its value on precise georeferencing, collective backing (*upvotes*), neighborhood discussion threads, and transparent, verifiable impact metrics.

---

## 4.2. Coexistence Criteria with Visual Design Prototypes
The Stitch / Figma visual prototype is an **exploratory conceptual artifact**. To prioritize functional code and engineering delivery, the screens do not require redesigning; the technical documentation ([01-problem-statement](01-problem-statement-solution-actors.md), [02-architecture-screens-flows](02-architecture-screens-flows.md), [03-business-rules](03-business-rules.md), [schema.sql](../data%20model/schema.sql), and [seeds.sql](../data%20model/seeds.sql)) governs formal implementation:

1. **Procedural Traceability:** Prototype labels such as "Official Dispatch to Secretariat", "Legal Filing `#RAD-INF-99120`", and "72h Legal Deadline" are formally implemented as the **Public Civic Tracking Code** (e.g., `#VIG-8492`), report date, and community validation status.
2. **Government Entities & "Under Construction" State:** Functionally replaced by domain model statuses: `REPORTED`, `UNDER_REVIEW`, `COMMUNITY_VALIDATED`, and `RESOLVED`.
3. **Geographic Unification (Bogotá vs. Cali):** The prototype utilized mock data in both cities. The formal architecture unifies this through the **national official DANE coverage catalog** (Section 4.4.B).
4. **Community Validation Threshold:** Formally established at **10 community upvotes** per RN-08 and RN-10 (prototype texts such as "Goal: 60" or "40+ signatures" were illustrative).
5. **Wizard Form Fields:** The reporting wizard includes fields required by the relational schema: title, description, category, and severity (*Low, Medium, High, Critical*).
6. **Gamification Progression in Dashboard:** Governed by RN-09: Level 1 (0–999 XP), Level 2 (1,000–2,499 XP), Level 3 (2,500–3,999 XP), Level 4 (4,000+ XP).
7. **Badges Catalog:** Governed by the 5 master badges (`FIRST_CIVIC_STEP`, `ACTIVE_VOICE`, `POTHOLE_HUNTER`, `HIGH_IMPACT_REPORT`, `COMMUNITY_GUARDIAN`).
8. **Dashboard Metrics:** Tracks the 4 calculable metrics: *Reports Created*, *Upvotes Received*, *Upvotes Given*, and *Comments Posted*.
9. **Roles:** Operates under the unified **Citizen** role with honorary civic ranks.

---

## 4.3. Decisions on Authentication, Onboarding, and Notifications

### A. Local Native Authentication & Location Mitigation Workflow
* **Current Focus (100% Local Authentication):**
  - Native authentication via **Email + Hashed Password + Full Name**.
  - Guarantees verifiable academic evaluation, allows controlled test users, and eliminates external third-party dependencies during core sprints.
* **Future Social Login Compatibility (Google / Apple):**
  - The schema includes `auth_provider VARCHAR(30) NOT NULL DEFAULT 'LOCAL'` (allowed values: `'LOCAL'`, `'GOOGLE'`, `'APPLE'`) and nullable `password_hash` in `user_profile`.
  - Adding social authentication buttons in the future is purely a client-side addition requiring zero database migrations.
* **Registration Onboarding (Closed Dropdown & GPS Assist):**
  - Collects: Full name, email address, password, and **mandatory reference city** (`reference_city`).
  - **Closed & Validated Dropdown:** City selection is enforced via a **Dropdown selector** populated strictly from `coverage_city` (open string inputs forbidden to prevent typos or non-cataloged names).
  - **No Cali Default in Database:** Users must select their city or tap **"Detect my nearest city by location (GPS)"**, which calculates distances against the DANE catalog and preselects the closest city.
  - **Neighborhood and Commune Omitted in Onboarding:** Eliminates registration friction and allows reporting across any sector.
* **"When in use" Location Permission:**
  - Requested upon first launch to dynamically center the map and feed.
* **Mitigation Plans for Location Denial and Out-of-Coverage Areas:**
  - *Core Principle:* **Under no circumstance is the application blocked if a user denies location sharing.**
  1. *Permission Denied:*
     - Displays a non-intrusive top banner: *"Location disabled: exploring default city"*.
     - Includes an **"Enable Location"** button, re-prompting permission or opening OS settings via `openAppSettings()`.
     - Centers the map at the user's last known active city (`last_city`, initialized to `reference_city`).
  2. *Assisted City Switcher (Header Component):*
     - Header interactive bar that avoids mobile screen clutter.
     - **Modal / Bottom Sheet with Fuzzy Search:**
       - **Fuzzy Search / Typeahead:** Dynamic filtering tolerant to accents, case, and typing variations, limited to 5–8 results (`[City, Department]`).
       - **Initial Suggestions (Empty State):** Recent cities (up to 3) and quick chips for the top 5 capitals (Bogotá, Medellín, Cali, Barranquilla, Bucaramanga).
     - **Behavior by GPS State:**
       - **User without GPS:** Selecting a city (e.g., Bogotá while physically in Cali) navigates the map to Bogotá's urban center and updates `user_profile.last_city = 'Bogotá'`. Subsequent launches without GPS start directly in Bogotá.
       - **User with active GPS:** Viewing another city is exploratory; a floating *"Center on my location"* button returns to their physical position at any time.
  3. *App Launch with GPS in Rural / Out-of-Coverage Area:*
     - If coordinates fall outside cataloged cities, the app **does not guess or jump to unknown towns**: it preserves view on the **last active urban city** (`last_city`) with a subtle notification: *"You are currently outside VIGÍA urban coverage. Displaying your last active city"*.
  4. *Report Creation without GPS:* In Step 1 of the Wizard, the user can manually reposition the pin or search an approximate address.

---

### B. Notifications Module: Initial Architectural Reference Matrix
> [!NOTE]
> This matrix is an initial architectural reference guide to prepare event triggers in related modules. It will be refined during the dedicated notifications sprint.

* **Architecture:** Supported by the relational `notification` table in PostgreSQL, categorizing priority (Push) and silent (In-App) alerts.

#### Initial System Notification & Event Matrix

| Event Code | Trigger Event | Recipient | Delivery Channel | Notification Title | Message Template |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `COMMUNITY_VALIDATION` | Report reaches 10 upvotes | Report author | **Push + In-App** | Report Validated by the Community! | Your report "#{title}" in {neighborhood} reached 10 community upvotes. You earned +500 XP! |
| `RESOLUTION_PROPOSAL` | Neighbor submits repair photo proposal | Report author | **Push + In-App** | Resolution Proposal Received | A citizen submitted photographic evidence of repair for "#{title}". Tap to verify. |
| `REPORT_RESOLVED` | Report formally transitions to `RESOLVED` | Author & report followers | **Push + In-App** | Road Hazard Resolved! | Report #{tracking_code} in {neighborhood} has been verified as repaired. |
| `NEW_COMMENT` | New comment posted in thread | Author & followers | **In-App (Silent)** | New comment on report | {user_name} commented on report #{tracking_code}. |
| `NEW_UPVOTE` | Individual upvote increment on report | Report author | **In-App (Silent)** | New support received | A neighbor backed your report in {neighborhood} (+10 XP). |
| `RANK_UP` | User crosses XP threshold for a new rank | Active user | **In-App (Modal/Banner)** | Civic Rank Promotion! | Congratulations! You have been promoted to {rank_name}. |
| `NEW_BADGE` | User fulfills badge criteria | Active user | **In-App (Modal/Banner)** | New Badge Unlocked! | You earned the "{badge_name}" badge. |

---

## 4.4. Data Model Decisions and Resolved Enhancements

### A. Closure Mechanism, Concurrent Resolution, and Quorum
* **Concurrency Protection (Preventing Multiple Simultaneous Proposals):**
  - **Strict Rule:** **Only ONE (1) resolution proposal in `PENDING` status may exist per report simultaneously.**
  - **Rationale:** Multiple concurrent closure proposals fragment community attention.
  - **Database Level Guarantee:**
    ```sql
    CREATE UNIQUE INDEX idx_single_active_resolution 
    ON incident_resolution (id_incident) 
    WHERE status = 'PENDING';
    ```
  - **UI Behavior:** If a user clicks "Report as resolved" while a proposal is active, the app displays: *"A resolution proposal is currently undergoing community verification. You may confirm or review the existing evidence"*, navigating directly to the active proposal.

* **Approval Thresholds (Closing Report to `RESOLVED`):**
  1. *Author Approval:* If author taps **[Accept Solution]**, proposal becomes `APPROVED_BY_AUTHOR` and report updates to `RESOLVED`.
  2. *Community Approval:* If proposal accumulates **3 community confirmation votes** (`confirmation_votes >= 3`), proposal becomes `APPROVED_BY_COMMUNITY` and report updates to `RESOLVED`. Tracked in `resolution_confirmation` to prevent duplicate votes.

* **Rejection & Cancellation Thresholds (Releasing the Lock):**
  1. *Author Rejection:* Author taps **[Reject Solution]** with mandatory justification (`rejection_reason`). Proposal transitions to `REJECTED_BY_AUTHOR`.
  2. *Community Objection:* If community identifies invalid evidence, **3 objections** in `resolution_objection` (`objection_votes >= 3`) transition proposal to `REJECTED_BY_COMMUNITY`.
  3. *Timeout Expiration:* If 7 days elapse without reaching 3 confirmation votes or author response, proposal transitions to `EXPIRED`.
  - **Lock Release:** Rejection or expiration frees the lock, enabling any citizen to file a new proposal with valid evidence.

---

### B. Official DANE Urban Coverage Catalog and `coverage_city` Table
* **Master Table Definition:**
  Master table `coverage_city` with urban centroid coordinates (`center_latitude`, `center_longitude`) and `is_capital` flag.
* **Official DANE Demographic Criteria:**
  1. **The 32 Departmental Capitals:**
     - Cali, Bogotá, Medellín, Barranquilla, Cartagena, Bucaramanga, Cúcuta, Pereira, Santa Marta, Ibagué, Pasto, Manizales, Neiva, Villavicencio, Armenia, Valledupar, Montería, Sincelejo, Popayán, Tunja, Riohacha, Florencia, Quibdó, Yopal, San Andrés, Mocoa, Arauca, San José del Guaviare, Leticia, Inírida, Mitú, Puerto Carreño.
  2. **Non-Capital Municipalities with Urban Population > 100,000 Inhabitants or Metropolitan Areas:**
     - *Valle del Cauca:* Palmira, Buenaventura, Tuluá, Cartago, Jamundí, Yumbo.
     - *Antioquia:* Bello, Itagüí, Envigado, Rionegro.
     - *Atlántico:* Soledad.
     - *Santander:* Floridablanca, Barrancabermeja.
     - *Cundinamarca:* Soacha, Chía, Zipaquirá, Facatativá.
     - *Boyacá:* Duitama, Sogamoso.
* **Explicit Exclusions:** National concessioned highways (ANI) and rural dirt roads. Coordinates bounded by continental Colombian borders (Latitude: -4.2° to 13.5°, Longitude: -79.0° to -66.8°).

---

### C. Best Practices: Separation between DDL (`schema.sql`) and DML (`seeds.sql`)
1. **Separation of Concerns (DDL vs DML):**
   - [`schema.sql`](../data%20model/schema.sql) contains strictly pure structural definitions (`CREATE TABLE`, foreign keys, integrity constraints, and indexes).
   - [`seeds.sql`](../data%20model/seeds.sql) contains master initialization seed data (`INSERT INTO` for civic ranks, incident categories, badges, and DANE coverage cities).
2. **Preparedness for Migration Frameworks:**
   - In production workflows (Prisma, Drift, Flyway, Supabase Migrations), separating schema and seeds ensures idempotent, automated migrations (`V1__schema.sql`, `V2__seeds.sql`).
3. **Isolation for Testing Fixtures:**
   - Enables spin-up of clean test database instances without carrying unnecessary static seed rows when custom test mocks are required.
