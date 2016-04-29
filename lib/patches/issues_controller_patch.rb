module RedmineAutosubtasks
  module Patches

    module IssuesControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method_chain :new, :autotasks
        end
      end

      module InstanceMethods
        def new_with_autotasks
          if (user_ids = params[:issue][:autosubtasks_for]).nil?
            new_without_autotasks
          else
            begin
              users = User.where(id: JSON.parse(user_ids))
              parent_issue = Issue.find(params[:issue][:parent_issue_id])
              tracker = Tracker.find(params[:issue][:tracker_id])
            rescue
              flash[:error] = "Some error"
            else
              users.each do |user|
                if @project.issues.where(parent: parent_issue, tracker: tracker, assigned_to: user).count == 0
                  @project.issues.create(
                    subject: parent_issue.subject,
                    author: User.current,
                    parent: parent_issue,
                    tracker: tracker,
                    assigned_to: user
                  )
                end
              end
            ensure
              redirect_to :back if request.env["HTTP_REFERER"]
            end
          end
        end
      end

    end
  end
end

unless IssuesController.included_modules.include?(RedmineAutosubtasks::Patches::IssuesControllerPatch)
  IssuesController.send(:include, RedmineAutosubtasks::Patches::IssuesControllerPatch)
end

