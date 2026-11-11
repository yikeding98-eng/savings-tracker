#!/usr/bin/env ruby
# frozen_string_literal: true
#
# 在云端构建时把「存款进度」小组件注册进 Runner.xcodeproj。
# 有了这个脚本，就不需要租 macOS / 打开 Xcode 手工建 target。
#
# 做三件事：
#   1. 新增 app_extension target（Bundle ID: com.personal.savingsTracker.SavingsWidget）
#   2. 把它的 .appex 嵌入主 App（Embed Foundation Extensions）
#   3. 给主 App 和扩展各自挂上 entitlements —— App Group 全靠这一步才生效
#
# 用法（在仓库根目录执行）：
#   WIDGET_VERSION=1.0.0 WIDGET_BUILD_NUMBER=1750000000 ruby ios/scripts/add_widget_target.rb
#
require 'xcodeproj'

IOS_DIR = File.expand_path('..', __dir__)
PROJECT_PATH = File.join(IOS_DIR, 'Runner.xcodeproj')
APP_TARGET = 'Runner'
WIDGET_TARGET = 'SavingsWidgetExtension'
WIDGET_DIR = 'SavingsWidget'
WIDGET_BUNDLE_ID = 'com.personal.savingsTracker.SavingsWidget'
DEPLOYMENT_TARGET = '15.0'

# 扩展的版本号必须和主 App 完全一致，否则 App Store Connect 会拒收（ITMS-90473）。
VERSION = ENV.fetch('WIDGET_VERSION', '1.0.0')
BUILD_NUMBER = ENV.fetch('WIDGET_BUILD_NUMBER', '1')

def abort_with(message)
  warn "[add_widget_target] 失败：#{message}"
  exit 1
end

abort_with("找不到工程 #{PROJECT_PATH}") unless File.exist?(PROJECT_PATH)
abort_with("缺少 #{WIDGET_DIR}/SavingsWidget.swift") unless
  File.exist?(File.join(IOS_DIR, WIDGET_DIR, 'SavingsWidget.swift'))
abort_with("缺少 #{WIDGET_DIR}/Info.plist") unless
  File.exist?(File.join(IOS_DIR, WIDGET_DIR, 'Info.plist'))
abort_with("缺少 #{WIDGET_DIR}/SavingsWidget.entitlements") unless
  File.exist?(File.join(IOS_DIR, WIDGET_DIR, 'SavingsWidget.entitlements'))
abort_with('缺少 Runner/Runner.entitlements') unless
  File.exist?(File.join(IOS_DIR, 'Runner', 'Runner.entitlements'))

project = Xcodeproj::Project.open(PROJECT_PATH)
app = project.targets.find { |t| t.name == APP_TARGET }
abort_with("工程里没有 #{APP_TARGET} target") if app.nil?

if project.targets.any? { |t| t.name == WIDGET_TARGET }
  puts "[add_widget_target] #{WIDGET_TARGET} 已存在，跳过创建"
else
  widget = project.new_target(:app_extension, WIDGET_TARGET, :ios, DEPLOYMENT_TARGET)

  group = project.main_group.children.find { |c| c.display_name == WIDGET_DIR }
  group ||= project.main_group.new_group(WIDGET_DIR, WIDGET_DIR)

  swift_ref = group.new_file('SavingsWidget.swift')
  group.new_file('Info.plist')
  group.new_file('SavingsWidget.entitlements')

  widget.add_file_references([swift_ref])

  widget.build_configurations.each do |config|
    settings = config.build_settings
    settings['PRODUCT_NAME'] = WIDGET_TARGET
    settings['PRODUCT_BUNDLE_IDENTIFIER'] = WIDGET_BUNDLE_ID
    settings['INFOPLIST_FILE'] = "#{WIDGET_DIR}/Info.plist"
    settings['GENERATE_INFOPLIST_FILE'] = 'NO'
    settings['CODE_SIGN_ENTITLEMENTS'] = "#{WIDGET_DIR}/SavingsWidget.entitlements"
    settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
    settings['SWIFT_VERSION'] = '5.0'
    settings['TARGETED_DEVICE_FAMILY'] = '1,2'
    settings['SKIP_INSTALL'] = 'YES'
    settings['CLANG_ENABLE_MODULES'] = 'YES'
    settings['SWIFT_OPTIMIZATION_LEVEL'] = '-O' if config.name == 'Release'
    settings['LD_RUNPATH_SEARCH_PATHS'] =
      '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
    settings['MARKETING_VERSION'] = VERSION
    settings['CURRENT_PROJECT_VERSION'] = BUILD_NUMBER
  end

  # 把 .appex 嵌进主 App，否则安装后手机上根本不会出现小组件
  embed = app.copy_files_build_phases.find { |p| p.name == 'Embed Foundation Extensions' }
  if embed.nil?
    embed = app.new_copy_files_build_phase('Embed Foundation Extensions')
  end
  embed.symbol_dst_subfolder_spec = :plug_ins

  build_file = embed.add_file_reference(widget.product_reference)
  begin
    build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  rescue StandardError
    # 老版本 xcodeproj 不支持该属性，不影响功能
  end

  app.add_dependency(widget)
  puts "[add_widget_target] 已新增 #{WIDGET_TARGET} target（#{WIDGET_BUNDLE_ID}）"
end

# 主 App 也要挂 entitlements，否则 App 写不进 App Group
entitlements = 'Runner/Runner.entitlements'
app.build_configurations.each do |config|
  next if config.build_settings['CODE_SIGN_ENTITLEMENTS'] == entitlements

  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = entitlements
end

project.save

# 保存后重新读一遍做校验，确认写进去了
check = Xcodeproj::Project.open(PROJECT_PATH)
widget = check.targets.find { |t| t.name == WIDGET_TARGET }
abort_with('保存后仍找不到小组件 target') if widget.nil?

release = widget.build_configurations.find { |c| c.name == 'Release' }
abort_with('小组件 target 缺少 Release 配置') if release.nil?

abort_with('Build number 没写进 Release 配置') unless
  release.build_settings['CURRENT_PROJECT_VERSION'] == BUILD_NUMBER

puts "[add_widget_target] 校验通过：appex 将嵌入主 App，版本 #{VERSION} (#{BUILD_NUMBER})"
