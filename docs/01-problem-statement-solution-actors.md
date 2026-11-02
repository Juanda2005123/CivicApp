# Document 1: Problem Statement, Solution, and Actors

## 1.1. Context and Problem
In urban environments, the constant deterioration of road networks and public spaces (potholes, fractured sidewalks, damaged sewage drains, malfunctioning traffic lights, and abandoned public works) impairs mobility, damages vehicles, and poses ongoing safety hazards for pedestrians, cyclists, and motorists.

Currently, citizen management of these issues faces two critical failures:
1. **Opacity and Dispersion of Complaints:** Citizens post isolated complaints on social networks or neighborhood chat groups without standardized georeferencing, resulting in lost visibility and minimal real-world impact.
2. **Invisibility of Collective Discontent:** Individual complaints fail to reflect the true magnitude of community frustration. There is no open, peaceful civic platform that consolidates photographic evidence with community backing to publicly highlight the city's most critical infrastructure bottlenecks.

## 1.2. The Solution (VIGÍA)
**VIGÍA** is a collaborative civic platform (mobile and web) for open auditing and citizen oversight that enables:
* Registering road damage on an interactive map with exact coordinate locations, photographic evidence, and structured categorization.
* Exploring and filtering incidents via real-time cartography and a unified community feed.
* Amplifying issues through collective community backing (*upvotes*) and constructive neighborhood discussion threads.
* Fostering ongoing civic engagement via a **Personal Impact Dashboard**, civic ranks, and merit badges (*subtle, transparent gamification*).

## 1.3. System Scope

### In Scope
* **Identity Management:** Citizen registration and authentication (email/password with architectural readiness for Google and Apple social logins), as well as anonymous guest exploration.
* **Cartographic & Exploration Module:** Interactive visualization of road damage on a georeferenced map and synchronized community feed with dynamic filters.
* **Guided Reporting Workflow (4-Step Wizard):** Map pin georeferencing $\rightarrow$ Photographic evidence $\rightarrow$ Category and perceived severity $\rightarrow$ Summary and public civic tracking code generation.
* **Collective Pressure & Interaction:** Upvoting system (with prevention of duplicates and self-voting) and chronological neighborhood comments (with the option to attach 1 complementary photo).
* **Community Validation:** Formal recognition for reports exceeding the community backing threshold (10 upvotes).
* **Civic Dashboard & Gamification:** Personal participation metrics (reports submitted, upvotes received, upvotes given, comments posted), experience points (XP), civic progression ranks, and milestone badges.

### Out of Scope (Explicit Boundaries)
* **Direct Interaction with Government Entities:** The platform does not manage administrative procedures (*PQRSD*) with municipal secretariats, mayoral offices, or public contractors, remaining a 100% citizen-led, community-driven, and independent tool.
* **Operational Dispatch:** Does not include municipal work crew assignments or public works scheduling.
* **Formal State Proceedings:** Any legal action, formal petition, or statutory notice to government bodies remains the external prerogative of the community.

## 1.4. System Actors
1. **Anonymous Visitor / Guest Observer:**
   * Accesses the platform without credentials.
   * Can browse the general map, explore the community feed, and view incident details.
   * Cannot create reports, upvote, comment, or earn experience points.
2. **Registered Citizen:**
   * Authenticated user with an active profile.
   * Submits road damage reports with photographic evidence.
   * Backs fellow citizens' reports (*upvotes*), participates in discussion threads (with optional photo attachment), and follows reports of interest.
   * Manages personal reports (editing and deletion subject to a time/vote threshold).
   * Views their Civic Dashboard to track their community impact, level, and earned badges.
3. **Distinguished Community Overseer:**
   * Citizen who has achieved a high civic rank through community-validated reports.
   * Possesses public badges displayed on comments and profiles, lending verified credibility to their contributions.
