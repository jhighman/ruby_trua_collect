# Trua Collect

Trua Collect is a verification platform that collects and validates various types of information from candidates through a multi-step form wizard framework.

## Overview

The Trua Verify system collects and validates various types of information from candidates, including:

- Personal information
- Consents
- Residence history
- Employment history
- Education
- Professional licenses
- Digital signature

The system uses a "collection key" to dynamically configure which verification steps are required for each claim.

## Installation and Setup

### Running Migrations

Before you can use the application, you need to run the database migrations to create the necessary tables:

```bash
# Run migrations in development environment
bin/rails db:migrate

# Run migrations in test environment
bin/rails db:migrate RAILS_ENV=test
```

### Starting the Application

After running the migrations, you can start the Rails server:

```bash
bin/rails server
```

Then visit http://localhost:3000 in your browser.

## Documentation

Detailed documentation is available in the [docs](./docs) directory:

- [Data Model](./docs/data_model.md) - Details about the Trua Verify data model
- [Form Wizard Framework](./docs/form_wizard.md) - Documentation for the Form Wizard Framework
- [Developer Guide](./docs/DEVELOPER_GUIDE.md) - Guide for developers working with the Form Wizard Framework
- [UI Specification](./docs/UI_spec.md) - Detailed UI specifications for the Form Wizard
- [Future Iterations](./docs/FUTURE_ITERATIONS.md) - Planned enhancements for future development

## Testing

The project includes an in-memory SQLite database configuration for local testing:

```bash
# Start the Rails server with the in-memory database
bin/rails db:memory:server

# Start a Rails console with the in-memory database
bin/rails db:memory:console

# Just set up the in-memory database without starting a server or console
bin/rails db:memory:setup
```

## Collection Key

The collection key is a hyphen-separated string that drives the dynamic behavior of the form. For example: `en-EPA-DTB-R5-E5-E-P-W`

See the [Data Model](./docs/data_model.md) documentation for details on the collection key structure.