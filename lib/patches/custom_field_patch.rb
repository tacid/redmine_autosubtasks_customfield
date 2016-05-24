module RedmineAutosubtasksCustomfield
  module Patches

    module CustomFieldPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
      end

      module InstanceMethods
        %w(atf_is_issue_viewable atf_do_send_notifications atf_do_create_subtasks).each do |opt_name|
          define_method "#{opt_name}?" do |default_value=false|
            send(opt_name).blank? ? default_value == true : send(opt_name) == '1'
          end
        end
      end

    end
  end
end

unless CustomField.included_modules.include?(RedmineAutosubtasksCustomfield::Patches::CustomFieldPatch)
  CustomField.send(:include, RedmineAutosubtasksCustomfield::Patches::CustomFieldPatch)
end

