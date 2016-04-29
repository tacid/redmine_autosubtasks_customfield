module RedmineAutosubtasks
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
        @target_class ||= User
      end

      def formatted_custom_value(view, custom_value, html=false)
        formatted = super(view, custom_value, html)
        if html
          unless (html_text = view.format_object( formatted )).blank?
            attrs = {
              tracker_id: custom_value.custom_field.autosubtasks_tracker_id,
              parent_issue_id: custom_value.customized,
              autosubtasks_for: Array(custom_value).map(&:value).to_json
            }
            html_text + " &nbsp; ".html_safe +
            view.link_to( l(:button_create),
               view.new_project_issue_path( custom_value.customized.project, issue: attrs ),
               class: 'icon icon-multiple'
            )
          else
            "-"
          end
        else
          formatted
        end
      end

      private

      def create_subtasks_button
        "<button>Create it!</button>".html_safe
      end

    end
  end
end

unless Redmine::FieldFormat.included_modules.include?(RedmineAutosubtasks::FieldFormatPatch)
    Redmine::FieldFormat.send(:include, RedmineAutosubtasks::FieldFormatPatch)
end
