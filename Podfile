# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'taya' do
  use_frameworks!
 
 pod 'WebViewJavascriptBridge', :git => 'https://github.com/stury/WebViewJavascriptBridge.git', :branch => ‘master’
  pod 'Adjust', '~> 4.31.0'
  pod 'Firebase/Messaging', '~> 10.24.0'
  pod 'KeychainSwift', '~> 24.0.0'
  pod 'Alamofire', '~> 5.9.1'
  pod 'HandyJSON', '~> 5.0.2'
  pod 'Firebase/RemoteConfig'
  
end

# Unified post_install handling
post_install do |installer|
  # HandyJSON optimization settings - fix compilation issues
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      # Disable code signing for Pods to avoid conflicts with manual signing
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
    end
    if target.name == 'HandyJSON'
      target.build_configurations.each do |config|
        # Apple Clang - Code Generation: Optimization Level set to None [-O0]
        config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
        # Swift Compiler - Code Generation: Optimization Level set to No Optimization [-Onone]
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
      end
    end
  end
end

