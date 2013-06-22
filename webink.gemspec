Gem::Specification.new do |s|
  s.name = "webink"
  s.version = '2.1.1'
  s.summary = "A minimal web framework."
  s.author = "Matthias Geier"
  s.homepage = "https://github.com/matthias-geier/WebInk"
  s.require_path = 'lib'
  s.files = Dir['lib/*.rb'] + Dir['lib/webink/*.rb'] + Dir['bin/*'] +
    [ "LICENSE.md" ]
  s.executables = ["webink_database", "rfcgi"]
  s.required_ruby_version = '>= 1.9.3'
  s.add_dependency('fcgi', '>= 0.8.8')
  s.add_dependency('simple-mmap', '>= 1.1.4')
end
