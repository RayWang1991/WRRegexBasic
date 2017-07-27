# platform : Mac, '8.0'

source 'https://github.com/RayWang1991/WRParsingBasic'

def wrRegexBasics_pods
  pod 'WRParsingBasic', :path => ‘../../Parser/WRParsingComponent/WRParsingBasic'
end

target 'WRRegexBasics' do
  wrRegexBasics_pods
end

post_install do |installer|
        `find Pods -regex 'Pods/pop.*\\.h' -print0 | xargs -0 sed -i '' 's/\\(<\\)pop\\/\\(.*\\)\\(>\\)/\\"\\2\\"/'`
end
