# FoodBridge

> **Surplus-Food Donation Coordination, Food-Waste Awareness & Impact Reporting**  
> *Connecting Donors, Partner Food Banks, and Communities.*

---

## 1. Project Overview & Core Principles

FoodBridge is a Flutter mobile application (Material 3, Android-first) designed for commercial canteens, restaurants, and event caterers to coordinate safe surplus-food donations with verified NGOs and food banks.

### Paramount Principle
> **"The app SUPPORTS the NGO's procedures; it does not replace them."**
> A listing is never "approved" or "safe" simply because it appears in the app. New listings always enter the **`Awaiting NGO Review`** status. The partner NGO holds sole and final authority on intake safety verification, acceptance, transport requirements, and distribution destinations.
>
> **Mandatory Universal Disclaimer**:  
> *"Food-safety rules are set by the partner NGO. This app does not guarantee food safety."*

---

## 2. Project Phases (Total: 5 Phases)

The application was built end-to-end across **5 sequential phases**:

| Phase | Title | Key Deliverables |
| :--- | :--- | :--- |
| **Phase 1** | **Architecture, Theme, Models & Rules** | Clean architecture structure, Material 3 warm green theme, domain models, strict state transition engine, formula calculators, `firestore.rules`, and seed dataset generator. |
| **Phase 2** | **Auth, Roles & Role Navigation** | Welcome screen, role selection (admin restricted), registration & pending approval workflow, `go_router` RBAC guards, and context-aware home dashboards for all 5 roles. |
| **Phase 3** | **Surplus Donation Pipeline** | Create donation screen with validations, available donations list (NGO only), NGO review with configurable safety checklist, pickup logistics, and food bank distribution ledger. |
| **Phase 4** | **Awareness, Waste Audits & Reporting** | Educational Awareness Centre with 6-question pre/post quiz, daily canteen waste audit form with `fl_chart` trend analytics, verified impact report with CSV & PDF printable export, and profile settings. |
| **Phase 5** | **Testing, Documentation & Demo Script** | Master test suite covering all 10 specification test cases, Firebase setup instructions, and step-by-step demo evaluation script. |

---

## 3. Tech Stack

- **Framework**: Flutter (Android-first), Material 3 Design
- **State Management**: Riverpod (`flutter_riverpod`)
- **Navigation & Routing**: `go_router` with declarative authentication and role redirection guards
- **Data Visualization**: `fl_chart` for historical kitchen waste rate trend analytics
- **Reporting & Export**: `csv` for audit data and `pdf` + `printing` for official printable PDF impact reports
- **Cloud Backend**: Cloud Firestore (with role-based security rules) and Firebase Authentication
- **Mapping & Geolocation**: OpenStreetMap (`flutter_map` + `latlong2`) for zero-cost, API-key-free interactive map rendering
- **Turn-by-Turn Navigation**: `url_launcher` for 1-tap external Google Maps GPS directions
- **Real-Time Engine**: Centralized reactive broadcast event bus (`RealtimeService`) driving live updates across 6 dimensions
- **Demo Mode**: Built-in reactive in-memory repository pre-loaded with realistic seed data across all 5 roles, enabling zero-config demonstration and immediate evaluation.

---

## 4. Real-Time Architecture & OpenStreetMap Engine

### What Becomes Real-Time?

| Feature | How It Updates Live |
| :--- | :--- |
| **Food availability** | When a donor posts or updates a donation listing, immediate alerts and map pin additions occur. |
| **NGO status** | When authorized staff update operating or availability information (*Accepting Donations* vs *At Capacity*). |
| **Donation tracking** | When an NGO accepts, schedules, or a volunteer driver weighs and collects surplus food. |
| **Map** | When approved intake locations, NGO availability, or donation pickup coordinates change. |
| **Notifications** | When the notification service broadcasts system-wide or role-targeted alert toasts. |
| **Impact dashboard** | When completed donations or distributions are recorded, instantly updating rescued kg and CO₂ savings. |

