import '../models/user_model.dart';
import '../models/organisation_model.dart';
import '../models/donation_model.dart';
import '../models/review_model.dart';
import '../models/pickup_model.dart';
import '../models/distribution_model.dart';
import '../models/waste_audit_model.dart';
import '../models/awareness_model.dart';
import '../models/audit_log_model.dart';
import '../../core/state/donation_status_engine.dart';
import '../../core/constants/app_constants.dart';

/// Prepopulated realistic seed dataset for zero-config demonstration and evaluation.
class SeedData {
  static final DateTime now = DateTime.now();

  // ---------------------------------------------------------------------------
  // 1. Prepopulated Organisations
  // ---------------------------------------------------------------------------
  static final List<OrganisationModel> organisations = [
    OrganisationModel(
      organisationId: 'org_donor_1',
      name: 'GreenLeaf Campus Canteen',
      type: OrgType.donor,
      operatingArea: 'University North Campus, Sector 4',
      isVerified: true,
      operatingHours: '07:30 - 21:00 Daily',
      contactPerson: 'Chef Anand Sharma',
      contactPhone: '+91 98234 56789',
      physicalAddress: 'Student Centre Block B, University Campus',
    ),
    OrganisationModel(
      organisationId: 'org_ngo_1',
      name: 'City Harvest Community Food Bank',
      type: OrgType.ngo,
      operatingArea: 'Metro City & Suburbs',
      isVerified: true,
      operatingHours: '08:00 - 22:00 Daily',
      contactPerson: 'Sarah Jenkins (Intake Director)',
      contactPhone: '+91 98765 43210',
      physicalAddress: 'Building 14, Relief Road, Central District',
    ),
  ];

  // ---------------------------------------------------------------------------
  // 2. Prepopulated Users across all 5 roles
  // ---------------------------------------------------------------------------
  static final List<UserModel> users = [
    // 1. Donor
    UserModel(
      userId: 'user_donor_1',
      name: 'Chef Anand Sharma',
      email: 'donor@foodbridge.ngo',
      role: UserRole.donor,
      organisationId: 'org_donor_1',
      contactNumber: '+91 98234 56789',
      approvalStatus: ApprovalStatus.approved,
      createdAt: now.subtract(const Duration(days: 30)),
      lastLoginAt: now.subtract(const Duration(hours: 1)),
    ),
    // 2. NGO Staff (Reviewer & Logistics Coordinator)
    UserModel(
      userId: 'user_ngo_1',
      name: 'Sarah Jenkins',
      email: 'ngo@foodbridge.ngo',
      role: UserRole.ngoStaff,
      organisationId: 'org_ngo_1',
      contactNumber: '+91 98765 43210',
      approvalStatus: ApprovalStatus.approved,
      createdAt: now.subtract(const Duration(days: 60)),
      lastLoginAt: now.subtract(const Duration(minutes: 15)),
    ),
    // 3. Volunteer Driver
    UserModel(
      userId: 'user_volunteer_1',
      name: 'Alex Driver',
      email: 'volunteer@foodbridge.ngo',
      role: UserRole.volunteer,
      organisationId: 'org_ngo_1',
      contactNumber: '+91 98111 22233',
      approvalStatus: ApprovalStatus.approved,
      createdAt: now.subtract(const Duration(days: 20)),
      lastLoginAt: now.subtract(const Duration(hours: 2)),
    ),
    // 4. Awareness Participant (public user)
    UserModel(
      userId: 'user_awareness_1',
      name: 'Priya Sharma',
      email: 'awareness@foodbridge.ngo',
      role: UserRole.awareness,
      contactNumber: '+91 98444 55566',
      approvalStatus: ApprovalStatus.approved,
      createdAt: now.subtract(const Duration(days: 10)),
      lastLoginAt: now.subtract(const Duration(hours: 5)),
    ),
    // 5. System Administrator
    UserModel(
      userId: 'user_admin_1',
      name: 'System Admin',
      email: 'admin@foodbridge.ngo',
      role: UserRole.admin,
      contactNumber: '+91 99999 00000',
      approvalStatus: ApprovalStatus.approved,
      createdAt: now.subtract(const Duration(days: 90)),
      lastLoginAt: now,
    ),
    // 6. Pending User for Verification Demo
    UserModel(
      userId: 'user_pending_1',
      name: 'Sunil Verma (Catering Mgr)',
      email: 'sunil@grandhotel.com',
      role: UserRole.donor,
      contactNumber: '+91 98333 44455',
      approvalStatus: ApprovalStatus.pending,
      createdAt: now.subtract(const Duration(hours: 3)),
    ),
  ];

