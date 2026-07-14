# LSA Evaluate

[![Ruby on Rails](https://img.shields.io/badge/Ruby%20on%20Rails-8.1-red)](https://rubyonrails.org/)
[![Ruby](https://img.shields.io/badge/Ruby-4.0.6-blue)](https://www.ruby-lang.org/en/)
[![MySQL](https://img.shields.io/badge/Database-MySQL%208-green)](https://www.mysql.com/)

LSA Evaluate is a Ruby on Rails application designed to facilitate a comprehensive submission and evaluation process. The application allows entrants to complete a profile, submit a body of work electronically, and have that work evaluated. Key features include the maintenance of entry forms, management of evaluations, and visual cues to entrants regarding the status of their submissions.

Initially developed to support the submission processes for Hopwood and MFA, LSA Evaluate is built with flexibility in mind, enabling other units to onboard their contest submission workflows as well. By migrating to this new platform, LSA Technology Services Web and Applications Development Services Team can better support these processes and enterprise the application for broader use across the organization.

## Target Audience

In its initial implementation, LSA Evaluate will serve the University of Michigan (UM) community, allowing UM students to participate in any submission workflow created within the platform. Administrators of LSA Evaluate can grant access to both UM and non-UM individuals to evaluate submissions.

## Technical Specifications

- **Ruby on Rails:** 8.1
- **Ruby Version:** 4.0.6
- **Database:** MySQL 8 (primary + Solid Queue / Cache / Cable databases)
- **Assets:** Propshaft + cssbundling-rails / jsbundling-rails (esbuild + Dart Sass)
- **Jobs:** Solid Queue (via Puma plugin in production/staging)
- **Cache / Cable:** Solid Cache and Solid Cable (no Redis)

> Note: `lsa_tdx_feedback` still declares a Redis gem dependency, so `redis` may appear transitively in `Gemfile.lock`, but the application no longer uses Redis for jobs, cache, or Action Cable.

## Installation

1. **Clone the repository:**

  ```bash
   git clone https://github.com/your-repo/lsa-evaluate.git
   cd lsa-evaluate
  ```

2. **Install dependencies:**

  ```bash
   bundle install
   yarn install
  ```

3. **Set up the database:**

  ```bash
   rails db:create db:prepare
  ```

  This creates the primary database plus queue, cache, and cable databases and loads their schemas.

4. **Build assets and run the server:**

  ```bash
   yarn build && yarn build:css
   bin/dev
  ```

## Email Configuration with SendGrid

This application uses SendGrid for email delivery in the production environment. Follow these steps to set it up:

1. Create a SendGrid account if you don't have one already
2. Generate an API key in the SendGrid dashboard
3. Set the following environment variables in your production environment:
   ```
   SENDGRID_USERNAME=apikey
   SENDGRID_API_KEY=your_sendgrid_api_key_here
   DOMAIN_NAME=yourdomain.com
   ```
4. Solid Queue runs inside Puma in production/staging and processes `deliver_later` mailers asynchronously. Monitor jobs at `/jobs` (axis_mundi users).

## Production / Staging Ops Notes

Before deploying:

1. Install Ruby 4.0.6 via asdf on the host.
2. Create MySQL databases: `evaluate_db_prod_queue`, `evaluate_db_prod_cache`, `evaluate_db_prod_cable` (and staging equivalents / `QUEUE_DATABASE_URL`, `CACHE_DATABASE_URL`, `CABLE_DATABASE_URL` if separate).
3. Run `rails db:prepare` (or load `db/queue_schema.rb`, `db/cache_schema.rb`, `db/cable_schema.rb`) on those databases.
4. Stop and remove Sidekiq/Redis once in-flight Sidekiq jobs are drained.
5. Restart Puma after deploy — Solid Queue is enabled via the Puma plugin.

## Protected Branches and Pre-Push Hook

This repository uses [branch protection rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/branch-protection-rules) for `staging` and `main` branches.
Direct pushes are restricted and enforced by a pre-push hook.

**Summary:**

- Non-admins: Must open a Pull Request to contribute to protected branches.
- Admins: Can push directly if listed in `.git-hooks/admins.txt`.
- All pushes to protected branches run tests automatically, unless skipped.
- For details on hook installation, admin setup, and troubleshooting, see [.git-hooks/README.md](.git-hooks/README.md).

## AppSignal

AppSignal is currently enabled only for the staging environment on Hatchbox.

Required Hatchbox environment variables:

```sh
APPSIGNAL_PUSH_API_KEY
APPSIGNAL_APP_NAME=LSAEvaluate
APPSIGNAL_APP_ENV=staging
APPSIGNAL_ACTIVE=true
```

Production on MiServer does not currently have AppSignal enabled.

## This project is licensed under the [MIT License](https://github.com/your-repo/lsa-evaluate/blob/main/LICENSE)
