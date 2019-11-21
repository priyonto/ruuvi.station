platform :ios, '10.0'
use_frameworks!
inhibit_all_warnings!

install! 'cocoapods', :disable_input_output_paths => true

def shared_pods
  pod 'BTKit'
  pod 'Charts'
  pod 'EmptyDataSet-Swift'
  pod 'Firebase/Messaging'
  pod 'Firebase/Analytics'
  pod 'FutureX'
  pod 'GestureInstructions'
  pod 'Humidity'
  pod 'LightRoute', :git => 'https://github.com/rinat-enikeev/LightRoute.git'
  pod 'Localize-Swift'
  pod 'RangeSeekSlider'
  pod 'Swinject'
  pod 'SwinjectPropertyLoader', :git => 'https://github.com/rinat-enikeev/SwinjectPropertyLoader'
  pod 'TTTAttributedLabel'
end

target 'station' do
  shared_pods
  pod 'RealmSwift'
end

target 'station_dev' do
  shared_pods
  pod 'RealmSwift'
end

target 'station_sui' do
#  shared_pods
end
