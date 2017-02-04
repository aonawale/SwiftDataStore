Pod::Spec.new do |spec|
spec.name = 'SwiftDataStore'
spec.version = '0.0.1'
spec.summary = 'Swift Data Store'
spec.homepage = 'https://github.com/aonawale/SwiftDataStore'
spec.license = { :type => 'BSD', :file => 'LICENSE' }
spec.authors = { 'Ahmed Onawale' => 'ahmedonawale@gmail.com' }
spec.social_media_url = 'http://twitter.com/ahmedonawale'
spec.ios.deployment_target = '8.0'
spec.requires_arc = true
spec.source = { :git 'https://github.com/aonawale/SwiftData.git', :tag => spec.version, submodules: true }
spec.source_files = 'Sources/SwiftDataStore/*.{h,swift}'
spec.dependency 'Pluralize.swift'
spec.description = <<-DESC
A Swift Data store for managing data models.
DESC
end
