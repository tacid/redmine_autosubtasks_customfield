module RedmineAutosubtasksCustomfield
  module Patches

    module IssuePatch
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          # VISIBILITY PATCH
          class << self
            alias_method_chain :visible_condition, :autotasks_field
          end
          alias_method_chain :visible?, :autotasks_field
          alias_method_chain :attachments_visible?, :autotasks_field
        end
      end

      module ClassMethods
        def visible_condition_with_autotasks_field(user, options={})
          visible_condition_without_autotasks_field(user, options) + (
           ( user.instance_of?(User) && user.logged? ) ?
             " OR " +
             Issue.arel_table[:id].in(
               (cv=CustomValue.arel_table).project(cv[:customized_id])
                  .join( (cf = CustomField.arel_table), Arel::Nodes::OuterJoin )
                  .on( cf[:id].eq(cv[:custom_field_id]) )
                  .where( cv[:customized_type].eq("Issue")
                         .and( cv[:value].in( [user.id] + user.groups.pluck(:id) ) )
                         .and( cv[:custom_field_id].in(
                                 cf.project(:id).where(
                                   cf[:type].eq('IssueCustomField')
                                   .and( cf[:field_format].eq('autosubtasks') )
                                   .and( cf[:format_store].matches("%atf_is_issue_viewable: '1'%") )
                                 )
                         ) )
                  )
             ).to_sql
             : ""
          )
        end
      end

      module InstanceMethods
        def autotasks_permitted_to_view_principal_ids
          autotask_custom_fields = (cf=CustomField.arel_table).project(:id).where(
                                     cf[:type].eq('IssueCustomField')
                                     .and( cf[:field_format].eq('autosubtasks') )
                                     .and( cf[:format_store].matches("%atf_is_issue_viewable: '1'%") )
                                   )
          self.custom_values
              .where(CustomValue.arel_table[:custom_field_id].in(autotask_custom_fields))
              .pluck(:value).uniq.sort
        end

        def autotasks_permitted_to_view_principals
          Principal.where(id: autotasks_permitted_to_view_principal_ids).order(:id)
        end

        def visible_with_autotasks_field?(usr=nil)
          self.autotasks_permitted_to_view_principals.include?(usr || User.current) or
            (usr || User.current).groups(id: self.autotasks_permitted_to_view_principal_ids).count > 0 or
            visible_without_autotasks_field?(usr)
        end

        def attachments_visible_with_autotasks_field?(usr=nil)
          self.autotasks_permitted_to_view_principals.include?(usr || User.current) or
            (usr || User.current).groups(id: self.autotasks_permitted_to_view_principal_ids).count > 0 or
            attachments_visible_without_autotasks_field?(usr)
        end
      end

    end
  end
end

unless Issue.included_modules.include?(RedmineAutosubtasksCustomfield::Patches::IssuePatch)
  Issue.send(:include, RedmineAutosubtasksCustomfield::Patches::IssuePatch)
end

