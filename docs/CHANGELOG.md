# Changelog

All notable changes to the trua_collect project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-08-07

### Added
- shadcn-ui component library integration
- tailwind_merge dependency for handling Tailwind CSS class conflicts
- Tailwind CSS configuration for shadcn design system
- Data traceability and audit features
  - AuditLog model for tracking changes
  - AuditService for logging form submission changes
  - Audit trail view for reviewing submission history
- State persistence and navigation
  - NavigationService for handling form navigation
  - Save and resume functionality
  - Navigation state tracking
- Performance optimizations
  - Lazy loading service for improved resource loading
  - Cache store configuration
- Advanced features
  - Conditional logic service for dynamic form behavior
  - Dynamic step service for flexible form flows
  - File upload service for handling attachments
  - Integration service for external system connections
  - Multi-path workflow service for complex form journeys
- Developer experience improvements
  - Form wizard generator for scaffolding new forms
  - Form wizard test helpers
  - Cleanup tasks

### Changed
- Updated all form step views to use shadcn-ui components:
  - personal_info.html.erb
  - signature.html.erb
  - residence_history.html.erb
  - consents.html.erb
  - education.html.erb
- Replaced Bootstrap components with shadcn-ui equivalents
- Migrated from PostgreSQL to SQLite for simpler development setup
- Improved form layout and styling with Tailwind CSS
- Enhanced documentation structure and organization
- Reorganized project files for better maintainability

### Fixed
- Fixed nil check for @requirements in signature.html.erb
- Fixed syntax error in signature.html.erb by removing duplicate code
- Addressed various styling inconsistencies
- Improved form validation and error handling