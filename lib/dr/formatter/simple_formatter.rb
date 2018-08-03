module DR
	module Formatter
		extend self
		def localize(msg, lang: :en, **_opts)
			case msg
			when Hash
				Array(lang).each do |l|
					return msg[l].to_s if msg.key?(l)
				end
			else
				msg.to_s
			end
		end

		def wrap(content,pre:nil,post:nil)
			return content if content.nil? or content.empty?
			pre.to_s+content.to_s+post.to_s
		end

		def expand_symbol(sym, meta: nil, expand: true, **opts)
			return sym if opts[:symbol]==:never
			content=case meta
			when Hash
				warn "#{sym} not found in #{meta}" unless meta.key?(sym)
				meta[sym]
			when Proc
				meta.call(sym, symbol: symbol, opts: opts)
			else
				sym
			end
			content=expand(content, **opts) if expand
			if block_given?
				yield content, **opts
			else
				content
			end
		end

		def get_symbol(sym)
			case sym
			when Symbol
				return sym
			when String
				return sym[1...sym.length].to_sym if sym[0] == ':'
			end
			nil
		end
		def try_expand_symbol(sym,**opts)
			if (key=get_symbol(sym))
				expand_symbol(key,**opts)
			else
				sym
			end
		end

		#if args is of size 1 and an array we join the elements of this array
		def join(*args, pre: "", post: "", pre_item: "", post_item: "", join: :auto, **opts)
			args=Array(args)
			args=args.map {|i| try_expand_symbol(i,**opts)}
			list=args.compact.map {|i| pre_item+i+post_item}.delete_if {|i| i.empty?}
			r=list.shift
			list.each do |s|
				if join==:auto
					if r[-1]=="\n" or s[1]=="\n"
						r+=s
					else
						r+=" "+s
					end
				else
					r+=join+s
				end
			end
			r=pre+r+post unless r.nil? or r.empty?
			r
		end

		def expand(msg, **opts)
			langs=Array(opts[:lang]); recursive=opts[:recursive]
			#if recursive is :first, then we only expand once ore
			opts[:recursive]=false if recursive==:first
			case msg
			when Hash
				Array(opts[:merge]).each do |key|
					if msg.key?(key)
						msg=msg.merge(msg[key])
						msg.delete(key)
					end
				end
				langs.each do |lang|
					return expand(msg[lang], **opts) if msg.key?(lang)
				end
				if recursive
					msg_exp={}
					msg.each do |k,v|
						msg_exp[k]=expand(v,**opts)
					end
					#expand may have introduced nil values
					clean_nil=opts.fetch(:clean_nil,true)
					msg_exp.delete_if {|_k,v| v==nil} if clean_nil
					msg_exp
				else
					msg
				end
			when Symbol
				opts[:symbol]||=:never
				expand_symbol(msg,**opts)
			when Array
				msg=msg.map {|i| expand(i,**opts)} if recursive
				opts[:join] ? join(msg, **opts) : msg
			when String
				(nmsg=try_expand_symbol(msg,**opts)) and return nmsg
				if block_given?
					yield(String, msg)
				else
					msg
				end
			when nil
				nil
			else
				msg
				#expand(msg.to_s,**opts)
			end
		end

	end
end
