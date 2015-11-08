Pod::Spec.new do |s|

  s.name         = "NotificationController"
  s.version      = "0.0.1"
  s.summary      = "A Neat Swift Notification Operations Wrapper"

  s.description  = <<-DESC
  With NotificationController, it's super easy to handle notifications with neat API. What's more, remove obersers is also properly handled.
                   DESC

  s.homepage     = "https://github.com/kukushi/NotificationController"
  s.license      = "MIT"
  s.author             = { "Xing He" => "" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/kukushi/NotificationController.git", :tag => s.version }
  s.source_files  = "Classes", "Classes/**/*.{h,m}", "NotificationController/*.{h,m,swift}"
  s.exclude_files = "Classes/Exclude"
  s.requires_arc = true

end