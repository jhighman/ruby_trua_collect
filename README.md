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

### Prerequisites

Before you begin, make sure you have the following installed:

- Ruby (version 3.0 or higher)
- Node.js and Yarn (for JavaScript dependencies)
- SQLite (for development database)

### Step 1: Clone the Repository

```bash
git clone https://github.com/jhighman/ruby_trua_collect.git
cd ruby_trua_collect
```

### Step 2: Install Dependencies

```bash
# Install Ruby dependencies
bundle install

# Install JavaScript dependencies
yarn install

# Install required Tailwind CSS plugins
yarn add --dev @tailwindcss/forms @tailwindcss/aspect-ratio @tailwindcss/typography @tailwindcss/container-queries tailwindcss-animate
```

### Step 3: Set Up the Database

```bash
# Run migrations in development environment
bin/rails db:migrate

# Run migrations in test environment
bin/rails db:migrate RAILS_ENV=test
```

### Step 4: Set Up Assets

```bash
# Create the builds directory if it doesn't exist
mkdir -p app/assets/builds

# Make sure the application.css file exists in the builds directory
touch app/assets/builds/application.css

# Copy the shadcn.css file to the builds directory
cp app/assets/stylesheets/shadcn.css app/assets/builds/

# Precompile assets
bin/rails assets:precompile RAILS_ENV=development
```

### Step 5: Start the Application

```bash
bin/rails server
```

Then visit http://localhost:3000 in your browser.

### Troubleshooting Styling Issues

If you encounter styling issues (missing CSS):

1. Make sure all Tailwind CSS plugins are installed:
   ```bash
   yarn add --dev @tailwindcss/forms @tailwindcss/aspect-ratio @tailwindcss/typography @tailwindcss/container-queries tailwindcss-animate
   ```

2. Rebuild the CSS:
   ```bash
   bin/rails tailwindcss:build
   ```

3. Ensure the shadcn.css file is in the builds directory:
   ```bash
   cp app/assets/stylesheets/shadcn.css app/assets/builds/
   ```

4. Restart the Rails server:
   ```bash
   bin/rails server
   ```

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

## Collection Key and Testing Different Configurations

The collection key is a hyphen-separated string that drives the dynamic behavior of the form. For example: `en-EPA-DTB-R5-E5-E-P-W`

### Collection Key Structure

The collection key has the following format:
```
<language>-<personal>-<consents>-<residence>-<employment>-<education>-<proLicense>-<signature>
```

Each segment configures a different aspect of the form:

1. **Language**: `en` for English, `es` for Spanish
2. **Personal Info**: `EPA` means Email, Phone, and Alias are required
3. **Consents**: `DTB` means Driver license, drug Test, and Biometric consents are required
4. **Residence History**: `R5` means 5 years of residence history is required
5. **Employment History**: `E5` means 5 years of employment history is required
6. **Education**: `E` means education verification is required
7. **Professional License**: `P` means professional license verification is required
8. **Signature**: `W` means wet signature (digital drawing) is required

### Example Collection Keys

To test different form configurations, you can use these example collection keys:

- `en-EPA-N-N-N-N-N-W`: English, Personal Info and Wet Signature only
- `en-EPA-DTB-R5-E5-E-P-W`: English, Full Collection with 5 years of history
- `en-EPA-N-N-EN2-N-N-W`: English, Personal Info, 2 Employers required, and Wet Signature
- `es-EPA-DTB-R5-E5-E-P-W`: Spanish, Full Collection with 5 years of history

See the [Data Model](./docs/data_model.md) documentation for more details on the collection key structure.