#
# Be sure to run `pod lib lint ringtoneMaker.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'RingtoneMaker'
    s.version          = '0.1.0'
    s.summary          = 'test'
    
    # This description is used to generate tags and improve search results.
    #   * Think: What does it do? Why did you write it? What is the focus?
    #   * Try to keep it short, snappy and to the point.
    #   * Write the description between the DESC delimiters below.
    #   * Finally, don't worry about the indent, CocoaPods strips it!
    
    s.homepage         = 'https://github.com/alperengezgin/RingtoneMakers'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Alperen Polat GEZGIN' => 'alperengezgin@gmail.com' }
    s.source           = { :git => 'https://github.com/alperengezgin/RingtoneMakers.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    
    s.ios.deployment_target = '13.0'
    
    s.source_files = 'ringtoneMaker/Classes/**/*'
    
    s.resource_bundles = {
        'ringtoneMaker' => ['ringtoneMaker/Assets/*.{png,json,xcassets,xib,band}']
    }
    
    s.frameworks = 'UIKit', 'MediaPlayer', 'Photos', 'AVKit', 'MobileCoreServices', 'AVFoundation'
    
  
end
