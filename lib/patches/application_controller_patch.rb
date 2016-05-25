module RedmineAutosubtasksCustomfield
  module Patches
    module ApplicationControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method_chain :authorize, :autotasks_field
        end
      end

      module InstanceMethods

        def authorize_with_autotasks_field(ctrl = params[:controller], action = params[:action], global = false)
          ( "#{ctrl}/#{action}" == 'issues/show' and @issue.autotasks_permitted_to_view_users.include?(User.current)
          ) or authorize_without_autotasks_field(ctrl, action, global)
        end

      end
    end
  end
end

unless ApplicationController.included_modules.include?(RedmineAutosubtasksCustomfield::Patches::ApplicationControllerPatch)
  ApplicationController.send(:include, RedmineAutosubtasksCustomfield::Patches::ApplicationControllerPatch)
end
