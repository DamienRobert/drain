module DR
	class SimpleKeywordsParser
		attr_accessor :opts, :keywords

		def initialize(hash, **opts)
			@opts=opts
			@keywords=hash
		end

		def keyword(name, &b)
			@keywords[name]=b
		end

		def parse(msg, **opts)
			opts=@opts.merge(opts)
			sep=opts[:sep] || ','
			# Warning: the delims must take only one char
			bdelim= opts[:bdelim] || '('
			edelim= opts[:edelim] || ')'
			keywords=@keywords.keys
			keywords_r="(?:"+keywords.map {|k| "(?:"+k+")"}.join("|")+")"
			reg = %r{(?<kw>#{keywords_r})(?<re>#{'\\'+bdelim}(?:(?>[^#{'\\'+bdelim}#{'\\'+edelim}]+)|\g<re>)*#{'\\'+edelim})}
			if (m=reg.match(msg))
				arg=m[:re][1...m[:re].length-1]
				arg=parse(arg, **opts)
				args=arg.split(sep)
				args=args.map {|a| a.strip} unless opts[:space]
				key=keywords.find {|k| /#{k}/ =~ m[:kw]}
				r=@keywords[key].call(*args).to_s
				msg=m.pre_match+r+parse(m.post_match,**opts)
				msg=keywords(msg,@keywords,**opts) if opts[:recursive]
			end
			return msg
		end
		# re = %r{
		#   (?<re>
		#     \(
		#       (?:
		#         (?> [^()]+ )
		#         |
		#         \g<re>
		#       )*
		#     \)
		#   )
		# }x
		#(?<re> name regexp/match
		#\g<re> reuse regexp
		#\k<re> reuse match
		#(?: grouping without capturing
		#(?> atomic grouping
		#x whitespace does not count
		# -> match balanced groups of parentheses

	end
end
