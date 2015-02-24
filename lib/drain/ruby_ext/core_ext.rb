require 'dr/ruby_ext/core_modules'

#automatically include the CoreExt modules in their class
DR::CoreExt.constants.each do |c|
	Module.const_get(c).module_eval {include Module.const_get("DR::CoreExt::#{c}")}
end
