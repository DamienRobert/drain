module DR
	#utilities to parse some strings into name values
	module SimpleParser
		extend self

		#takes a string 'name:value' and return name and value
		#can specify a default value; if the default is true we match
		#no-name as name:false
		def parse_namevalue(nameval, sep: ':', default: nil)
			name,*val=nameval.split(sep)
			if val.empty?
				if default == true
					#special case where if name begins by no- we return false
					if name =~ /^no-(.*)$/
						return $1, false
					else
						return name, true
					end
				else
					return name, default
				end
			else
				value=val.join(sep)
				return name,value
			end
		end

		#takes a string as "name:value!option1=ploum!option2=plam,name2:value2!!globalopt=plim,globalopt2=plam"
		#and return the hash
		#{values: {name: value, name2: value2},
		# localopt: {name: {option1:ploum,option2:plam}},
		# globalopt: {globalopt: plim, globalopt2: plam},
		# opt: {name: {option1:ploum,option2:plam,globalopt: plim, globalopt2: plam}, name2:{{globalopt: plim, globalopt2: plam}}}
		def parse_string(s)
			r={values: {}, local_opts: {}, global_opts: {}, opts: {}}
			args,*globopts=s.split('!!')
			globopts.map {|g| g.split(',')}.flatten.each do |g|
				name,value=parse_namevalue(g, sep: '=', default: true)
				r[:global_opts][name]=value
			end
			args.split(',').each do |arg|
				arg,*localopts=arg.split('!')
				name,value=parse_namevalue(arg)
				r[:values][name]=value
				r[:local_opts][name]={}
				localopts.each do |o|
					oname,ovalue=parse_namevalue(o, sep: '=', default: true)
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
