
require 'rubygems'
Gem.manage_gems
gem = Gem.cache.search('actionwebservice').sort_by { |g| g.version }.last
if gem.autorequire
  require gem.autorequire
else
  require_options = ["actionwebservice"]
  unless require_options.find do |path|
      begin
        require path 
      rescue MissingSourceFile 
        nil
      end
    end
    puts msg = "ERROR: Please update #{File.expand_path __FILE__} with the require path for linked RubyGem actionwebservice"
    exit
  end
end

