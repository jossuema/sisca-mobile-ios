#!/usr/bin/env ruby
# Genera SISCAMobile.xcodeproj usando la gema `xcodeproj` (viene con CocoaPods).
# Uso:  ruby gen_project.rb
# Reejecutable: recrea el proyecto desde cero a partir de los archivos en SISCAMobile/.

require 'xcodeproj'
require 'fileutils'

ROOT         = File.expand_path(File.dirname(__FILE__))
PROJECT_PATH = File.join(ROOT, 'SISCAMobile.xcodeproj')
SRC_DIR      = File.join(ROOT, 'SISCAMobile')
BUNDLE_ID    = 'com.example.siscamobile'
DEPLOY       = '16.0'

FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH)
target  = project.new_target(:application, 'SISCAMobile', :ios, DEPLOY)

app_group = project.main_group.new_group('SISCAMobile', 'SISCAMobile')

# Recorre SISCAMobile/ creando grupos que reflejan las carpetas y añade los archivos
# al build phase correspondiente.
add_dir = lambda do |fs_dir, group|
  Dir.children(fs_dir).sort.each do |entry|
    path = File.join(fs_dir, entry)
    if File.directory?(path)
      if entry.end_with?('.xcassets')
        ref = group.new_reference(entry)
        target.resources_build_phase.add_file_reference(ref)
      else
        add_dir.call(path, group.new_group(entry, entry))
      end
    else
      case entry
      when /\.swift$/
        target.source_build_phase.add_file_reference(group.new_reference(entry))
      when 'Info.plist'
        group.new_reference(entry) # referenciado vía INFOPLIST_FILE, no en build phase
      when 'Config.plist'
        target.resources_build_phase.add_file_reference(group.new_reference(entry))
      when 'Config.plist.example'
        group.new_reference(entry) # solo visible en el navegador, no se copia
      end
    end
  end
end

add_dir.call(SRC_DIR, app_group)

target.build_configurations.each do |config|
  bs = config.build_settings
  bs['SWIFT_VERSION']                 = '5.0'
  bs['IPHONEOS_DEPLOYMENT_TARGET']    = DEPLOY
  bs['PRODUCT_BUNDLE_IDENTIFIER']     = BUNDLE_ID
  bs['PRODUCT_NAME']                  = '$(TARGET_NAME)'
  bs['INFOPLIST_FILE']                = 'SISCAMobile/Info.plist'
  bs['GENERATE_INFOPLIST_FILE']       = 'NO'
  bs['TARGETED_DEVICE_FAMILY']        = '1'
  bs['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  bs['CODE_SIGN_STYLE']               = 'Automatic'
  bs['CURRENT_PROJECT_VERSION']       = '1'
  bs['MARKETING_VERSION']             = '1.0'
  bs['ENABLE_PREVIEWS']               = 'YES'
  bs['SWIFT_EMIT_LOC_STRINGS']        = 'YES'
  bs['LD_RUNPATH_SEARCH_PATHS']       = ['$(inherited)', '@executable_path/Frameworks']
end

project.save
project.recreate_user_schemes

puts "OK: #{PROJECT_PATH}"
puts "Archivos Swift: #{target.source_build_phase.files.count}"
puts "Recursos: #{target.resources_build_phase.files.map { |f| f.display_name }.join(', ')}"
