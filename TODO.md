# TODO.md - Event5050 Implementation Plan

## Current Focus: Multistep Organization Onboarding

### Phase 1: Foundation (High Priority)
- [ ] Research existing authentication setup and check for Wicked gem
- [ ] Install and configure required gems (Devise, acts_as_tenant, Wicked)
- [ ] Create OrgUser model with Devise authentication
- [ ] Create Organization model with OrgUser associations
- [ ] Set up multitenancy with acts_as_tenant for OrgUser scope

### Phase 2: Wicked Onboarding Controller (Medium Priority)
- [ ] Create organization-scoped Wicked onboarding controller
- [ ] Design org-specific views with DaisyUI components
- [ ] Add role-based permissions for org users (admin, finance, legal, support)
- [ ] Write tests for OrgUser and Organization onboarding flow
- [ ] Add organization-specific flash messages and error handling

**Onboarding Flow Steps:**
1. **org_user_details** - Organization user registration (name, email, password)
2. **organization_info** - Organization creation (name, description, contact info)
3. **confirmation** - Review details and finalize

**Core Models:**
- **OrgUser:** Devise authentication, belongs to Organization, role enum, first user becomes admin
- **Organization:** Basic info, has many OrgUsers, UUID primary key

---

## Currency Migration to Money::Currency Objects - COMPLETED ✅

**Implementation Date:** June 13, 2025

### What was accomplished:
- ✅ **Organization Currency Support**: Added currency column and Money::Currency object support
- ✅ **Raffle Currency Inheritance**: Raffles inherit currency from Organization with override capability  
- ✅ **Draw Currency Inheritance**: Draws inherit currency from Raffle
- ✅ **PricingTier Currency Support**: PricingTiers inherit from Raffle with override capability
- ✅ **Ticket Currency Support**: Tickets inherit currency through the full chain
- ✅ **Service Layer Integration**: FeeCalculator and PrizePoolDistributor use Money::Currency objects
- ✅ **Comprehensive Testing**: Full TDD approach with model, service, and integration tests

### Currency Inheritance Chain:
```
Organization (EUR) 
    ↓ 
Raffle (inherits EUR, can override)
    ↓
Draw (inherits from Raffle)
    ↓  
PricingTier (inherits from Raffle, can override)
    ↓
Ticket (inherits through chain: ticket_purchase → pricing_tier → draw)
```

### Key Features:
- **Multi-currency support** across the entire platform
- **Inheritance chain** ensures currency consistency
- **Override capability** at Raffle and PricingTier levels
- **Money::Currency objects** instead of strings for type safety
- **Service integration** with proper currency handling
- **Database migrations** to support currency columns
- **Comprehensive test coverage** including edge cases

### Database Changes:
- Added `currency` column to `organizations` table
- Added `currency` column to `raffles` table  
- Removed database defaults to support inheritance
- All currency columns are non-null strings

### Files Modified:
- Models: `Organization`, `Raffle`, `Draw`, `PricingTier`, `Ticket`
- Services: Enhanced `FeeCalculator` and `PrizePoolDistributor` tests
- Tests: Comprehensive test coverage for all models and services
- Integration tests: End-to-end currency inheritance validation

---

## Future Implementation Phases

## Phase 3: Geographic & Licensing System
- [ ] Create Jurisdiction model with PostGIS geography column
- [ ] Implement GEOJSON storage and parsing for jurisdiction boundaries
- [ ] Create License model with requirements (age limits, fees, geographic restrictions)
- [ ] Add License types (single draw vs recurring)
- [ ] Create LicenseRequirement model for flexible requirement rules
- [ ] Implement license validation service
- [ ] Add jurisdiction management interface (admin only)
- [ ] Create license application and approval workflow

## Phase 3: Geographic & Licensing System
- [ ] Create Jurisdiction model with PostGIS geography column
- [ ] Implement GEOJSON storage and parsing for jurisdiction boundaries
- [ ] Create License model with requirements (age limits, fees, geographic restrictions)
- [ ] Add License types (single draw vs recurring)
- [ ] Create LicenseRequirement model for flexible requirement rules
- [ ] Implement license validation service
- [ ] Add jurisdiction management interface (admin only)
- [ ] Create license application and approval workflow

## Phase 4: Raffle & Draw Structure
- [ ] Create Raffle model (belongs to organization, has license)
- [ ] Implement ice_cube integration for recurring raffle schedules
- [ ] Create Draw model (time-boxed ticket sales period)
- [ ] Add draw scheduling logic for recurring raffles
- [ ] Create PriceTier model for ticket pricing options
- [ ] Implement draw state machine (upcoming, active, closed, completed)
- [ ] Add automatic draw closure job using Solid Queue
- [ ] Create raffle/draw management interface for organizations

