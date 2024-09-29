# # spec/requests/entries_spec.rb
# require 'rails_helper'

# RSpec.describe "Entries Management", type: :request do
#   include Devise::Test::IntegrationHelpers
#   include ActiveSupport::Testing::TimeHelpers
#   include ActionView::RecordIdentifier

#   let(:user) { create(:user) }
#   let(:profile) { create(:profile, user: user) }
#   let(:container) { create(:container) }
#   let(:role) { create(:role, kind: "Container Manager") }
#   let!(:assignment) { create(:assignment, user: user, container: container, role: role) }
#   let(:contest_description) { create(:contest_description, container: container) }
#   let(:date_closed) { 1.day.from_now }
#   let(:contest_instance) { create(:contest_instance, contest_description: contest_description, date_open: 2.days.ago, date_closed: date_closed) }
#   let!(:entry) { create(:entry, profile: profile, contest_instance: contest_instance, disqualified: false, deleted: false) }

#   before do
#     sign_in user
#   end

#   # Shared context for Turbo Stream format
#   shared_context "Turbo Stream requests" do
#     let(:headers_turbo_stream) { { "Accept" => "text/vnd.turbo-stream.html" } }
#   end

#   # Shared context for HTML format
#   shared_context "HTML requests" do
#     let(:headers_html) { { "Accept" => "text/html" } }
#   end

#   describe "PATCH /entries/:id/soft_delete" do
#     include_context "HTML requests"
#     include_context "Turbo Stream requests"

#     context "when the contest instance is still open (date_closed in the future)" do
#       let(:date_closed) { 1.day.from_now }

#       it "soft deletes the entry and redirects with a success notice (HTML)" do
#         patch soft_delete_entry_path(entry), headers: headers_html

#         entry.reload
#         expect(entry.deleted).to be true
#         expect(response).to redirect_to(applicant_dashboard_path)
#         follow_redirect!
#         # expect(response.body).to include('Entry was successfully removed.')
#       end

#       it "soft deletes the entry and responds with Turbo Stream" do
#         patch soft_delete_entry_path(entry), headers: headers_turbo_stream

#         entry.reload
#         expect(entry.deleted).to be true
#         expect(response.content_type).to start_with "text/vnd.turbo-stream.html"
#         expect(response.body).to include('Entry was successfully removed.')
#         expect(response.body).to include(dom_id(entry))
#       end
#     end

#     context "when the contest instance has closed (date_closed in the past)" do
#       let(:date_closed) { 1.day.ago }

#       it "does not delete the entry and redirects with an alert (HTML)" do
#         # puts "!!!@@@!!!@@@ #{contest_instance.inspect}"
#         patch soft_delete_entry_path(entry), headers: headers_html

#         entry.reload
#         expect(entry.deleted).to be false
#         expect(response).to redirect_to(applicant_dashboard_path)
#         follow_redirect!
#         expect(response.body).to include('Cannot delete entry after contest has closed.')
#       end

#       it "does not delete the entry and responds with Turbo Stream" do
#         travel_to Time.current do
#           patch soft_delete_entry_path(entry), headers: headers_turbo_stream

#           entry.reload
#           expect(entry.deleted).to be false
#           # expect(response).to have_http_status(:forbidden).or have_http_status(:redirect)
#           expect(response.body).to include('You are not authorized to perform this action.')
#         end
#       end
#     end

#     context "when the user is unauthorized to soft delete the entry" do
#       let(:unauthorized_user) { create(:user) }
#       let(:unauthorized_profile) { create(:profile, user: unauthorized_user) }
#       let!(:unauthorized_entry) { create(:entry, profile: unauthorized_profile, contest_instance: contest_instance, deleted: false) }

#       before do
#         sign_out user
#         sign_in unauthorized_user
#       end

#       it "does not delete the entry and redirects with an authorization alert (HTML)" do
#         patch soft_delete_entry_path(unauthorized_entry), headers: headers_html

#         unauthorized_entry.reload
#         expect(unauthorized_entry.deleted).to be false
#         expect(response).to redirect_to(root_path)
#         follow_redirect!
#         expect(response.body).to include('You are not authorized to perform this action.')
#       end

#       it "does not delete the entry and responds with Turbo Stream" do
#         patch soft_delete_entry_path(unauthorized_entry), headers: headers_turbo_stream

#         unauthorized_entry.reload
#         expect(unauthorized_entry.deleted).to be false
#         expect(response.content_type).to start_with "text/vnd.turbo-stream.html"
#         expect(response.body).to include('You are not authorized to perform this action.')
#       end
#     end

#     context "when the entry cannot be soft deleted due to validation errors" do
#       before do
#         # Simulate a validation error by making the update fail
#         allow_any_instance_of(Entry).to receive(:update).with(deleted: true).and_return(false)
#       end

#       it "does not delete the entry and redirects with a failure alert (HTML)" do
#         patch soft_delete_entry_path(entry), headers: headers_html

#         entry.reload
#         expect(entry.deleted).to be false
#         expect(response).to redirect_to(applicant_dashboard_path)
#         follow_redirect!
#         expect(response.body).to include('Failed to remove entry.')
#       end

#       it "does not delete the entry and responds with Turbo Stream" do
#         patch soft_delete_entry_path(entry), headers: headers_turbo_stream

