# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Event5050 is a Rails 8.0.2 application that appears to be a 50/50 raffle event platform. It uses PostgreSQL with PostGIS for spatial data, UUIDs as primary keys, and follows a Hotwire-first approach with server-side rendering. See @event5050_specification.txt for additional specifictions.

## Memory: Specification File Reference

- The @event5050_specification.txt file contains critical project specifications and should be referenced for detailed project requirements and design guidelines.

## Development Commands

```bash
# Start development server (Rails + Tailwind CSS watcher)
bin/dev

# Restart the development server
touch tmp/restart.txt

# Setup development environment
bin/setup

# Run Rails console
bin/rails console

# Run database migrations
bin/rails db:migrate

# Run tests
bin/rails test

# Run system tests
bin/rails test:system

# Run linter
bundle exec rubocop

# Run security scanner
bundle exec brakeman

# Manage JavaScript imports
bin/importmap

# Deploy with Kamal
bin/kamal deploy
```

## Architecture & Stack

### Backend
- Rails 8.0.2 with PostgreSQL database
- PostGIS enabled for spatial/geographic data queries
- pgcrypto for UUID primary keys (configured globally)
- Solid Cache, Solid Queue, and Solid Cable for database-backed adapters

### Frontend
- Hotwire stack (Turbo + Stimulus) for SPA-like behavior without API
- Tailwind CSS with DaisyUI component library
- Import maps for JavaScript (no bundler)
- CSS processed through `app/assets/tailwind/application.css`

### Key Configuration
- UUIDs as primary keys by default (see `config/application.rb`)
- PostGIS adapter for ActiveRecord
- Database names follow pattern: `event5050_[environment]`
- Propshaft for asset pipeline (not Sprockets)

### Testing
- Minitest (not RSpec) following Rails conventions
- Capybara with headless Chrome for system tests
- Parallel testing enabled
- Perform test driven development - develop failing tests first and then implement passing code. Do not mock objects unless neccesary.

## Database Considerations

When creating models that need spatial data:
- Use PostGIS data types (geometry, geography)
- The PostGIS extension is already enabled
- pgcrypto is available for additional cryptographic functions

## Frontend Development

When adding UI components:
- Use DaisyUI classes for consistent theming
- Follow Stimulus conventions for JavaScript behavior
- Place Stimulus controllers in `app/javascript/controllers/`
- Tailwind classes are available throughout the application

## Memory

- When adding things like statuses used enums not strings