### Pune City OpenStreetMap Network & 1-Tap Directions
- **OpenStreetMap Interactive Layer**: Centered on Pune City (`18.5204° N, 73.8567° E`) with custom markers for NGOs (Green for Accepting, Orange for High Demand, Indigo for Central Food Banks) and active surplus food pickups.
- **Real Pune NGO Dataset**: Pre-populated with authentic organizations including **Robin Hood Army Pune** (Viman Nagar), **Feeding India by Zomato** (Shivajinagar), **Seva Sahayog Foundation** (Karve Nagar), **Janwani MCCIA** (SB Road), **Maher Ashram** (Wagholi), and **Hope for Children** (Koregaon Park).
- **1-Tap Navigation**: Tapping **"Get Directions"** launches native Google Maps turn-by-turn GPS navigation directly to the NGO or food donor's exact coordinates.

---

## 5. User Roles & Permission Matrix

1. **Food Donor**: Canteens, restaurants, and event caterers. Creates surplus food listings, tracks own listings, submits daily waste audits, and views site impact.
2. **NGO / Food Bank Staff**: Holds final authority over food intake. Reviews listings against configurable safety checklists, accepts/rejects/requests clarification, assigns volunteer drivers, and logs food bank distribution ledgers.
3. **Volunteer / Driver**: Sees strictly their assigned pickups. Enters the **actual measured weight** at collection (separate from listed quantity).
4. **Awareness Participant**: Public community user. Reads prevention tips, downloads posters, takes the 6-question pre/post quiz, and views public diverted waste statistics. Cannot access operational records.
5. **Administrator**: Manages account approval queue for new registrations, oversees content, and inspects the immutable system audit trail.

---

## 6. Strict Donation Lifecycle State Machine

```
Draft ──► Submitted ──► Awaiting NGO Review ──► Accepted ──► Pickup Scheduled ──► Collected ──► Distribution Recorded ──► Closed
                                 │
                                 ├──► Rejected (reason required)
                                 └──► Clarification Requested ──► Submitted
```

- **Quantity Isolation**:
  - `listedQuantity`: Initial donor estimate (immutable after submit).
  - `acceptedQuantity`: NGO approved intake amount.
  - `actualCollectedQuantity`: Net food weight measured on-site by driver (tare deducted).
  - `distributedQuantity`: Exact kilograms distributed to recipient categories.
  - `remainderQuantity`: Diverted to compost or animal feed with mandatory disposition reason.
- **Auto-Expiry**: If `DateTime.now() > pickupDeadline` prior to collection, the item is flagged as `Expired`.
- **Cancellation**: Permitted with mandatory, non-empty cancellation reason.

---

## 7. Mathematical Formulas & Business Logic

Encapsulated in pure, unit-tested functions in `lib/core/calculators/impact_calculators.dart`:

1. **Waste Rate (%)**:
   $$\text{Waste Rate (\%)} = \left(\frac{\text{discarded kg}}{\text{total prepared kg}}\right) \times 100 \quad (\text{if prepared} = 0 \to 0.0\%)$$
2. **Change in Discarded Waste (%)**:
   $$\text{Change in Discarded Waste (\%)} = \left(\frac{\text{baseline avg} - \text{post avg}}{\text{baseline avg}}\right) \times 100$$
   *Guard*: If `baseline avg <= 0` or audit methodology changed, displays **"Not meaningful"**.
3. **Completed Collection Rate (%)**:
   $$\text{Collection Rate (\%)} = \left(\frac{\text{completed collections}}{\text{accepted requests}}\right) \times 100 \quad (\text{if accepted} = 0 \to 0.0\%)$$
4. **Data Quality Score (%)**:
   $$\text{Data Quality (\%)} = \left(\frac{\text{complete listings}}{\text{total submitted listings}}\right) \times 100$$

---

## 8. Setup & Run Instructions

### Prerequisites
- Flutter SDK (>= 3.3.0)
- Android Studio / VS Code with Flutter extension
- An Android emulator, physical device, or Chrome browser

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Run in Demo Mode (Zero-Config)
The app runs out-of-the-box in **Demo Mode** with preloaded sample data for all 5 roles:
```bash
flutter run
```

### Step 3: Firebase Configuration (When Connecting to Live Firebase)
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Authentication** (Email/Password provider).
3. Enable **Cloud Firestore** and deploy the included security rules:
   ```bash
   firebase deploy --only firestore:rules
   ```
4. For Android: Download `google-services.json` and place it in `android/app/google-services.json`.
5. Run the FlutterFire CLI to generate `firebase_options.dart`:
   ```bash
   flutterfire configure
   ```

---

## 9. Five-Minute Demo Walkthrough Script

