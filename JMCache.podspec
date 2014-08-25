Pod::Spec.new do |s|
        s.name         = 'JMCache'
        s.version = '0.1'
        s.requires_arc = true
        s.author = {
                'Morissard Jérome' => 'morissardj@gmail.com'
        }
        s.ios.deployment_target = '6.0'
        s.summary = 'JMCache is a key/value store designed for persisting temporary objects. NSCoding is not mandatory and you can increase security wit a ValueTransformer '
        s.license      = { :type => 'MIT' }
        s.homepage = 'https://github.com/leverdeterre/JMCache'
        s.source = {
        :git => 'https://github.com/leverdeterre/JMCache.git',
        :tag => "0.2.2"
        }
        s.source_files = 'JMCache/JMCache/JMCache/*'
end
