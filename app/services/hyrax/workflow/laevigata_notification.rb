module Hyrax
  module Workflow
    class LaevigataNotification < AbstractNotification
      # regardless of what is passed in, set the recipients according to this notification's requirements
      def initialize(entity, comment, user, recipients = {})
        recipients ||= {} # provide default value when `nil` is explictly passed
        super
        @recipients = workflow_recipients.with_indifferent_access
      end

      def self.send_notification(entity:, comment:, user:, recipients: {})
        super
      end

      # Truncate titles to 140 characters
      def title
        original_title = @entity.proxy_for.title.first
        max = 140
        original_title.length > max ? "#{original_title[0...max]}..." : original_title
      end

      # Get the full URL for email notifications
      # This should get pushed upstream to Hyrax
      def document_url
        key = document.model_name.singular_route_key
        Rails.application.routes.url_helpers.send(key + "_url", document.id, host: "your_hostname_here")
      end

      def workflow_recipients
        raise NotImplementedError, "Implement workflow_recipients in a child class"
      end

      # The Users who have an approving role.
      # @return [<Array>::User] an Array of Hyrax::User objects
      def approvers
        Role.find_by_name('approver').users
      rescue
        []
      end

      # The Users who have a reviewing role
      # @return [<Array>::User] an Array of Hyrax::User objects
      def reviewers
        Role.find_by_name('reviewer').users
      rescue
        []
      end

      # The Hyrax::User who desposited the work
      # @return [Hyrax::User]
      def depositor
        ::User.find_by_user_key(document.depositor)
      end
    end
  end
end
