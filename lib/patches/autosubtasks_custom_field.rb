module RedmineAutosubtasksCustomfield
  module FieldFormatPatch
    extend ActiveSupport::Concern

    class AutosubtasksFormat < Redmine::FieldFormat::UserFormat
      add 'autosubtasks'
      self.customized_class_names = %w(Issue)
      self.form_partial = 'custom_fields/formats/autosubtasks'
      field_attributes :autosubtasks_tracker_id

      def label
        "label_field_for_autosubtasks"
      end

      def target_class
        @target_class ||= Principal
      end

      def formatted_custom_value(view, custom_value, html=false)
        formatted = super(view, custom_value, html)
        if html
          unless (html_text = format_obj(formatted, view)).blank?
            attrs = {
              tracker_id: custom_value.custom_field.autosubtasks_tracker_id,
              parent_issue_id: custom_value.customized,
              autosubtasks_for: Array(custom_value).map(&:value).to_json
            }
            # Show create subtasks button only for issues/show action
            if view.request.path_parameters[:action] == 'show'
            html_text +
              ( Array(formatted).size > 1 ? "<br />" : " &nbsp; " ).html_safe +
              view.link_to( l(:button_create),
                view.new_project_issue_path(custom_value.customized.project, issue: attrs),
                class: 'icon icon-multiple')
            else
              html_text
            end
          else
            "-"
          end
        else
          formatted
        end
      end

      def format_obj(object, view)
        case object.class.name
        when 'Array'
          object.map {|o| format_obj(o, view)}.join('<br />').html_safe
        when 'User'
          view.link_to_user(object)
        when 'Group'
          view.link_to(object.to_s, (User.current.admin? ? view.group_path(object) : "#" ), class: "group icon icon-group" )
        else
          ""
        end
      end

      def possible_values_options(custom_field, object=nil)
        possible_values_records(custom_field, object).map {|u| [u.name, u.id.to_s]}
      end

      def possible_values_records(custom_field, object=nil)
        if object.is_a?(Array)
          projects = object.map {|o| o.respond_to?(:project) ? o.project : nil}.compact.uniq
          projects.map {|project| possible_values_records(custom_field, project)}.reduce(:&) || []
        elsif object.respond_to?(:project) && object.project
          scope = object.project.principals
          if custom_field.user_role.is_a?(Array)
            role_ids = custom_field.user_role.map(&:to_s).reject(&:blank?).map(&:to_i)
            if role_ids.any?
              scope = scope.where("#{Member.table_name}.id IN (SELECT DISTINCT member_id FROM #{MemberRole.table_name} WHERE role_id IN (?))", role_ids)
            end
          end
          scope.sorted
        else
          []
        end
      end

    end
  end
end

unless Redmine::FieldFormat.included_modules.include?(RedmineAutosubtasksCustomfield::FieldFormatPatch)
    Redmine::FieldFormat.send(:include, RedmineAutosubtasksCustomfield::FieldFormatPatch)
end
