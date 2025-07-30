# LSA Evaluate

[![Ruby on Rails](https://img.shields.io/badge/Ruby%20on%20Rails-7.2-red)](https://rubyonrails.org/)
[![Ruby](https://img.shields.io/badge/Ruby-3.3.4-blue)](https://www.ruby-lang.org/en/)
[![MySQL](https://img.shields.io/badge/Database-MySQL%208-green)](https://www.mysql.com/)

LSA Evaluate is a Ruby on Rails application designed to facilitate a comprehensive submission and evaluation process. The application allows entrants to complete a profile, submit a body of work electronically, and have that work evaluated. Key features include the maintenance of entry forms, management of evaluations, and visual cues to entrants regarding the status of their submissions.

Initially developed to support the submission processes for Hopwood and MFA, LSA Evaluate is built with flexibility in mind, enabling other units to onboard their contest submission workflows as well. By migrating to this new platform, LSA Technology Services Web and Applications Development Services Team can better support these processes and enterprise the application for broader use across the organization.

## Target Audience

In its initial implementation, LSA Evaluate will serve the University of Michigan (UM) community, allowing UM students to participate in any submission workflow created within the platform. Administrators of LSA Evaluate can grant access to both UM and non-UM individuals to evaluate submissions.

## Technical Specifications

- **Ruby on Rails:** 7.2
- **Ruby Version:** 3.3.4
- **Database:** MySQL 8

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
   rails db:create db:migrate

  ```

4. **Run the server:**

  ```bash
   rails server
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
4. Ensure Sidekiq is set up and running to process emails asynchronously

Emails are automatically configured to be sent asynchronously through Sidekiq background jobs.

## Protected Branches and Pre-Push Hook

This repository uses [branch protection rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/branch-protection-rules) for `staging` and `main` branches.
Direct pushes are restricted and enforced by a pre-push hook.

**Summary:**

- Non-admins: Must open a Pull Request to contribute to protected branches.
- Admins: Can push directly if listed in `.git-hooks/admins.txt`.
- All pushes to protected branches run tests automatically, unless skipped.
- For details on hook installation, admin setup, and troubleshooting, see [.git-hooks/README.md](.git-hooks/README.md).

## This project is licensed under the [MIT License](https://github.com/your-repo/lsa-evaluate/blob/main/LICENSE)
