module RedmineAutosubtasksCustomfield
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
          if params[:issue].nil? or (user_ids = params[:issue][:autosubtasks_for]).nil?
            new_without_autotasks
          else
            begin
              users = Principal.where(id: JSON.parse(user_ids))
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
                    assigned_to: user,
                    description: "#{parent_issue.tracker.name} ##{parent_issue.id.to_s}",
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

unless IssuesController.included_modules.include?(RedmineAutosubtasksCustomfield::Patches::IssuesControllerPatch)
  IssuesController.send(:include, RedmineAutosubtasksCustomfield::Patches::IssuesControllerPatch)
end

