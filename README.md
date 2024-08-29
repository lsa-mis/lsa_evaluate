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

## This project is licensed under the [MIT License](https://github.com/your-repo/lsa-evaluate/blob/main/LICENSE)