#         entry.reload
#         expect(entry.deleted).to be false
#         expect(response.content_type).to start_with "text/vnd.turbo-stream.html"
#         expect(response.body).to include('Failed to remove entry.')
#       end
#     end
#   end

#   describe "PATCH /entries/:id/toggle_disqualified" do
#     include_context "HTML requests"
#     include_context "Turbo Stream requests"

#     context "when the user is authorized" do
#       context "when toggling from false to true" do
#         before do
#           entry.update(disqualified: false)
#         end

#         it "toggles the disqualified status to true and redirects with a success notice (HTML)" do
#           patch toggle_disqualified_entry_path(entry), headers: headers_html

#           entry.reload
#           expect(entry.disqualified).to be true
#           expect(response).to redirect_to(container_path(entry.contest_instance.contest_description.container))
#           follow_redirect!
#           expect(response.body).to include('Entry status updated successfully.')
#         end

#         it "toggles the disqualified status to true and responds with Turbo Stream" do
#           patch toggle_disqualified_entry_path(entry), headers: headers_turbo_stream

#           entry.reload
#           expect(entry.disqualified).to be true
#           expect(response.content_type).to start_with "text/vnd.turbo-stream.html"
#           expect(response.body).to include('Entry status updated successfully.')
#           expect(response.body).to include(dom_id(entry))
#         end
#       end

#       context "when toggling from true to false" do
#         before do
#           entry.update(disqualified: true)
#         end

#         it "toggles the disqualified status to false and redirects with a success notice (HTML)" do
#           patch toggle_disqualified_entry_path(entry), headers: headers_html

#           entry.reload
#           expect(entry.disqualified).to be false
#           expect(response).to redirect_to(container_path(entry.contest_instance.contest_description.container))
#           follow_redirect!
#           expect(response.body).to include('Entry status updated successfully.')
#         end

#         it "toggles the disqualified status to false and responds with Turbo Stream" do
#           patch toggle_disqualified_entry_path(entry), headers: headers_turbo_stream

#           entry.reload
#           expect(entry.disqualified).to be false
#           expect(response.content_type).to start_with "text/vnd.turbo-stream.html"
#           expect(response.body).to include('Entry status updated successfully.')
#           expect(response.body).to include(dom_id(entry))
#         end
#       end
#     end

#     context "when the user is unauthorized to toggle disqualified" do
#       let(:unauthorized_user) { create(:user) }
#       let(:unauthorized_profile) { create(:profile, user: unauthorized_user) }
#       let!(:unauthorized_entry) { create(:entry, profile: unauthorized_profile, contest_instance: contest_instance, disqualified: false) }

#       before do
#         sign_out user
#         sign_in unauthorized_user
#       end

#       it "does not toggle the disqualified status and redirects with an authorization alert (HTML)" do
#         patch toggle_disqualified_entry_path(unauthorized_entry), headers: headers_html

#         unauthorized_entry.reload
#         expect(unauthorized_entry.disqualified).to be false
#         expect(response).to redirect_to(root_path)
#         follow_redirect!
#         expect(response.body).to include('You are not authorized to perform this action.')
#       end

#       it "does not toggle the disqualified status and responds with Turbo Stream" do
#         patch toggle_disqualified_entry_path(unauthorized_entry), headers: headers_turbo_stream

#         unauthorized_entry.reload
#         expect(unauthorized_entry.disqualified).to be false
#         expect(response.content_type).to start_with "text/vnd.turbo-stream.html"
#         expect(response.body).to include('You are not authorized to perform this action.')
#       end
#     end

#     context "when the entry cannot be toggled due to validation errors" do
#       before do
#         # Simulate a validation error by making save return false
#         allow_any_instance_of(Entry).to receive(:save).and_return(false)
#       end

#       it "does not toggle the disqualified status and redirects with an alert (HTML)" do
#         patch toggle_disqualified_entry_path(entry), headers: headers_html

#         entry.reload
#         expect(entry.disqualified).to eq(false) # Assuming initial state was false
#         expect(response).to redirect_to(container_path(entry.contest_instance.contest_description.container))
#         follow_redirect!
#         expect(response.body).to include('Failed to update entry status.')
#       end

#       it "does not toggle the disqualified status and responds with Turbo Stream" do
#         patch toggle_disqualified_entry_path(entry), headers: headers_turbo_stream

#         entry.reload
#         expect(entry.disqualified).to eq(false) # Assuming initial state was false
#         expect(response.content_type).to start_with "text/vnd.turbo-stream.html"
#         expect(response.body).to include('Failed to update entry status.')
#       end
#     end
#   end

#   # Optional: Testing Non-existent Entry (Edge Case)
#   describe "PATCH /entries/:id/toggle_disqualified for non-existent entry" do
#     include_context "HTML requests"
#     include_context "Turbo Stream requests"

#     it "raises ActiveRecord::RecordNotFound error (HTML)" do
#       expect {
#         patch toggle_disqualified_entry_path(9999), headers: { "Accept" => "text/html" }
#       }.to raise_error(ActiveRecord::RecordNotFound)
#     end

#     it "raises ActiveRecord::RecordNotFound error (Turbo Stream)" do
#       expect {
#         patch toggle_disqualified_entry_path(9999), headers: { "Accept" => "text/vnd.turbo-stream.html" }
#       }.to raise_error(ActiveRecord::RecordNotFound)
#     end
#   end
# end
