# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
EditableContent.create([
                         { page: 'home', section: 'instructions', content: ActionText::RichText.new(body: 'Lorem ipsum dolor sit amet, vince adipiscing elit,
                          sed do eiusmod tempor incididunt ut labore et dolore
                          magna aliqua. Ut enim ad minim veniam, quis nostrud
                          exercitation ullamco laboris nisi ut aliquip ex ea
                          commodo consequat. Duis aute irure dolor in reprehenderit
                          in voluptate velit esse cillum dolore eu fugiat nulla pariatur.') },
                         { page: 'home', section: 'description', content: 'Short paragraph explaining LSA Evaluate.' }
                       ])

Status.create([
                { kind: 'Active', description: 'The entity is active and operational.' },
                { kind: 'Deleted', description: 'The entity has been deleted.' },
                { kind: 'Archived', description: 'The entity is archived.' },
                { kind: 'Disqualified', description: 'The entity is disqualified.' }
              ])

Category.create([
                  { kind: 'Drama', description: 'Category for drama works.' },
                  { kind: 'Screenplay', description: 'Category for screenplay works.' },
                  { kind: 'Non-Fiction', description: 'Category for non-fiction works.' },
                  { kind: 'Fiction', description: 'Category for fiction works.' },
                  { kind: 'Poetry', description: 'Category for poetry works.' },
                  { kind: 'Novel', description: 'Category for novel works.' },
                  { kind: 'Short Fiction', description: 'Category for short fiction works.' },
                  { kind: 'Text-Image', description: 'Category for text-image works.' }
                ])

ClassLevel.create([
                    { level: 'Freshman', description: 'First year of high school.' },
                    { level: 'Sophomore', description: 'Second year of high school.' },
                    { level: 'Junior', description: 'Third year of high school.' },
                    { level: 'Senior', description: 'Fourth year of high school.' },
                    { level: 'Graduate', description: 'Post-secondary education.' }
                  ])
