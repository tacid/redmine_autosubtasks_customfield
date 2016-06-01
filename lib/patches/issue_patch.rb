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
          alias_method_chain :notified_users, :autotasks_field
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
        def autotasks_permitted_to_view_users
          autotasks_custom_value_users_for_option("%atf_is_issue_viewable: '1'%")
        end

        def autotasks_notifications_users
          autotasks_custom_value_users_for_option("%atf_do_send_notifications: '1'%")
        end

        def autotasks_users_for_cf_name(cf_name)
          autotasks_custom_value_users(
            self.custom_values.where(
              custom_field: CustomField.where(field_format: 'autosubtasks').find_by_name(cf_name)
            ).pluck(:value)
          )
        end

        def notified_users_with_autotasks_field
          notified = Array(autotasks_notifications_users)
          # Remove users that can not view the issue
          notified.reject! {|user| !visible?(user)}
          notified += notified_users_without_autotasks_field
          notified.uniq!
          notified
        end

        def visible_with_autotasks_field?(usr=nil)
          self.autotasks_permitted_to_view_users.include?(usr || User.current) or
            visible_without_autotasks_field?(usr)
        end

        def attachments_visible_with_autotasks_field?(usr=nil)
          self.autotasks_permitted_to_view_users.include?(usr || User.current) or
            attachments_visible_without_autotasks_field?(usr)
        end

        private

        # Returns values from all custom fields with autosubtasks field format
        def autotasks_custom_value_ids(like_clause="%")
          autotask_custom_fields = (cf=CustomField.arel_table).project(:id).where(
                                     cf[:type].eq('IssueCustomField')
                                     .and( cf[:field_format].eq('autosubtasks') )
                                     .and( cf[:format_store].matches(like_clause) )
                                   )
          self.custom_values
              .where(CustomValue.arel_table[:custom_field_id].in(autotask_custom_fields))
              .pluck(:value).compact.uniq
        end

        def autotasks_custom_value_users_for_option(like_clause='%')
          autotasks_custom_value_users(autotasks_custom_value_ids(like_clause))
        end

        # Returns users selected and users from selected groups
        # in all the custom fields in issue with autosubtasks field format
        def autotasks_custom_value_users(ids=nil)
          ids ||= autotasks_custom_value_ids('%')
          groups_users = Arel::Table.new(:groups_users)
          users = User.arel_table

          User.where(
            users[:id].in(ids)
            .or(users[:id].in(
                groups_users.project(:user_id).where( groups_users[:group_id].in(ids) ) ) )
          ).order(:id)
        end
      end

    end
  end
end

unless Issue.included_modules.include?(RedmineAutosubtasksCustomfield::Patches::IssuePatch)
  Issue.send(:include, RedmineAutosubtasksCustomfield::Patches::IssuePatch)
end

