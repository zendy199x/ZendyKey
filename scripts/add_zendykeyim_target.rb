#!/usr/bin/env ruby
# add_zendykeyim_target.rb
# Adds ZendyKeyIM target to ZendyKey.xcodeproj

require 'xcodeproj'

# Open project
project_path = 'ZendyKey.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Check if target already exists
if project.targets.any? { |t| t.name == 'ZendyKeyIM' }
  puts "✅ ZendyKeyIM target already exists!"
  exit 0
end

puts "Creating ZendyKeyIM target..."

# Create new macOS Application target
target = project.new_target(:application, 'ZendyKeyIM', :osx, '12.0', nil, :swift)
target.build_configurations.each do |config|
  settings = config.build_settings
  
  # Basic settings
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.zendy199x.inputmethod.ZendyKey'
  settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  settings['INFOPLIST_FILE'] = 'ZendyKeyIM/Info.plist'
  settings['SWIFT_VERSION'] = '5.0'
  settings['MACOSX_DEPLOYMENT_TARGET'] = '12.0'
  settings['COMBINE_HIDPI_IMAGES'] = 'YES'
  
  # Code signing (ad-hoc for now)
  settings['CODE_SIGN_STYLE'] = 'Automatic'
  settings['CODE_SIGN_IDENTITY'] = '-'
  
  # Entitlements
  if config.name == 'Release'
    settings['CODE_SIGN_ENTITLEMENTS'] = 'ZendyKeyIM/ZendyKeyIMRelease.entitlements'
  else
    settings['CODE_SIGN_ENTITLEMENTS'] = 'ZendyKeyIM/ZendyKeyIM.entitlements'
  end
  
  # Disable sandbox for Input Method
  settings['ENABLE_APP_SANDBOX'] = 'NO'
  settings['ENABLE_HARDENED_RUNTIME'] = 'YES'
end

# Create group for ZendyKeyIM
zkim_group = project.main_group.find_subpath('ZendyKeyIM', true)
zkim_group.set_source_tree('SOURCE_ROOT')

# Add source files to target
zkim_files = [
  'ZendyKeyIM/main.swift',
  'ZendyKeyIM/ZKIMController.swift',
  'ZendyKeyIM/IMKitDebugger.swift',
  'ZendyKeyIM/ZKIMKitDebugger.swift',
]

zkim_files.each do |file_path|
  if File.exist?(file_path)
    file_ref = zkim_group.new_file(file_path)
    target.source_build_phase.add_file_reference(file_ref)
    puts "  Added: #{file_path}"
  else
    puts "  ⚠️ Not found: #{file_path}"
  end
end

# Add shared engine files (from ZendyKey target)
shared_files = [
  'ZendyKey/Core/Engine/ZKEngine.swift',
  'ZendyKey/Core/Engine/ZKVietnameseData.swift',
  'ZendyKey/Core/Engine/ZKDictionaryManager.swift', 
  'ZendyKey/Core/Engine/ZKEngineSpellCheck.swift',
  'ZendyKey/Core/Models/InputMethod.swift',
  'ZendyKey/Core/Models/CodeTable.swift',
  'ZendyKey/Core/Models/ZKCharacter.swift',
  'ZendyKey/Utilities/ZKSharedSettings.swift',
  'Shared/AppBehaviorDetector.swift',
]

# Find references to shared files and add to ZendyKeyIM target
zendykey_group = project.main_group.find_subpath('ZendyKey', false)
if zendykey_group
  shared_files.each do |file_path|
    # Find existing file reference
    file_ref = project.files.find { |f| f.path && f.real_path.to_s.include?(File.basename(file_path)) }
    if file_ref
      target.source_build_phase.add_file_reference(file_ref)
      puts "  Added shared: #{file_path}"
    else
      puts "  ⚠️ Not found in project: #{file_path}"
    end
  end
end

# Add InputMethodKit framework
inputmethodkit_ref = project.frameworks_group.new_file('System/Library/Frameworks/InputMethodKit.framework', :sdk_root)
target.frameworks_build_phase.add_file_reference(inputmethodkit_ref)
puts "  Added: InputMethodKit.framework"

# Add Cocoa framework
cocoa_ref = project.frameworks_group.new_file('System/Library/Frameworks/Cocoa.framework', :sdk_root)
target.frameworks_build_phase.add_file_reference(cocoa_ref)
puts "  Added: Cocoa.framework"

# Add Carbon framework (for TIS functions)
carbon_ref = project.frameworks_group.new_file('System/Library/Frameworks/Carbon.framework', :sdk_root)
target.frameworks_build_phase.add_file_reference(carbon_ref)
puts "  Added: Carbon.framework"

# Add Resources
resources_files = [
  'ZendyKeyIM/AppIcon.icns',
  'ZendyKeyIM/MenuIcon.pdf',
]

resources_files.each do |file_path|
  if File.exist?(file_path)
    file_ref = zkim_group.new_file(file_path)
    target.resources_build_phase.add_file_reference(file_ref)
    puts "  Added resource: #{file_path}"
  end
end

# Create scheme for ZendyKeyIM
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.save_as(project_path, 'ZendyKeyIM')
puts "  Created scheme: ZendyKeyIM"

# Save project
project.save
puts "✅ ZendyKeyIM target added successfully!"
puts ""
puts "Next steps:"
puts "1. Open ZendyKey.xcodeproj in Xcode"
puts "2. Select ZendyKeyIM scheme"
puts "3. Build (Cmd+B)"
puts "4. Copy ZendyKeyIM.app to ~/Library/Input Methods/"