  // ---------------------------------------------------------------------------
  // 3. Prepopulated Donations in each lifecycle state
  // ---------------------------------------------------------------------------
  static final List<DonationModel> donations = [
    // 1. Awaiting NGO Review
    DonationModel(
      donationId: 'don_101',
      donorId: 'user_donor_1',
      donorOrgId: 'org_donor_1',
      donorOrgName: 'GreenLeaf Campus Canteen',
      foodDescription: 'Surplus Vegetable Biryani and Dal Tadka prepared for lunch banquet.',
      foodCategory: 'Cooked Meals',
      listedQuantity: 30.0,
      unit: 'kg',
      preparationDateTime: now.subtract(const Duration(hours: 2)),
      storageCondition: 'Hot Held (> 63°C)',
      knownAllergens: ['Dairy / Milk', 'None Declared'],
      packagingType: 'Stainless insulated food containers',
      pickupDeadline: now.add(const Duration(hours: 3)),
      locationName: 'GreenLeaf Canteen Kitchen Loading Dock',
      locationAddress: 'Sector 4, University North Campus Gate 2',
      contactPerson: 'Chef Anand Sharma',
      contactPhone: '+91 98234 56789',
      status: DonationStatus.awaitingNgoReview,
      createdAt: now.subtract(const Duration(hours: 1)),
      updatedAt: now.subtract(const Duration(hours: 1)),
    ),

    // 2. Clarification Requested
    DonationModel(
      donationId: 'don_102',
      donorId: 'user_donor_1',
      donorOrgId: 'org_donor_1',
      donorOrgName: 'GreenLeaf Campus Canteen',
      foodDescription: 'Assorted Buffet Leftovers: Paneer Curry, Mixed Rice and Salad.',
      foodCategory: 'Cooked Meals',
      listedQuantity: 18.0,
      unit: 'kg',
      preparationDateTime: now.subtract(const Duration(hours: 5)),
      storageCondition: 'Ambient / Room Temp',
      knownAllergens: ['Dairy / Milk'],
      packagingType: 'Plastic trays with cling wrap',
      pickupDeadline: now.add(const Duration(hours: 2)),
      locationName: 'GreenLeaf Canteen Kitchen',
      locationAddress: 'Sector 4, University North Campus Gate 2',
      contactPerson: 'Chef Anand Sharma',
      contactPhone: '+91 98234 56789',
      status: DonationStatus.clarificationRequested,
      createdAt: now.subtract(const Duration(hours: 4)),
      updatedAt: now.subtract(const Duration(hours: 2)),
    ),

    // 3. Accepted & Pickup Scheduled
    DonationModel(
      donationId: 'don_103',
      donorId: 'user_donor_1',
      donorOrgId: 'org_donor_1',
      donorOrgName: 'GreenLeaf Campus Canteen',
      foodDescription: 'Fresh Bakery Dinner Rolls, Whole Wheat Bread Loaves and Buns.',
      foodCategory: 'Bakery & Bread',
      listedQuantity: 22.0,
      unit: 'kg',
      preparationDateTime: now.subtract(const Duration(hours: 4)),
      storageCondition: 'Ambient / Room Temp',
      knownAllergens: ['Gluten / Wheat'],
      packagingType: 'Food-grade sealed cardboard crates',
      pickupDeadline: now.add(const Duration(hours: 4)),
      locationName: 'GreenLeaf Bakery Section Loading Bay',
      locationAddress: 'Sector 4, University North Campus Gate 2',
      contactPerson: 'Chef Anand Sharma',
      contactPhone: '+91 98234 56789',
      status: DonationStatus.pickupScheduled,
      createdAt: now.subtract(const Duration(hours: 5)),
      updatedAt: now.subtract(const Duration(hours: 2)),
    ),

    // 4. Collected by Volunteer
    DonationModel(
      donationId: 'don_104',
      donorId: 'user_donor_1',
      donorOrgId: 'org_donor_1',
      donorOrgName: 'GreenLeaf Campus Canteen',
      foodDescription: 'Event Surplus: Steamed Idlis, Medu Vada, Coconut Chutney and Sambar.',
      foodCategory: 'Cooked Meals',
      listedQuantity: 45.0,
      unit: 'kg',
      preparationDateTime: now.subtract(const Duration(hours: 7)),
      storageCondition: 'Chilled (1°C to 5°C)',
      knownAllergens: ['Mustard', 'Tree Nuts'],
      packagingType: 'Thermal transport insulated boxes',
      pickupDeadline: now.subtract(const Duration(hours: 1)),
      locationName: 'GreenLeaf Canteen Rear Dock',
      locationAddress: 'Sector 4, University North Campus Gate 2',
      contactPerson: 'Chef Anand Sharma',
      contactPhone: '+91 98234 56789',
      status: DonationStatus.collected,
      createdAt: now.subtract(const Duration(hours: 8)),
      updatedAt: now.subtract(const Duration(hours: 1)),
    ),

    // 5. Distribution Recorded & Closed
    DonationModel(
      donationId: 'don_105',
      donorId: 'user_donor_1',
      donorOrgId: 'org_donor_1',
      donorOrgName: 'GreenLeaf Campus Canteen',
      foodDescription: 'Canteen Lunch Surplus: Rajma Masala, Steamed Rice, Phulkas.',
      foodCategory: 'Cooked Meals',
      listedQuantity: 35.0,
      unit: 'kg',
      preparationDateTime: now.subtract(const Duration(days: 1, hours: 4)),
      storageCondition: 'Hot Held (> 63°C)',
      knownAllergens: ['None Declared'],
      packagingType: 'Sealed stainless containers',
      pickupDeadline: now.subtract(const Duration(days: 1)),
      locationName: 'GreenLeaf Canteen Kitchen',
      locationAddress: 'Sector 4, University North Campus Gate 2',
      contactPerson: 'Chef Anand Sharma',
      contactPhone: '+91 98234 56789',
      status: DonationStatus.closed,
      createdAt: now.subtract(const Duration(days: 1, hours: 6)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ),

    // 6. Expired Listing
    DonationModel(
      donationId: 'don_106',
      donorId: 'user_donor_1',
      donorOrgId: 'org_donor_1',
      donorOrgName: 'GreenLeaf Campus Canteen',
      foodDescription: 'Pre-packaged Sandwiches and Fresh Fruit Cups.',
      foodCategory: 'Packaged Goods',
      listedQuantity: 12.0,
      unit: 'kg',
      preparationDateTime: now.subtract(const Duration(hours: 14)),
      storageCondition: 'Chilled (1°C to 5°C)',
      knownAllergens: ['Gluten / Wheat', 'Dairy / Milk'],
      packagingType: 'Individual plastic containers',
      pickupDeadline: now.subtract(const Duration(hours: 2)), // deadline passed
      locationName: 'Canteen Deli Counter',
      locationAddress: 'Sector 4, University North Campus Gate 2',
      contactPerson: 'Chef Anand Sharma',
      contactPhone: '+91 98234 56789',
      status: DonationStatus.expired,
      isExpired: true,
      createdAt: now.subtract(const Duration(hours: 12)),
      updatedAt: now.subtract(const Duration(hours: 2)),
    ),
  ];

  // ---------------------------------------------------------------------------
  // 4. Prepopulated NGO Reviews
  // ---------------------------------------------------------------------------
  static final List<ReviewModel> reviews = [
    ReviewModel(
      reviewId: 'rev_102',
      donationId: 'don_102',
      reviewerId: 'user_ngo_1',
      reviewerName: 'Sarah Jenkins',
      decision: ReviewDecision.clarificationRequested,
      checklist: [
        const SafetyChecklistItem(item: 'Packaging integrity check', isVerified: false, notes: 'Cling wrap loose on 2 trays'),
        const SafetyChecklistItem(item: 'Temperature holding verification', isVerified: false, notes: 'Ambient held for 5 hours exceeds intake threshold'),
      ],
      ngoNotes: 'Please confirm whether cooked paneer was chilled immediately after prep. Ambient storage for 5 hours requires re-evaluation.',
      reviewedAt: now.subtract(const Duration(hours: 2)),
    ),
    ReviewModel(
      reviewId: 'rev_103',
      donationId: 'don_103',
      reviewerId: 'user_ngo_1',
      reviewerName: 'Sarah Jenkins',
      decision: ReviewDecision.accepted,
      checklist: [
        const SafetyChecklistItem(item: 'Packaging is intact, food-grade, and securely sealed', isVerified: true, notes: 'Sealed cardboard crates confirmed'),
        const SafetyChecklistItem(item: 'Visual inspection confirms freshness with no signs of spoilage', isVerified: true, notes: 'Freshly baked today'),
        const SafetyChecklistItem(item: 'Declared storage temperature condition matches food type', isVerified: true, notes: 'Ambient bread storage acceptable'),
      ],
      ngoNotes: 'Accepted. Baked dry goods pose minimal microbial risk. Assigned to Volunteer Alex Driver.',
      reviewedAt: now.subtract(const Duration(hours: 3)),
    ),
    ReviewModel(
      reviewId: 'rev_104',
      donationId: 'don_104',
      reviewerId: 'user_ngo_1',
      reviewerName: 'Sarah Jenkins',
      decision: ReviewDecision.accepted,
      checklist: [
        const SafetyChecklistItem(item: 'Thermal transport insulation ready', isVerified: true),
        const SafetyChecklistItem(item: 'Chilled storage verified at 4°C', isVerified: true),
      ],
      ngoNotes: 'Chilled items inspected. Dispatched volunteer for insulated pickup.',
      reviewedAt: now.subtract(const Duration(hours: 4)),
    ),
    ReviewModel(
      reviewId: 'rev_105',
      donationId: 'don_105',
      reviewerId: 'user_ngo_1',
      reviewerName: 'Sarah Jenkins',
      decision: ReviewDecision.accepted,
      checklist: [
        const SafetyChecklistItem(item: 'Sealed stainless containers verified', isVerified: true),
        const SafetyChecklistItem(item: 'Hot holding > 63°C maintained until handoff', isVerified: true),
      ],
      ngoNotes: 'Fully approved and verified against NGO hygiene intake protocol.',
      reviewedAt: now.subtract(const Duration(days: 1, hours: 5)),
    ),
  ];

  // ---------------------------------------------------------------------------
  // 5. Prepopulated Pickups
  // ---------------------------------------------------------------------------
  static final List<PickupModel> pickups = [
    PickupModel(
      pickupId: 'pick_103',
      donationId: 'don_103',
      assignedVolunteerId: 'user_volunteer_1',
      assignedVolunteerName: 'Alex Driver',
      scheduledWindowStart: now.add(const Duration(hours: 1)),
      scheduledWindowEnd: now.add(const Duration(hours: 3)),
      status: PickupStatus.scheduled,
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    PickupModel(
      pickupId: 'pick_104',
      donationId: 'don_104',
      assignedVolunteerId: 'user_volunteer_1',
      assignedVolunteerName: 'Alex Driver',
      scheduledWindowStart: now.subtract(const Duration(hours: 2)),
      scheduledWindowEnd: now.subtract(const Duration(hours: 1)),
      actualPickupTime: now.subtract(const Duration(hours: 1)),
      actualCollectedQuantity: 42.0, // Listed was 45.0 kg; driver weighed 42.0 kg
      actualQuantityUnit: 'kg',
      driverNotes: 'Weighed on portable scale. 3 kg container tare subtracted. All containers secure.',
      status: PickupStatus.collected,
      createdAt: now.subtract(const Duration(hours: 3)),
    ),
    PickupModel(
      pickupId: 'pick_105',
      donationId: 'don_105',
      assignedVolunteerId: 'user_volunteer_1',
      assignedVolunteerName: 'Alex Driver',
      scheduledWindowStart: now.subtract(const Duration(days: 1, hours: 3)),
      scheduledWindowEnd: now.subtract(const Duration(days: 1, hours: 1)),
      actualPickupTime: now.subtract(const Duration(days: 1, hours: 2)),
      actualCollectedQuantity: 35.0,
      actualQuantityUnit: 'kg',
      driverNotes: 'Smooth collection. Handed over directly to central pantry kitchen.',
      status: PickupStatus.collected,
      createdAt: now.subtract(const Duration(days: 1, hours: 4)),
    ),
  ];

  // ---------------------------------------------------------------------------
  // 6. Prepopulated Distributions (Food-Bank Records)
  // ---------------------------------------------------------------------------
  static final List<DistributionModel> distributions = [
    DistributionModel(
      distributionId: 'dist_105',
      donationId: 'don_105',
      pickupId: 'pick_105',
      quantityDistributed: 32.0, // Distributed to beneficiaries
      unit: 'kg',
      distributionTime: now.subtract(const Duration(days: 1, hours: 1)),
      destinationCategory: 'Student Food Pantry',
      recipientLocation: 'Campus Community Pantry Block C',
      remainderQuantity: 3.0, // Remainder accounted for
      remainderDisposition: 'Compost',
      dispositionReason: 'Hardened rice crust and tray residue unfit for direct meal serving.',
      recordedByUserId: 'user_ngo_1',
      recordedByUserName: 'Sarah Jenkins',
      createdAt: now.subtract(const Duration(days: 1)),
    ),
  ];

  // ---------------------------------------------------------------------------
  // 7. Prepopulated Waste Audits across 5 consecutive days
  // ---------------------------------------------------------------------------
  static final List<WasteAuditModel> wasteAudits = [
    WasteAuditModel(
      auditId: 'audit_1',
      siteId: 'org_donor_1',
      siteName: 'GreenLeaf Campus Canteen',
      recordedByUserId: 'user_donor_1',
      date: now.subtract(const Duration(days: 4)),
      preparedKg: 220.0,
      servedKg: 180.0,
      edibleSurplusKg: 25.0,
      discardedKg: 15.0,
      measurementMethod: 'Direct Weighing (Scale)',
      notes: 'Initial audit day. Rain reduced lunchtime student footfall.',
      createdAt: now.subtract(const Duration(days: 4)),
    ),
    WasteAuditModel(
      auditId: 'audit_2',
      siteId: 'org_donor_1',
      siteName: 'GreenLeaf Campus Canteen',
      recordedByUserId: 'user_donor_1',
      date: now.subtract(const Duration(days: 3)),
      preparedKg: 210.0,
      servedKg: 185.0,
      edibleSurplusKg: 15.0,
      discardedKg: 10.0,
      measurementMethod: 'Direct Weighing (Scale)',
      notes: 'Implemented smaller prep batches for vegetable sides.',
      createdAt: now.subtract(const Duration(days: 3)),
    ),
    WasteAuditModel(
      auditId: 'audit_3',
      siteId: 'org_donor_1',
      siteName: 'GreenLeaf Campus Canteen',
      recordedByUserId: 'user_donor_1',
      date: now.subtract(const Duration(days: 2)),
      preparedKg: 205.0,
      servedKg: 186.0,
      edibleSurplusKg: 12.0,
      discardedKg: 7.0,
      measurementMethod: 'Direct Weighing (Scale)',
      notes: 'Waste rate reduced after staff awareness briefing.',
      createdAt: now.subtract(const Duration(days: 2)),
    ),
    WasteAuditModel(
      auditId: 'audit_4',
      siteId: 'org_donor_1',
      siteName: 'GreenLeaf Campus Canteen',
      recordedByUserId: 'user_donor_1',
      date: now.subtract(const Duration(days: 1)),
      preparedKg: 200.0,
      servedKg: 188.0,
      edibleSurplusKg: 8.0,
      discardedKg: 4.0,
      measurementMethod: 'Direct Weighing (Scale)',
      notes: 'Portion control ladles introduced at buffet counters.',
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    WasteAuditModel(
      auditId: 'audit_5',
      siteId: 'org_donor_1',
      siteName: 'GreenLeaf Campus Canteen',
      recordedByUserId: 'user_donor_1',
      date: now,
      preparedKg: 195.0,
      servedKg: 186.0,
      edibleSurplusKg: 6.0,
      discardedKg: 3.0,
      measurementMethod: 'Direct Weighing (Scale)',
      notes: 'Lowest discard recorded. Edible surplus routed to FoodBridge.',
      createdAt: now,
    ),
  ];

  // ---------------------------------------------------------------------------
  // 8. Prepopulated Awareness Educational Content & Quizzes
  // ---------------------------------------------------------------------------
  static final List<AwarenessContent> awarenessContent = [
    AwarenessContent(
      contentId: 'aware_1',
      title: 'First-In, First-Out (FIFO) Storage Management',
      type: AwarenessContentType.tip,
      category: 'Kitchen Best Practices',
      body: 'Always place newer ingredients behind older ones on cold and dry storage shelves. Clearly date-mark all prepped pans to ensure older edible batches are rotated and utilized first before spoiling.',
      sourceReviewer: 'City Harvest Food Safety Committee',
      publishedDate: DateTime(2026, 9, 1),
    ),
    AwarenessContent(
      contentId: 'aware_2',
      title: 'The Temperature Danger Zone (5°C to 63°C)',
      type: AwarenessContentType.poster,
      category: 'Food Safety Basics',
      body: 'Microorganisms multiply rapidly between 5°C and 63°C. Hot cooked food intended for surplus donation must either be held hot above 63°C or rapidly cooled to below 5°C within 90 minutes before insulated container handoff.',
      sourceReviewer: 'Partner NGO Hygiene Taskforce',
      publishedDate: DateTime(2026, 9, 10),
    ),
    AwarenessContent(
      contentId: 'aware_3',
      title: 'FAQ: Can Food Past Its "Best Before" Date Be Donated?',
      type: AwarenessContentType.faq,
      category: 'Regulations & Guidelines',
      body: '"Best Before" dates refer to peak sensory quality, not microbial safety. Many shelf-stable items (uncooked rice, canned beans, dry pasta) remain completely safe beyond this date. However, the partner NGO holds absolute discretion on intake verification.',
      sourceReviewer: 'FoodBridge Advisory Board',
      publishedDate: DateTime(2026, 9, 15),
    ),
    AwarenessContent(
      contentId: 'aware_4',
      title: 'Campus Zero-Waste Action Week 2026',
      type: AwarenessContentType.campaign,
      category: 'Events & Campaigns',
      body: 'Join universities and local canteens in a 7-day challenge to record daily waste audits, eliminate edible plate waste, and redirect 100% of safe buffet surplus to community pantries.',
      sourceReviewer: 'Student Sustainability Alliance',
      publishedDate: DateTime(2026, 10, 1),
      campaignDate: DateTime.now().add(const Duration(days: 7)),
    ),
  ];

  static const Quiz sampleQuiz = Quiz(
    quizId: 'quiz_pre_post_1',
    title: 'Food-Waste Prevention & Safe Donation Assessment',
    description: 'Test your understanding of commercial kitchen waste reduction, safe temperature handling, and donation protocols.',
    isPostQuiz: false,
    questions: [
      QuizQuestion(
        id: 'q1',
        question: 'What is the primary difference between a "Use By" date and a "Best Before" date?',
        options: [
          'They mean exactly the same thing in food safety.',
          '"Use By" relates to food safety; "Best Before" relates to optimal food quality.',
          '"Best Before" means food must be discarded immediately at midnight.',
          '"Use By" applies exclusively to dry canned goods.',
        ],
        correctIndex: 1,
        explanation: '"Use By" indicates when food may become unsafe to eat. "Best Before" signifies quality, texture, and flavor.',
      ),
      QuizQuestion(
        id: 'q2',
        question: 'What is the temperature "Danger Zone" where bacteria multiply most rapidly?',
        options: [
          'Below 0°C',
          'Between 5°C and 63°C (41°F and 145°F)',
          'Between 70°C and 100°C',
          'Only above boiling point',
        ],
        correctIndex: 1,
        explanation: 'The danger zone is 5°C to 63°C. Safe hot holding is above 63°C and chilled storage is 5°C or below.',
      ),
      QuizQuestion(
        id: 'q3',
        question: 'Under FoodBridge principles, who holds final authority on accepting food donations?',
        options: [
          'The donor kitchen manager.',
          'The volunteer delivery driver.',
          'The mobile app automated algorithm.',
          'The partner NGO / food bank inspection staff.',
        ],
        correctIndex: 3,
        explanation: 'The partner NGO has sole, final authority on acceptance, safety verification, and distribution destinations.',
      ),
      QuizQuestion(
        id: 'q4',
        question: 'What is the First-In, First-Out (FIFO) kitchen principle?',
        options: [
          'Eat dessert first before the main course.',
          'Store newer stock behind older stock so older edible items are used first.',
          'Serve the first customer that arrives regardless of reservation.',
          'Discard all food in the refrigerator after 24 hours.',
        ],
        correctIndex: 1,
        explanation: 'FIFO ensures stock rotation where older batches are used before newer deliveries, preventing spoilage.',
      ),
      QuizQuestion(
        id: 'q5',
        question: 'Why must actual collected quantity be recorded separately from listed quantity?',
        options: [
          'To verify accurate diverted waste metrics and adjust for packaging tare weight.',
          'Because listed quantities are never recorded.',
          'To penalize donors for minor estimation errors.',
          'Because the volunteer decides the recipient price.',
        ],
        correctIndex: 0,
        explanation: 'Separating estimated vs verified collected quantity maintains data integrity and audit reliability.',
      ),
      QuizQuestion(
        id: 'q6',
        question: 'What happens to safe edible food remainder that cannot be distributed to primary shelters?',
        options: [
          'It is hidden from the records.',
          'It is recorded with disposition: animal feed, composting, or safe discard.',
          'It is automatically approved for resale.',
          'It is dumped without logging.',
        ],
        correctIndex: 1,
        explanation: 'Transparent food-bank records account for all surplus through verified disposition paths like compost or feed.',
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // 9. Initial Audit Logs
  // ---------------------------------------------------------------------------
  static final List<AuditLogModel> initialAuditLogs = [
    AuditLogModel(
      logId: 'log_1',
      actorId: 'system',
      actorName: 'FoodBridge Engine',
      actorRole: 'system',
      action: 'SYSTEM_INITIALIZATION',
      targetCollection: 'system',
      targetId: 'seed_v1',
      metadata: {'mode': 'demo', 'timestamp': now.toIso8601String()},
      timestamp: now.subtract(const Duration(days: 30)),
    ),
    AuditLogModel(
      logId: 'log_2',
      actorId: 'user_donor_1',
      actorName: 'Chef Anand Sharma',
      actorRole: 'donor',
      action: 'DONATION_CREATED',
      targetCollection: 'donations',
      targetId: 'don_101',
      metadata: {'food': 'Vegetable Biryani', 'status': 'awaitingNgoReview'},
      timestamp: now.subtract(const Duration(hours: 1)),
    ),
    AuditLogModel(
      logId: 'log_3',
      actorId: 'user_ngo_1',
      actorName: 'Sarah Jenkins',
      actorRole: 'ngo_staff',
      action: 'REVIEW_ACCEPTED',
      targetCollection: 'donations',
      targetId: 'don_103',
      metadata: {'decision': 'accepted', 'assignedVolunteer': 'user_volunteer_1'},
      timestamp: now.subtract(const Duration(hours: 3)),
    ),
  ];
}
