# Document 6: Sprint Backlog 3 — Community Interaction, Lifecycle, Gamification, and Notifications

**Branch:** `develop` (documented in `docs/sprint-2-3-backlogs`)  
**Status:** In progress. HU-01, HU-02, HU-04, HU-05, HU-15, HU-16, HU-17, HU-18, HU-20 and HU-23 are implemented on `develop`, HU-25 (PR #23), and HU-24 on `feat/hu-24-push-notifications` (details in `docs/07-sprint-handoff-status.md`, section 4).  
**Sprint Goal:** Activate VIGÍA's participatory community loop: enable citizen endorsement (*upvotes*), collective validation upon reaching 10 votes (+500 XP), neighborhood discussion threads with photographic evidence, strict time-window moderation for reports and comments, live impact dashboard with gamified rank progression, complete profile/privacy settings, and academic-requirement **push notifications**.

---

## 1. Sprint 3 Overview

**Sprint 3** transforms the application from a report repository into an **active civic auditing and mutual accountability platform**. It implements collective validation, civic reputation, profile privacy, and push notification triggers for critical events.

```
┌────────────────────────────────────────────────────────────────────────┐
│                          SPRINT 3 SCOPE                                │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Social Voice & Endorsements:                                        │
│    - HU-15: Toggle upvote mechanism (+1 upvote) with XP exchange.      │
│    - HU-16: Community validation tracking (10 votes = +500 XP).        │
│    - HU-17: Chronological comment threads with optional photo evidence.│
│    - HU-18: Report editing and deletion (strict 30-minute window).     │
│                                                                        │
│ 2. Advanced Search & Filtering:                                        │
│    - HU-20: Filtering by category/neighborhood and sorting (Votes,    │
│             Date, Distance) synchronized between Map and Feed.         │
│                                                                        │
│ 3. Civic Identity, Privacy & Settings:                                 │
│    - HU-01: Civic privacy (hide real name / "Ciudadano anónimo").      │
│    - HU-02: Device permissions management from profile settings.       │
│    - HU-04: Edit profile information, email change, and password reset.│
│    - HU-05: Avatar upload and customization (up to 5 MB).              │
│                                                                        │
│ 4. Gamification & Civic Impact:                                        │
│    - HU-23: Live impact dashboard with 4 computed metrics, reactive    │
│             rank recalculation, and "Mis reportes" management.         │
│                                                                        │
│ 5. Academic & Course Requirements:                                     │
│    - HU-24: Push notifications for ≥ 2 mandatory civic events.         │
│    - HU-25: Community Resolution Proposal & Verification (RN-11).      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Detailed User Stories

### HU-15: Endorse a Report (*Upvote*)
**As a** registered citizen,  
**I want** to endorse reports submitted by fellow citizens,  
**So that** critical road hazards gain visibility for community action.

#### Acceptance Criteria
1. **Given that** I have not endorsed another citizen's report, **when** I tap *Apoyar*, **then** the counter increments by 1, the button reflects active endorsement with icon and text, I receive **+10 XP**, and the report author receives **+10 XP**.
2. **Given that** I already endorsed the report, **when** I tap it again, **then** my endorsement is revoked (*toggle*), the counter decrements by 1, and both the author and I lose the 10 XP previously granted.
3. **Given that** I am the author of the report, **when** viewing my report (HU-16), **then** the endorsement button is hidden; any direct API attempt is rejected by server rules (RN-05).
4. **Given that** I tap the button repeatedly in rapid succession, **when** touches are processed, **then** only one endorsement per user is registered (debouncing and DB unique constraint).
5. **Given that** the network request fails, **when** the error is reported, **then** counter and button revert to their previous state and XP balances remain untouched.

---

### HU-16: Track Report Community Validation
**As an** author of a report,  
**I want** to see how many endorsements are needed to reach community validation,  
**So that** I know how much civic backing my submission has gathered.

#### Acceptance Criteria
1. **Given that** I open my own report, **when** details load (HU-14), **then** the author view is presented without an endorsement button (HU-15).
2. **Given that** it has fewer than 10 endorsements, **when** viewing the validation card, **then** it displays *"X de 10 apoyos"* and *"Faltan Y apoyos para validar este reporte (+500 XP)"*.
3. **Given that** it receives its 10th endorsement for the first time, **when** recorded, **then** status transitions automatically to `COMMUNITY_VALIDATED` and I receive the **+500 XP** validation bonus (RN-08).
4. **Given that** the report is validated, **when** viewed by any citizen, **then** the prominent *"Reporte validado por la comunidad"* seal is displayed with shape, color, and text.
5. **Given that** a validated report drops below 10 endorsements due to vote revocation, **when** recalculated, **then** the 500 XP bonus remains consolidated; subsequent re-attainment of 10 votes does not award the bonus again.

---

### HU-17: Comment on a Report
**As a** registered citizen,  
**I want** to comment on a report and optionally attach a photo,  
**So that** I can provide additional context or document repair progress over time.

#### Acceptance Criteria
1. **Given that** I open a report (HU-14), **when** inspecting the discussion thread, **then** comments appear in chronological order (oldest to newest) with author, civic rank, timestamp, text, and optional photo.
2. **Given that** I write text, **when** submitted, **then** the comment appears in the thread, input clears, and I earn **+15 XP**.
3. **Given that** I attach a photo without entering text, **when** submitted, **then** the comment publishes with photo alone and awards **+15 XP**.
4. **Given that** I attach a photo, **when** validated, **then** only 1 image in JPG, PNG, or WebP format up to 5 MB is accepted; otherwise, an explanatory rejection message appears.
5. **Given that** I posted a comment less than 5 minutes ago, **when** I choose *Eliminar* and confirm, **then** text and photo are removed, and 15 XP are deducted.
6. **Given that** more than 5 minutes have elapsed, **when** viewing my comment, **then** the delete option is no longer available; text editing is never permitted (RN-06), and late deletion requests are rejected by the server.
7. **Given that** submission fails, **when** the error is reported, **then** entered text and photo are preserved for retry.

---

### HU-18: Edit or Delete My Report
**As an** author of a report,  
**I want** to edit or delete my report shortly after publication,  
**So that** I can fix mistakes without compromising accumulated community backing.

#### Acceptance Criteria
1. **Given that** my report was published less than 30 minutes ago and has fewer than 5 endorsements (HU-15), **when** I open its author view (HU-16), **then** *Editar* and *Eliminar* actions are available.
2. **Given that** I edit text or photos, **when** saved, **then** the report retains its tracking code `#VIG-XXXX` and enforces the same validation rules as initial publication.
3. **Given that** I choose *Eliminar*, **when** confirmed in the dialog, **then** the report and its photos are removed from feed (HU-19) and map (HU-13), and the 100 XP awarded for publication are revoked.
4. **Given that** the report exceeds 30 minutes of age or reaches 5 endorsements, **when** opened, **then** modification actions are hidden and the report appears frozen to safeguard community evidence.
5. **Given that** the screen was open when the 30-minute window expired, **when** save or delete is attempted, **then** the server rejects the request with an explanatory message.

---

### HU-20: Search, Filter, and Sort Reports
**As a** citizen,  
**I want** to search, filter, and sort reports in the Community screen,  
**So that** I can locate issues relevant to my route or neighborhood.

#### Acceptance Criteria
1. **Given that** I type in the search bar, **when** text matches description, title, or address, **then** the list filters to matching reports ignoring accents and case.
2. **Given that** I select a category or neighborhood, **when** applied, **then** only reports matching the selection are shown.
3. **Given that** I switch sort order, **when** choosing *Más votados*, *Más recientes*, or *Más cercanos*, **then** the list reorders accordingly.
4. **Given that** location permissions were denied, **when** choosing *Más cercanos*, **then** an explanation prompts enabling location while maintaining the previous order.
5. **Given that** filters were applied in Comunidad (HU-19), **when** switching to Mapa (HU-13), **then** matching filters remain active on map pins.
6. **Given that** no reports match active filters, **when** rendered, **then** an empty state notice offers a single-tap button to clear all filters.
7. **Given that** I am searching or filtering, **when** viewing the screen, **then** the active city name is prominently displayed.

---

### HU-01: Manage My Privacy
**As a** registered citizen,  
**I want** to decide whether my full name is publicly visible,  
**So that** I control what personal information is exposed to other users.

#### Acceptance Criteria
1. **Given that** I open the configuration view in my profile, **when** viewing *"Privacidad"*, **then** the toggle *"Mostrar mi nombre"* is shown with its current status.
2. **Given that** I disable *"Mostrar mi nombre"*, **when** saved, **then** my reports and comments (including historical ones) display *"Ciudadano anónimo"* instead of my real name, while preserving my honorary civic rank.
3. **Given that** my name was hidden, **when** I re-enable *"Mostrar mi nombre"*, **then** my real name reappears on all my contributions.
4. **Given that** saving fails, **when** error is displayed, **then** the toggle reverts to its previous state.

---

### HU-02: Manage Device Permissions
**As a** registered citizen,  
**I want** to manage camera and location permissions from within the app,  
**So that** I know and control how my device capabilities are used.

#### Acceptance Criteria
1. **Given that** I open settings in my profile, **when** viewing *"Permisos"*, **then** camera and location permissions are displayed with their current status in plain text.
2. **Given that** the app has not requested camera access yet, **when** tapped, **then** the native OS permission prompt opens.
3. **Given that** permission was previously answered, **when** tapped, **then** device OS settings are opened, and status updates upon returning to the app.
4. **Given that** camera access is denied, **when** attaching photos, **then** gallery selection works normally without crashing.
5. **Given that** location access is denied, **when** creating a report or exploring the map, **then** manual pin placement and city selection remain fully operational.

---

### HU-04: Edit Personal Information
**As a** registered citizen,  
**I want** to update my name, city, email, and password,  
**So that** my account remains accurate and protected.

#### Acceptance Criteria
1. **Given that** I open profile settings, **when** viewing *"Datos personales"*, **then** current name, city, email, and the password change option are shown.
2. **Given that** I enter a name with fewer than two words, **when** attempting to save, **then** validation error prevents saving.
3. **Given that** I change my reference city, **then** selection is restricted to the closed official DANE catalog or GPS assist.
4. **Given that** I enter an invalid or already registered email, **when** attempting to save, **then** a clear rejection message appears.
5. **Given that** I enter a valid new email, **when** saved, **then** the app instructs confirming verification from the new inbox before taking effect.
6. **Given that** I update my password, **when** current password is wrong or new password violates complexity (6+ chars, uppercase, lowercase, digit), **then** validation feedback prevents updating.
7. **Given that** update fails, **when** error is shown, **then** draft inputs are preserved for retry.

---

### HU-05: Customize Civic Avatar
**As a** registered citizen,  
**I want** to add or update my profile avatar,  
**So that** other community members can visually identify my contributions.

#### Acceptance Criteria
1. **Given that** I am in *"Datos personales"*, **when** tapping my avatar, **then** I can take a photo or select from gallery.
2. **Given that** I choose an invalid format or an image over 5 MB, **when** validated, **then** it is rejected and my current avatar is kept.
3. **Given that** I select a valid image, **when** upload finishes, **then** my avatar updates on my profile and in past and future comments.
4. **Given that** I have not uploaded an avatar, **when** my profile or comment is rendered, **then** the default brand seal is displayed.
5. **Given that** image upload to Supabase Storage fails, **when** error occurs, **then** my previous avatar remains unchanged and I can retry.

---

### HU-23: View My Civic Impact Dashboard
**As a** registered citizen,  
**I want** to view my personal impact metrics, rank, and submitted reports,  
**So that** I understand the real-world value of my civic participation.

#### Acceptance Criteria
1. **Given that** I open Mi perfil, **when** data loads, **then** avatar, name (or anonymous indicator), role (*Ciudadano*), residence city, rank seal, XP points, and progress bar to next level are displayed.
2. **Given that** I inspect my impact counters, **when** compared against activity, **then** they match actual totals:
   - *Reportes Creados* (HU-12).
   - *Apoyos Recibidos* on my reports (HU-15).
   - *Apoyos Otorgados* to neighbor reports (HU-15).
   - *Comentarios Publicados* in discussion threads (HU-17).
3. **Given that** my accumulated XP crosses a threshold (1,000, 2,500, or 4,000 XP), **when** the dashboard refreshes, **then** my new civic rank is reflected; if XP drops below threshold, rank is recalculated (RN-09).
4. **Given that** I reach the maximum rank (*Nivel 4 · Veedor Mayor*), **when** inspecting the progress bar, **then** it indicates the highest oversight milestone has been achieved.
5. **Given that** I have published reports, **when** tapping an item in *"Mis reportes"*, **then** its author view opens (HU-16); if none exist, an invitation to submit the first report is displayed.

---

### HU-24: Push Notifications & Civic Alerts *(Mandatory Academic Requirement)*
**As a** registered citizen,  
**I want** to receive push notifications for high-priority events on my reports,  
**So that** I am promptly alerted to community milestones and road repairs.

#### Acceptance Criteria
1. **Given that** my report reaches 10 endorsements (`COMMUNITY_VALIDATED`), **when** the 10th vote is recorded, **then** a high-priority push notification is sent: *"¡Reporte validado por la comunidad! Tu reporte '#[Título]' alcanzó 10 apoyos (+500 XP)"*.
2. **Given that** a neighbor posts a new comment on a report I authored or follow, **when** submitted, **then** a push notification is delivered: *"Nuevo comentario en el reporte #[Código]: [Nombre/Anónimo] aportó a la discusión"*.
3. **Given that** I tap a received push notification, **when** the app opens, **then** it deep-links directly to the relevant report detail screen (HU-14/HU-16).
4. **Given that** push notifications are disabled at the OS level, **when** events occur, **then** events are persistently recorded in the `notification` database table for in-app alert center viewing.


#### Implementation decisions (2026-11-26)
Firebase Cloud Messaging as the course teaches it (lessons K0–K4), with a Supabase Edge Function as the backend. Every row the triggers write to `notification` (`NEW_UPVOTE`, `NEW_COMMENT`, `COMMUNITY_VALIDATION`, `RESOLUTION_PROPOSAL`, `REPORT_RESOLVED`) is pushed, not only the two mandatory events. Each citizen has a topic `user_<id>` instead of a stored `fcm_token`: the phone subscribes after sign-in and unsubscribes on sign-out. Android only. Migration 011 also makes the "new comment" text say "Ciudadano anónimo" when the commenter hides their name (HU-01).
---

### HU-25: Community Resolution Proposal & Verification *(RN-11 / Civic Resolution)*
**As a** citizen or neighbor,  
**I want** to propose or verify that a reported road hazard has been repaired by attaching photographic proof,  
**So that** we can officially close the auditing cycle and verify restored infrastructure.

#### Acceptance Criteria
1. **Given that** I view a report in `REPORTED` or `COMMUNITY_VALIDATED` status, **when** I tap *"Reportar como reparado"*, **then** a modal allows submitting 1 mandatory repair photo and a description of completed works.
2. **Given that** an active resolution proposal already exists in `PENDING` status for that report, **when** another citizen attempts to propose repair, **then** duplicate proposal is prevented (enforced by `idx_single_active_resolution`) and they are redirected to vote on the active proposal.
3. **Given that** the original author submits repair evidence, **when** confirmed, **then** the report transitions directly to `RESOLVED`.
4. **Given that** a non-author citizen submits the repair proposal, **when** it accumulates **3 community confirmation votes**, **then** the report transitions to `RESOLVED` and the proponent receives **+50 XP**.
5. **Given that** neighbors detect fraudulent or invalid repair evidence, **when** the proposal receives **3 community objections**, **then** it transitions to `REJECTED_BY_COMMUNITY`, unlocking the report for future valid proposals.

#### Implementation decisions (2026-11-25)
The whole of RN-11 is implemented, not only the five criteria: the report author can **accept** a neighbor's proposal or **reject** it with a mandatory reason (`REJECTED_BY_AUTHOR`), a pending proposal **expires after 7 days**, and the report shows `UNDER_REVIEW` while a neighbor's proposal is pending (it goes back to `REPORTED` or `COMMUNITY_VALIDATED` when the proposal is rejected or expires). Server rules: `data model/migrations/010_community_resolution.sql`.
- The author's own proposal closes the report **without XP** (nobody rewards themselves); the +50 XP goes to a neighbor whose proposal is accepted by the author or by 3 confirmations.
- The proponent and the report author cannot vote; each neighbor votes once and cannot both confirm and object; votes are final.
- Expiry is lazy (no cron): an expired proposal takes no votes or decisions, and it is marked `EXPIRED` when somebody proposes again.
- Deleting a report also takes back the +50 XP of an accepted neighbor's resolution (extends migration 007).

---

## 3. Technical & Business Rule Decisions for Sprint 3

### 3.1. Business Rules Updated in Sprint 3
1. **RN-03 (Report Edit/Delete Window):** Strict **30-minute** limit and **fewer than 5 endorsements**. Report deletion revokes the 100 XP awarded for publication.
2. **RN-04 & RN-05 (Toggle Endorsements & Self-Vote Prohibition):** One vote per user, toggled off on second tap. Self-voting is strictly forbidden.
3. **RN-06 (Comment Moderation & Immutability):** Text editing is prohibited. Deletion allowed strictly within **5 minutes** of submission (-15 XP). Comments with image only (no text) are valid.
4. **RN-08 & RN-09 (XP Matrix & Rank Scale):**
   - Endorsement cast: **+10 XP** to voter and **+10 XP** to author.
   - Endorsement revoked: **-10 XP** to voter and **-10 XP** to author.
   - Comment submitted: **+15 XP**.
   - Community validation (10 votes): **+500 XP** irrevocable one-time bonus to author.
   - Resolution verified: **+50 XP** to proponent.
   - Ranks: *Observador Urbano* (0–999 XP), *Vecino Activo* (1,000–2,499 XP), *Guardián Vial* (2,500–3,999 XP), *Veedor Mayor* (4,000+ XP).

### 3.2. Push Notifications Architecture
- Course requirement compliance (≥ 2 events).
- Integration via **Firebase Cloud Messaging (FCM)** with Supabase Webhooks or Edge Functions.
- Device registration tokens (`fcm_token`) stored in a dedicated table or profile metadata.
