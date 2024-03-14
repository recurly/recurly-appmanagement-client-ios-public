Pod::Spec.new do |spec|
  spec.name               = 'RecurlyAppManagementSDK'
  spec.version            = '1.0.0'
  spec.deprecated         = true 
  spec.summary            = 'A library to enable AppManagement in Recurly merchant iOS apps'
  spec.homepage           = 'https://github.com/recurly/recurly-client-ios-appmanagement'
  spec.license            = { :type => 'Commercial', :text => <<-LICENSE
Copyright (c) 2023 Recurly, Inc.
All rights reserved.
                              LICENSE
                           }
  spec.author             = { 'Recurly, Inc.' => 'support@recurly.com' }
  spec.source             = { :git => 'https://github.com/recurly/recurly-client-ios-appmanagement.git', :tag => "v#{spec.version}" }
  spec.swift_version      = '5.7'
  spec.vendored_frameworks     = 'RecurlyAppManagementSDK.xcframework'
  spec.ios.deployment_target  = '15.0'
end

