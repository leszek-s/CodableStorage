Pod::Spec.new do |s|
  s.name          = "CodableStorage"
  s.version       = "1.1.0"
  s.summary       = "Easy to use key-value storage for objects conforming to the Codable protocol, backed by Core Data."
  s.homepage      = "https://github.com/leszek-s/CodableStorage"
  s.license       = "MIT"
  s.author        = "Leszek S"
  s.source        = { :git => "https://github.com/leszek-s/CodableStorage.git", :tag =>  "1.1.0" }
  s.ios.deployment_target = "12.0"
  s.osx.deployment_target = "10.15"
  s.source_files  = "CodableStorage"
  s.swift_version = "5.0"
end
