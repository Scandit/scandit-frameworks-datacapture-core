Pod::Spec.new do |s|
    s.name                    = 'scandit-datacapture-frameworks-core'
    s.version                 = '6.19.0-beta.1'
    s.summary                 = 'Scandit Frameworks Shared Core module'
    s.homepage                = 'https://github.com/Scandit/scandit-datacapture-frameworks-core'
    s.license                 = 'Apache-2.0'
    s.author                  = { 'Scandit' => 'support@scandit.com' }
    s.platforms               = { :ios => '13.0' }
    s.source                  = { :git => 'git@github.com:Scandit/scandit-datacapture-frameworks-core.git', :tag => '6.19.0-beta.1' }
    s.swift_version           = '5.7'
    s.source_files            = 'Sources/**/*.{h,m,swift}'
    s.requires_arc            = true
    s.module_name             = 'ScanditFrameworksCore'
    s.header_dir              = 'ScanditFrameworksCore'

    s.dependency 'ScanditCaptureCore', '= 6.19.0-beta.1'
end
