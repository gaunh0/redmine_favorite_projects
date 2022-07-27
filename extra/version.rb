#!/usr/bin/ruby

require "fileutils"
require 'date'

GPL2_HEADER = "# This file is a part of Redmine Favorite projects (redmine_favorite_projects) plugin
#
# Copyright (C) 2011-#{Date.today.year} RedmineUP
# http://www.redmineup.com/
#
# redmine_favorite_projects is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_favorite_projects is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_favorite_projects.  If not, see <http://www.gnu.org/licenses/>.

"

def pro_version(text)
  text.force_encoding('utf-8') if text.respond_to?(:force_encoding)
  text.gsub(/(\s*(#|<!--)[ ]*<[\/]?PRO>[^\n\r]*(-->)*|[ ]*(#|<!--)\s*<LIGHT\/>[^\n\r]*)/m, "")
end

def light_version(text)
  text.force_encoding('utf-8') if text.respond_to?(:force_encoding)
  text.gsub(/((#|<!--)[ ]*<LIGHT\/>\s*|\s*(#|<!--)[ ]*<PRO>.*?<\/PRO>)[ ]*(-->)*/m, "")
end

def add_gpl2_license_header(files)
  files.each do |file_name|
    file_content = File.read(file_name)
    file_content = GPL2_HEADER + file_content
    file_content = "# encoding: utf-8\n#\n" + file_content if file_name.match(/.*_(test|helper)\.rb/)
    File.open(file_name, "w") {|file| file.puts file_content}
  end
end

plugin_dir = File.expand_path('../', File.dirname(__FILE__))

Dir["#{plugin_dir}/**/*.rb",
    "#{plugin_dir}/**/*.erb",
    "#{plugin_dir}/**/*.api.rsb",
    "#{plugin_dir}/Gemfile"].each do |file_name|
  text = File.read(file_name)

  if ARGV && ARGV[0] == 'light'
    patched_file = light_version(text)
  else
    patched_file = pro_version(text)
  end

  File.open(file_name, "w") {|file| file.puts patched_file}
end

add_gpl2_license_header(Dir["#{plugin_dir}/**/*.rb"])

FileUtils.rm_r Dir["#{plugin_dir}/.drone.yml"], :force => true
