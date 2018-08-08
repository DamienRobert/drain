module DR
	class Formatter
		module Helpers
			def localize(msg, lang: :en, **_opts)
				case msg
				when Hash
					Array(lang).each do |l|
						if msg.key?(l)
							yield(msg[l]) if block_given?
							return msg[l]
						end
					end
				else
					msg
				end
			end

			def wrap(content, pre:nil, post:nil)
				return content if content.nil? or content.empty?
				pre.to_s+content.to_s+post.to_s
			end

			def join(*args, pre: "", post: "", pre_item: "", post_item: "", join: :auto, **_opts)
				args=Array(args)
				list=args.compact.map {|i| wrap(i, pre: pre_item, post: post_item)}.delete_if {|i| i.empty?}
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
		end
		extend Helpers

		attr_accessor :opts, :meta
		def initialize(meta={}, **opts)
			@meta=meta
			@opts=opts
		end

		def localize(msg, **opts)
			self.class.localize(msg, **@opts.merge(opts))
		end

		def join(*args, **opts)
			opts=@opts.merge(opts)
			args=Array(args).map {|i| try_expand_symbol(i,**opts)}
			self.class.localize(*args, **opts)
		end

		private def metainfo_from_symbol(sym, meta: @meta, **opts)
			return sym if opts[:meta_symbol]==:never
			content=case meta
			when Hash
				warn "#{sym} not found in #{meta}" unless meta.key?(sym)
				meta[sym]
			when Proc
				meta.call(sym, **opts)
			else
				sym
			end
			if block_given?
				yield content, **opts
			else
				content
			end
		end

		private def get_symbol(sym)
			case sym
			when Symbol
				return sym
			when String
				return sym[1...sym.length].to_sym if sym[0] == ':'
			end
			nil
		end
		private def try_get_symbol(sym,**opts)
			if (key=get_symbol(sym))
				expand_symbol(key,**opts)
			else
				sym
			end
		end

		def expand(msg, **opts)
			recursive=opts[:recursive]
			#if recursive is :first, then we only expand once ore
			if recursive.is_a?(Integer)
				opts[:recursive]=recursive-1
				recursive=false if recursive <= 0
			end
			case msg
			when Hash
				Array(opts[:merge]).each do |key|
					if msg.key?(key)
						msg=msg.merge(msg[key])
						msg.delete(key)
					end
				end
				# we localize after merging potential out types
				localize(msg, **opts) do |lmsg|
					# localization do not count as a recursive step
					return expand(lmsg, **opts)
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
				msg=metainfo_from_symbol(msg,**opts)
				recursive ? expand(msg, **opts) : msg
			when Array
				msg=msg.map {|i| expand(i,**opts)} if recursive
				opts[:join] ? join(msg, **opts) : msg
			when String
				(nmsg=try_get_symbol(msg,**opts)) and return nmsg
				if block_given?
					yield(msg, **opts)
				else
					msg
				end
			when nil
				nil
			else
				if block_given?
					yield(msg, **opts)
				else
					#expand(msg.to_s,**opts)
					msg
				end
			end
		end

	end
end