## Phase 5: Ticket System
- [ ] Create Ticket model with UUIDv7-based human-readable numbers
- [ ] Implement ticket numbering service (format UUIDv7 for readability)
- [ ] Create TicketPurchase model for transaction tracking
- [ ] Add ticket reservation system (temporary hold during checkout)
- [ ] Implement geographic validation for ticket purchases
- [ ] Add age verification checks based on jurisdiction
- [ ] Create ticket purchase interface for end users
- [ ] Add "My Tickets" dashboard for purchasers

## Phase 6: Payment Integration
- [ ] Install and configure Stripe gem
- [ ] Implement Stripe Connect onboarding for organizations
- [ ] Create Payment model for transaction records
- [ ] Add money-rails configuration for multi-currency support
- [ ] Implement ticket purchase checkout flow with Stripe
- [ ] Add payment failure handling and retry logic
- [ ] Create refund processing system
- [ ] Implement escrow account management for prize funds

## Phase 7: Prize & Draw Execution
- [ ] Create Prize model (main prize + secondary prizes)
- [ ] Create PrizeType model (percentage vs fixed amount)
- [ ] Implement DrawExecutionService for closing draws
- [ ] Add verifiable RNG system with audit trail
- [ ] Create WinnerSelectionService ensuring no duplicate wins
- [ ] Implement prize pool calculation with fee deductions
- [ ] Add PrizeDistributionService for fund transfers
- [ ] Create draw results interface with winner display

## Phase 8: Notifications & Communications
- [ ] Configure ActionMailer with SendGrid
- [ ] Create mailer for winner notifications
- [ ] Create mailer for draw reminders
- [ ] Add Twilio integration for SMS
- [ ] Implement notification preferences for users
- [ ] Create email templates using DaisyUI styling
- [ ] Add real-time updates via Action Cable for live draws

## Phase 9: Financial Management
- [ ] Create FinancialTransaction model for audit trail
- [ ] Implement fee calculation service (platform, license, organization)
- [ ] Add financial reporting for organizations
- [ ] Create reconciliation tools
- [ ] Implement tax reporting features
- [ ] Add financial dashboard for finance role users
- [ ] Create payout scheduling system

## Phase 10: Analytics & Reporting
- [ ] Create analytics dashboard for organizations
- [ ] Add ticket sales reports
- [ ] Implement draw performance metrics
- [ ] Create license compliance reports
- [ ] Add platform-wide admin dashboard
- [ ] Implement data export functionality

## Phase 11: Security & Compliance
- [ ] Add comprehensive audit logging for financial transactions
- [ ] Implement rate limiting for ticket purchases
- [ ] Add fraud detection rules
- [ ] Create security testing suite
- [ ] Implement PCI compliance measures
- [ ] Add WCAG 2.1 AA accessibility features
- [ ] Create compliance dashboard for legal role users

## Phase 12: Performance & Optimization
- [ ] Add database indexes for critical queries
- [ ] Implement caching strategy for jurisdictions and active draws
- [ ] Optimize PostGIS spatial queries
- [ ] Add background job monitoring
- [ ] Implement CDN for assets
- [ ] Add application performance monitoring

## Phase 13: Testing & Quality Assurance
- [ ] Set up factory_bot with comprehensive factories
- [ ] Write model tests with edge cases
- [ ] Create integration tests for payment flows
- [ ] Add system tests for critical user paths
- [ ] Implement security testing suite
- [ ] Add performance benchmarks
- [ ] Create data migration tests

## Phase 14: Documentation & Deployment
- [ ] Create API documentation (if applicable)
- [ ] Write user guides for each role
- [ ] Document deployment process
- [ ] Set up staging environment
- [ ] Configure Kamal for deployment
- [ ] Create backup and disaster recovery procedures
- [ ] Implement monitoring and alerting

## Technical Debt & Refactoring
- [ ] Refactor controllers to use service objects consistently
- [ ] Extract complex queries to query objects
- [ ] Optimize N+1 queries
- [ ] Improve error handling consistency
- [ ] Standardize API responses
- [ ] Clean up and organize JavaScript controllers

## Future Enhancements
- [ ] Mobile app API endpoints
- [ ] Advanced fraud detection with ML
- [ ] Multi-language support
- [ ] White-label options for organizations
- [ ] Advanced analytics with data visualization
- [ ] Integration with other payment providers
- [ ] Blockchain-based draw verification option