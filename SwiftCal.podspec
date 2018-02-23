Pod::Spec.new do |spec|
  spec.platform = :ios
  spec.name         = 'SwiftCal'
  spec.version      = '1.0.0'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://github.com/superhuman/SwiftCal'
  spec.authors      = 'Sanket Firodiya'
  spec.summary      = 'A set of classes used to parse and handle iCalendar (.ICS) files'
  spec.source       = { :git => 'https://github.com/superhuman/SwiftCal.git', :tag => '1.0.0' }
  spec.source_files = 'CalendarKit-Swift/SwiftCal/*.swift'
  spec.frameworks = 'UIKit', 'Foundation'
  spec.requires_arc = true
end