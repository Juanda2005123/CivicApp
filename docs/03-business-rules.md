# Document 3: System Business Rules

## 3.1. Rules on Reports
* **RN-01 (Report Integrity):** Every report must mandatorily record: latitude, longitude, reference address, neighborhood, descriptive title, problem description, and a valid category.
* **RN-02 (Photographic Evidence):** Each report supports between 0 and 3 attached photographs in JPG, PNG, or WebP formats, with a maximum size of 5 MB per file.
* **RN-03 (Report Edit and Deletion Window):**
  * The author of a report may edit its text/photos or delete it **strictly within the first 30 minutes** following its publication, provided the report has **fewer than 5 upvotes**.
  * If the report exceeds 30 minutes of age or accumulates 5 or more community upvotes, it becomes permanently frozen and cannot be modified or deleted by the author, safeguarding the authenticity of accumulated citizen backing.

## 3.2. Rules on Community Interaction
* **RN-04 (Single Upvote / Toggle Mechanism):** An authenticated user can cast only one upvote per report. Tapping the upvote button on an already backed report revokes the vote (*toggle vote*).
* **RN-05 (Self-Vote Prohibition):** A user cannot vote on their own reports under any circumstance.
* **RN-06 (Moderation, Attachments, and Comment Deletion):**
  * Only registered users can post comments in report threads.
  * **Optional Photographic Evidence:** Each comment may optionally attach up to one (1) photograph as visual complement or road condition follow-up (JPG, PNG, or WebP format, maximum 5 MB). This is not mandatory to comment.
  * Comments are immutable (no text editing or image replacement) to preserve the chronological integrity of the thread.
  * **Deletion Window:** The author of a comment can **delete it exclusively within the first 5 minutes** following publication (removing both text and attached photo). After this time, the comment is permanent.
* **RN-07 (Subscription and Notifications):** Any authenticated user (other than the author) can toggle tracking on a report to receive notifications regarding new comments or community milestones. The author is subscribed automatically by default.

## 3.3. Rules on Gamification and Experience Points (XP)
* **RN-08 (XP Acquisition Schedule):**
  * **Publishing a new report:** **+100 XP** awarded at the moment of publication.
  * **Community Validation Bonus:** **+500 XP** awarded automatically to the author when their report reaches **10 upvotes** for the first time.
  * **Per upvote received on own reports:** **+10 XP** for the author per individual vote gained.
  * **Backing another's report (casting upvote):** **+10 XP** for the voting user.
  * **Posting a constructive comment:** **+15 XP** for the commenter.
  * **Vote revocation penalty:** If a user retracts their upvote, **-10 XP** is deducted from the voter and **-10 XP** from the report author. If revocation reduces total votes below 10, the validation bonus is not revoked if already consolidated.
* **RN-09 (Civic Ranks Scale):**
  * *Level 1 - Urban Observer:* 0 to 999 XP.
  * *Level 2 - Active Neighbor:* 1,000 to 2,499 XP.
  * *Level 3 - Road Guardian:* 2,500 to 3,999 XP.
  * *Level 4 - Master Overseer:* 4,000+ XP.
  * *Note:* Each rank is defined by `civic_rank.min_xp` (0, 1000, 2500, and 4000). A user's rank corresponds to the highest `min_xp` that does not exceed their `experience_points`.
* **RN-10 (Automatic Badge Awards):** Badges are awarded synchronously upon meeting the following cumulative conditions:
  * *First Civic Step:* Awarded upon publishing the first report.
  * *Active Voice:* Awarded upon posting 10 comments in community discussions.
  * *Pothole Hunter:* Awarded upon publishing 5 reports in the "Pothole or Road Hazard" category.
  * *High-Impact Report:* Awarded when a personal report achieves community validation (10 upvotes).
  * *Community Guardian:* Awarded upon granting 50 upvotes to fellow neighbors' reports.

