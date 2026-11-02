# Document 2: Screen Architecture and User Flows

## 2.1. Main Screens Map

### Screen 0: Authentication and Access
* Native email/password authentication and registration (with architectural design ready for Social Login).
* **Registration Form (Minimal Onboarding):**
  * Full name, email address, and password.
  * **Closed Dropdown City Selector:** Dropdown menu populated strictly from the `coverage_city` / `ciudad_cobertura` catalog (no free-form text input), with an auxiliary button *"Detect my nearest city by location (GPS)"*.
* Automatic post-authentication redirection to the **Profile Summary Screen (Civic Dashboard)**.
* Direct access in *"Anonymous Visitor / Guest"* mode for friction-free browsing.

### Screen 1: General Public Works & Road Map (Cartographic Home)
* Fullscreen interactive map centered on the active city with pins classified by icon and damage category.
* **Smart City Switcher (Header Component):**
  * Dropdown modal / bottom sheet that avoids cluttering the mobile screen with all 50+ cities at once.
  * **Fuzzy Search / Typeahead:** Dynamic filtering as the user types, resilient to accents and capitalization, limited to the top 5–8 matching results (`[City, Department]`).
  * **Quick Initial Suggestions (Before typing / Empty State):**
    * *Recent Cities:* The user's last 3 visited/consulted cities.
    * *Major Cities:* One-touch quick chips for the top 5 Colombian metropolitan capitals (Bogotá, Medellín, Cali, Barranquilla, Bucaramanga).
* **Unified Filter Bar:**
  * **Category:** *All, Potholes/Road Hazards, Traffic Lights, Abandoned Works, Sidewalks, Water Leaks, Road Signage*.
  * **Sector/Neighborhood:** List selector or zone search.
  * **Relevance Criteria:** *Most Voted, Recent, Critical, Community Validated (+10 votes)*.
* Interactive floating card (*Liquid Card*) upon selecting a marker, displaying summary, received upvotes, and access to details.
* Floating Action Button (*FAB*): *"Report Road / Public Work"*.

### Guided Reporting Workflow (4-Step Wizard)
* **Step 1 - Set Location:**
  * Interactive map with target crosshairs for precise GPS georeferencing or manual pin placement.
  * Automatic reverse-geocoding extraction of approximate address, neighborhood, and locality/commune with optional manual adjustment.
* **Step 2 - Photographic Evidence:**
  * Direct capture from the device camera or selection from the image gallery (maximum 3 photos).
  * Visual quality and sharpness validation. Option to skip photo if unavailable.
* **Step 3 - Type and Severity:**
  * Damage typology selection via descriptive cards with icons.
  * Perceived severity level selection (*Low, Medium, High, Critical*).
  * Optional field for approximate dimensions (e.g., *~1.2m x 18cm depth*).
* **Step 4 - Summary and Confirmation:**
  * Consolidated card displaying location, photo preview, category, and date/time.
  * Publication confirmation generating a public civic tracking code (e.g., `#VIG-8492`).

### Screen 2: Community Feed (Community)
* Vertical scrolling list of report cards.
* **Filter and Search Bar (Synchronized with Screen 1):**
  * Free-text search (by description or address).
  * Category chips (*Potholes, Traffic Lights, etc.*) and sector/neighborhood filter.
  * Sorting tabs: *Most Voted*, *Most Recent*, *Nearest*.
* Each report card displays: cover photo, title, neighborhood, author with civic level, priority badge, quick upvote button with live counter, and comment counter.

### Screen 3A: Report Detail (Neighbor / Third-Party View)
* Photo carousel/gallery with exact coordinates and capture timestamp.
* Report author information (name, neighborhood, current civic rank).
* Problem description, dimensions, and reported road mobility impact.
* **Collective Voice Bar:** Upvote counter and progress bar toward community validation.
* **Main Support Button:** *"Boost Report (+1 Vote)"* button (allows revoking the vote if already given).
* **Notification Button (Bell):** Subscribe to receive alerts regarding new comments or community milestones on the report.
* **Discussion Thread:** Chronological comment list showing avatar, user rank, comment text, and support for an attached image. Includes a text input box and a button to attach 1 optional photo (from camera or gallery) as complementary evidence or follow-up (not mandatory).

### Screen 3B: Report Detail (Author View / My Report)
* Displays full incident information reported by the authenticated user.
* **No subscription button:** The author is automatically subscribed by default to their own publication.
* **No upvote button:** Self-voting is strictly forbidden.
* **Community Validation Card (Subtle Gamification):**
  * Progress indicator: *"X of 10 upvotes received for Community Validation"*.
  * Dynamic incentive message: *"Y votes remaining to validate this report (+500 XP)"*.
  * If over 10 votes: Prominent seal showing *"Community-Validated Report"*.
* **Report Management:** *Edit* or *Delete* actions enabled strictly if within the 30-minute window and having fewer than 5 upvotes (RN-03).

### Screen 4: Civic Dashboard (Profile and Engagement)
* **Civic Identity Header:** Avatar, citizen name, current rank (e.g., *Level 3 - Road Guardian*), and XP progress bar toward the next rank.
* **Personal Citizen Impact Metrics:**
  1. **Reports Created:** Lifetime total of published incidents.
  2. **Upvotes Received:** Total backing received by the community on the user's reports (key collective impact metric).
  3. **Upvotes Given:** Total upvotes awarded to other neighbors' reports.
  4. **Comments Posted:** Total participations and contributions in discussion threads.
* **Civic Badges Gallery:** Grid displaying unlocked badges and requirements for upcoming milestones.
* **"My Reports" Section:** List of direct shortcuts to the user's publications (redirecting to view 3B).