Evaluate the complete end-to-end flow using the interactive 1-tap demo tools:

### Step 1: Launch & Explore Welcome Screen
- Observe the warm green theme, accessibility standards (minimum 48×48 dp touch targets), and the mandatory Universal Food Safety Disclaimer banner.
- Tap **"Donor (Canteen)"** under Quick Demo Access chips to sign in immediately as **Chef Anand Sharma**.

### Step 2: Create Surplus Donation (Donor Flow)
- Tap **"+ Create Donation"** on the Donor Dashboard.
- Notice the prepopulated form: Category (`Cooked Meals`), Quantity (`20 kg`), Storage (`Hot Held > 63°C`), Allergens, Packaging, Pickup Deadline, and Contact details.
- Tap **"Submit Listing"**. Notice that the listing is saved strictly as **"Awaiting NGO Review"** (not auto-approved).

### Step 3: Conduct Intake Review (NGO Staff Flow)
- Tap the top-right role chip and select **"NGO / Food Bank Staff"** (switches to **Sarah Jenkins**).
- Open **"Review Listings"** (or tap the incoming item in the queue).
- Inspect full food details and declared temperature.
- In the **NGO Intake Safety Checklist**, toggle criteria, or type a custom check and tap **"+ Add"**.
- Tap **"Accept Donation & Proceed to Logistics"**.

### Step 4: Schedule & Collect (Logistics Flow)
- On the pickup prompt dialog, tap **"Confirm Schedule"** to dispatch to Volunteer **Alex Driver**.
- Tap the top-right role chip and select **"Volunteer / Driver"** (switches to **Alex Driver**).
- Open **"Confirm Collection"**: enter the actual scale weight (e.g. `19.2 kg`, deducting container tare).
- Tap **"Save & Confirm"**. Notice `actualCollectedQuantity` is saved separately from the listed `20 kg`.

### Step 5: Food Bank Distribution Ledger
- Switch role back to **"NGO / Food Bank Staff"** and open **"Food Bank Ledger"**.
- Under collected surplus, tap **"Record"**.
- Select Destination Category (`Student Food Pantry`), enter Distributed kg (`18.0 kg`), Remainder (`1.2 kg`), Remainder Disposition (`Compost`), and state disposition reason (`Container crust trimming`).
- Save to finalize and close the record.

### Step 6: Waste Audit, Quiz & Export Reports
- Switch role to **"Awareness Participant"**: Open **"Take Assessment Quiz"** to answer questions and view detailed explanations.
- Switch role to **"Donor"**: Open **"Log Waste Audit"** to view the `fl_chart` waste trend reduction graph.
- Open **"Impact & Reports"**: Select date range, observe verified totals (estimates kept separate), and tap **"Print / Save PDF"** or **"Export CSV"**.

### Step 7: Account Approval Gate (Admin Flow)
- Sign out and tap **"Register"** on the Welcome screen.
- Register a new account as a Food Donor. Notice it routes to the **Account Verification (Pending Approval)** screen.
- Switch to **"Administrator"** to review the approval queue and tap **"Approve"**.

---

## 9. Test Verification Report

All specification requirements have been validated through automated tests:

```bash
flutter test
```

### Verified Test Cases:
1. `TEST CASE 1`: Complete donor listing saves strictly as `Awaiting NGO Review` (no auto-approval).
2. `TEST CASE 2`: Missing required fields are blocked with `ArgumentError`.
3. `TEST CASE 3`: Role permissions enforced; volunteers see strictly assigned pickups; awareness participants cannot access operational donation records.
4. `TEST CASE 4`: NGO review saves decision, timestamp, reviewer ID, and reviewer name.
5. `TEST CASE 5`: Cancelled pickups store mandatory cancellation reasons.
6. `TEST CASE 6`: Actual collected quantity (`actualCollectedQuantity`) is recorded and stored separately from `listedQuantity`.
7. `TEST CASE 7`: Food bank distributions record distributed quantities, recipient category, remainder quantity, and mandatory disposition reason.
8. `TEST CASE 8`: An expired deadline flags the listing as `Expired`.
9. `TEST CASE 9`: The dashboard filters verified totals by date range.
10. `TEST CASE 10`: Formula precision tests for Waste Rate zero division guard, collection rate %, and Change in Discarded Waste returning **"Not meaningful"** when baseline $\le 0$ or methodology changed.