## 3.4. Rules on Report Resolution
* **RN-11 (Civic Resolution, Single Active Proposal, and Cross-Verification):**
  * To mark a report with status `RESOLVED`, it is mandatory to submit recent photographic evidence (1 photo) demonstrating that the road damage has been repaired or patched, accompanied by a description of current conditions.
  * **UI Interaction & Independent Entity:** The report detail screen features a dedicated button *"Report as Repaired/Resolved"* that opens a specialized modal, creating a record in the decoupled `incident_resolution` entity (storing the photo URL in `photo_evidence_url`).
  * **No-Bifurcation Rule (Single Active Proposal):** Only **one (1) resolution proposal in `PENDING` status may exist per report simultaneously** (enforced by the unique index `idx_single_active_resolution`). If another user attempts to submit a resolution while one is pending, the system redirects them to the active proposal.
  * **Frontend Display:** The active proposal is rendered as a prominent pinned card with a green border at the top of the report discussion thread.
  * **Resolution by Original Author:** If the report author submits repair evidence, the report transitions directly to `RESOLVED` (`APPROVED_BY_AUTHOR`).
  * **Resolution by Non-Author Citizen:** If a citizen other than the author submits the resolution proposal:
    * The author is immediately notified with options to **[Accept Solution]** or **[Reject]**.
    * **Community Approval:** If the proposal accumulates **3 community confirmation votes** via `resolution_confirmation` (`confirmation_votes >= 3`), the system automatically updates the report to `RESOLVED` (`APPROVED_BY_COMMUNITY`).
  * **Proposal Rejection and Cancellation:**
    * *Author Rejection:* The author can click **[Reject]** with a mandatory explanation (`rejection_reason`). The proposal transitions to `REJECTED_BY_AUTHOR`.
    * *Community Objection:* If neighbors identify fraudulent or invalid evidence, with **3 community objections** in `resolution_objection` (`objection_votes >= 3`), the proposal transitions to `REJECTED_BY_COMMUNITY`.
    * *Expiration:* If 7 days elapse without reaching quorum or receiving author response, the proposal transitions to `EXPIRED`.
    * Upon rejection or expiration, the concurrency lock is released, allowing any citizen to submit a new valid proposal.
  * **Civic Reward for Verification:** Successful resolution awards a **+50 XP** bonus to the user who submitted the accepted evidence.

## 3.5. Rules on Geographic Scope
* **RN-12 (Territorial Delimitation and Official DANE Urban Catalog):**
  * VIGÍA operates across the road infrastructure and urban public space of major Colombian cities registered in the `coverage_city` catalog:
    1. The 32 departmental capital cities of Colombia.
    2. Non-capital municipalities with an urban population exceeding 100,000 inhabitants or belonging to consolidated metropolitan areas (e.g., Palmira, Tuluá, Buenaventura, Soledad, Bello, Itagüí, Soacha, Floridablanca).
  * Rural unpaved trails (*trochas*) and national concessioned highways (ANI / Invías) are excluded.
  * Coordinates must fall strictly within the continental Colombian bounding box (Latitude between -4.2° and 13.5°, Longitude between -79.0° and -66.8°).

## 3.6. Rules on System Notifications
* **RN-13 (Generation, Persistence, and Initial Civic Notification Matrix):**
  * The system persistently stores all civic events in the `notification` table to feed the Alert Center (Bell icon).
  * *Technical Architecture Note:* The defined notification matrix is an initial architectural reference guide; it is subject to refinement during the dedicated notifications sprint.
  * **Priority / Push Notifications:**
    1. *`COMMUNITY_VALIDATION`:* When a personal report reaches 10 upvotes.
    2. *`RESOLUTION_PROPOSAL`:* When a neighbor submits photographic evidence suggesting an author's report has been repaired.
    3. *`REPORT_RESOLVED`:* When a followed or authored report is formally marked as resolved.
  * **In-App Silent Notifications:**
    1. *`NEW_UPVOTE`:* Individual upvote increments on published reports.
    2. *`NEW_COMMENT`:* New discussion contributions in subscribed reports.
    3. *`RANK_UP` and `NEW_BADGE`:* Gamification milestones celebrated via interactive modals or banners in active sessions.

## 3.7. Rules on Authentication, Onboarding, and Profile Summary
* **RN-14 (Registration, Location Handling, and Profile Redirection):**
  * **Registration:** Requires full name, unique email, secure hashed password, and mandatory reference city selection (`reference_city`) via a **closed Dropdown selector** populated from `coverage_city` (open string inputs forbidden). Includes the **"Detect my nearest city by location (GPS)"** option to preselect the closest city. Neighborhood/commune is omitted to eliminate onboarding friction.
  * **"When in use" Location Permission:** Requested upon app launch to dynamically center the map and feed on the user's position.
  * **Mitigation Plans for Location Denial and Out-of-Coverage Areas:**
    1. *Permission Granted:* Automatic centering on live GPS coordinates.
    2. *Permission Denied:* App remains 100% operational. Displays a non-intrusive banner with an **"Enable Location"** button (re-prompting permission or opening OS settings via `openAppSettings()`) and positions the map at the user's last known active city (`last_city`).
    3. *Assisted City Switcher (Header Component):* Accessible to all users, avoiding mobile screen saturation. Features **Fuzzy Search** (accent- and case-tolerant, 5–8 results) and one-tap quick chips for recent cities and the top 5 capitals (Bogotá, Medellín, Cali, Barranquilla, Bucaramanga). If a user without GPS searches another city (e.g., Bogotá), the map navigates there and updates `last_city = 'Bogotá'` for future launches.
    4. *Launch in Rural / Out-of-Coverage Area:* If GPS coordinates fall outside cataloged urban cities, the app preserves view on the last active urban city (`last_city`) with a subtle informational notice.
    5. *Report Creation without GPS:* The user can manually position the map pin or search an approximate address via text.
  * **Immediate Post-Login Redirection:** Following authentication (registration or login), the system navigates directly to the **Profile Summary Screen (Civic Dashboard)**, displaying avatar, initial rank (*Urban Observer*), XP balance, reference city, and personal impact statistics.
