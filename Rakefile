def need(command, howto)
  `which -s #{command}`
  if $?.to_i > 0
    puts "You need #{command}. Try: #{howto}"
    exit 1
  end
end

desc "Starts a preview server."
task :start do
  need "proton", "gem install proton"
  system "proton start"
end

desc "Builds."
task :build do
  need "coffee", "npm install -g coffee-script"
  need "uglifyjs", "npm install -g uglifyjs"
  system "coffee -p stencil.coffee > stencil.js"
  system "uglifyjs stencil.js > stencil.min.js"
end
