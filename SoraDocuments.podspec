#
# Be sure to run `pod lib lint SoraDocuments.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SoraDocuments'
  s.version          = '0.1.3'
  s.summary          = 'Library to perform operations on structured documents and store on disk.'

  s.homepage         = 'https://github.com/soramitsu'
  s.license          = { :type => 'GPL 3.0', :file => 'LICENSE' }
  s.author           = { 'Russel' => 'emkil.russel@gmail.com' }
  s.source           = { :git => 'https://github.com/soramitsu/documents-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'SoraDocuments/Classes/**/*.swift'

  s.swift_version = '4.2'

  s.test_spec do |ts|
      ts.source_files = 'Tests/**/*.swift'
  end

end
