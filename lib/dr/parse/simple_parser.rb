module DR
	#utilities to parse some strings into name values
	module SimpleParser
		extend self

		#takes a string 'name:value' and return name and value
		#can specify a default value; if the default is true we match
		#no-name as name:false
		def parse_namevalue(nameval, sep: ':', default: nil, symbolize: true)
			name,*val=nameval.split(sep)
			if val.empty?
				value=default
				if default == true
					#special case where if name begins by no- we return false
					name.to_s.match(/^no-(.*)$/) do |m| 
						name=m[1]
						value=false
					end
				end
			else
				value=val.join(sep)
			end
			name=name.to_sym if symbolize
			return name,value
		end

		# parse opt1=value1:opt2=value2...
		def parse_options(options, arg_split:':', valuesep: '=', opt_default: true, keyed_sep: "/")
			return {} unless options
			parsed_options={}
			options=options.split(arg_split) unless options.is_a?(Enumerable)
			options.each do |optvalue|
				opt,value=DR::SimpleParser.parse_namevalue(optvalue,sep: valuesep, default: opt_default)
				parsed_options.set_keyed_value(opt,value, sep: keyed_sep)
			end
			return parsed_options
		end

		# parse name:opt1=value1:opt2=value2...
		def parse_name_options(name, arg_split:':', **keywords)
			name,*options=name.split(arg_split)
			return name, parse_options(options, arg_split: arg_split, **keywords)
		end

		#takes a string as "name:value!option1=ploum!option2=plam,name2:value2!!globalopt=plim,globalopt2=plam!!globalopt3=plom,globalopt4=plim"
		#and return the hash
		#{values: {name: value, name2: value2},
		# local_opts: {name: {option1:ploum,option2:plam}},
		# global_opts: {globalopt: plim, globalopt2: plam},
		# opts: {name: {option1:ploum,option2:plam,globalopt: plim, globalopt2: plam}, name2:{{globalopt: plim, globalopt2: plam}}}
		#
		#Algo: split on 'args!!globopts'
		#  globopts are split on ',' or '!!'
		#  args are split on ',' into parameters
		#  parameters are split on 'args!local_opts'
		#  args are split on 'name:value' using parse_namevalue
		#  local_opts are splits on 'opt=value" using parse_namevalue
		def parse_string(s, arg_split:',', valuesep: ':', default: nil,
				opt_valuesep: '=', opt_default: true, opts_split: '!',
				globalopts_separator: '!!', globopts_split: arg_split, 
				globalopts_valuesep: opt_valuesep, globalopts_default: opt_default)
			r={values: {}, local_opts: {}, global_opts: {}, opts: {}}
			args,*globopts=s.split(globalopts_separator)
			globopts.map {|g| g.split(globopts_split)}.flatten.each do |g|
				name,value=parse_namevalue(g, sep: globalopts_valuesep, default: globalopts_default)
				r[:global_opts][name]=value
			end
			args.split(arg_split).each do |arg|
				arg,*localopts=arg.split(opts_split)
				name,value=parse_namevalue(arg, sep: valuesep, default: default)
				r[:values][name]=value
				r[:local_opts][name]={}
				localopts.each do |o|
					oname,ovalue=parse_namevalue(o, sep: opt_valuesep, default: opt_default)
					r[:local_opts][name][oname]=ovalue
				end
				r[:local_opts].each do |name,hash|
					r[:opts][name]=r[:local_opts][name].dup
					r[:global_opts].each do |k,v|
						r[:opts][name][k]||=v
					end
				end
			end
			return r
		end

	end
end
