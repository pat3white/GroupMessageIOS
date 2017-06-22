platform :ios, "10.0"
use_frameworks!

target 'ChatChat' do
    
pod 'Firebase/Storage'
pod 'Firebase/Auth'
pod 'Firebase/Database'
pod 'Firebase/Messaging'
pod 'JSQMessagesViewController'
pod 'ChameleonFramework/Swift'

end

post_install do |installer|
    
    installer.pods_project.targets.each do |target|
        
        target.build_configurations.each do |config|
            
            config.build_settings['SWIFT_VERSION'] = '3.0'
            
        end
        
    end
    
end
