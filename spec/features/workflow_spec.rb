# Generated via
#  `rails generate hyrax:work Image`
require 'rails_helper'
include Warden::Test::Helpers

# NOTE: If you generated more than one work, you have to set "js: true"
RSpec.feature 'Create a Image', js: false do
  context 'a logged in user' do
    let(:depositor) { FactoryBot.create(:user) }
    let(:reviewer) { FactoryBot.create(:user) }
    let(:approver) { FactoryBot.create(:user) }
    let(:admin_set_id) { AdminSet.find_or_create_default_admin_set_id }
    let(:work) { Image.new(title: ['My Fake Title'], visibility: 'open', depositor: depositor.user_key) }

    before do
      admin_set_id # Ensure default admin set is created

      reviewer_role = Role.find_or_create_by(name: 'reviewer')
      reviewer_role.users << reviewer
      reviewer_role.save

      approver_role = Role.find_or_create_by(name: 'approver')
      approver_role.users << approver
      approver_role.save

      login_as depositor
      image_binary = File.open("#{::Rails.root}/spec/fixtures/birds.jpg")
      uploaded_file = Hyrax::UploadedFile.create(user: @user, file: image_binary)
      attributes_for_actor = { uploaded_files: [uploaded_file.id] }
      env = Hyrax::Actors::Environment.new(work, ::Ability.new(depositor), attributes_for_actor)
      Hyrax::CurationConcern.actor.create(env)
      image_binary.close
    end

    scenario "deposits a work" do
      default_admin_set = AdminSet.first
      expect(default_admin_set.active_workflow.name).to eq "my_customized_workflow"

      # The reviewer is in the reviewer role
      reviewer_role = Role.find_by_name('reviewer')
      expect(reviewer_role.users.first.user_key).to eq reviewer.user_key

      # A newly deposited item is in the pending_review state when it is first created
      deposited_item = Image.first
      expect(deposited_item.to_sipity_entity.reload.workflow_state_name).to eq "pending_review"

      # Visit the newly deposited item as a public user. It should not be visible.
      logout
      visit("/concern/images/#{deposited_item.id}")
      expect(page).to have_content "The work is not currently available"

      # Check workflow permissions for depositing user.
      # Once they have deposited their item, they cannot do anything unless it
      # is returned to them.
      available_workflow_actions = Hyrax::Workflow::PermissionQuery.scope_permitted_workflow_actions_available_for_current_state(
        user: depositor,
        entity: deposited_item.to_sipity_entity
      ).pluck(:name)
      expect(available_workflow_actions).to be_empty

      # Check notifications for depositing user
      login_as depositor
      visit("/notifications")
      expect(page).to have_content 'Deposit needs review'
      expect(page).to have_content "#{deposited_item.title.first} (#{deposited_item.id}) was deposited by #{depositor.display_name} and is awaiting initial review."

      # Check notifications for reviewer
      logout
      login_as reviewer
      visit("/notifications")
      expect(page).to have_content 'Deposit needs review'
      expect(page).to have_content "#{deposited_item.title.first} (#{deposited_item.id}) was deposited by #{depositor.display_name} and is awaiting initial review."

      # The reviewer marks it as reviewed
      subject = Hyrax::WorkflowActionInfo.new(deposited_item, reviewer)
      sipity_workflow_action = PowerConverter.convert_to_sipity_action("mark_as_reviewed", scope: subject.entity.workflow) { nil }
      Hyrax::Workflow::WorkflowActionService.run(subject: subject, action: sipity_workflow_action, comment: nil)
      expect(deposited_item.to_sipity_entity.reload.workflow_state_name).to eq "pending_approval"

      # Check notifications for approving user
      logout
      login_as approver
      visit("/notifications")
      expect(page).to have_content "#{deposited_item.title.first} (#{deposited_item.id}) has completed initial review and is awaiting final approval."

      # The approving user marks the item as approved
      subject = Hyrax::WorkflowActionInfo.new(deposited_item, approver)
      sipity_workflow_action = PowerConverter.convert_to_sipity_action("approve", scope: subject.entity.workflow) { nil }
      Hyrax::Workflow::WorkflowActionService.run(subject: subject, action: sipity_workflow_action, comment: nil)
      expect(deposited_item.to_sipity_entity.reload.workflow_state_name).to eq "approved"

      # Check notifications for approving user
      visit("/notifications")
      expect(page).to have_content "#{deposited_item.title.first}\" has been approved by"

      # Check notifications for depositor again
      logout
      login_as depositor
      visit("/notifications")
      expect(page).to have_content "#{deposited_item.title.first} (#{deposited_item.id}) has completed initial review and is awaiting final approval."
      expect(page).to have_content "#{deposited_item.title.first}\" has been approved by"

      # Now the work should be publicly visible
      logout
      visit("/concern/images/#{deposited_item.id}")
      expect(page).to have_content deposited_item.title.first
      expect(page).to have_content "Approved"
    end
  end
end
