#for the filename ploum.rb, load all ploum/*.rb files
dir=File.expand_path(File.basename(__FILE__).chomp('.rb'), File.dirname(__FILE__))
Dir.glob(File.expand_path('*.rb',dir)) do |file|
	require file
end
