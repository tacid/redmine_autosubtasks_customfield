Redmine::Plugin.register :redmine_autosubtasks_customfield do
  name 'Autosubtasks custom field'
  author 'Tacid'
  description 'This plugin adds the user customfield that allow to create subtasks in one click'
  version '0.9.4'
  url 'https://github.com/tacid/redmine_autosubtasks_customfield'
  author_url 'https://github.com/tacid'

  requires_redmine version_or_higher: '3.0.0'

  settings default: {}
end

ActionDispatch::Callbacks.to_prepare do
  require 'patches/autosubtasks_custom_field'
  require 'patches/issues_controller_patch'
end
