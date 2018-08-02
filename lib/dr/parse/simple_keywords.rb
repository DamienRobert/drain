module DR
	module SimpleKeywordsParser
		extend self

		#shortcut when we only have one keyword
		def keyword(msg, kw, **opts, &b)
			h={kw => b}
			return keywords(msg,h,**opts)
		end

		def keywords(msg, hash, **opts)
			sep=opts[:sep] || /,\s*/
			keywords=hash.keys
			keywords_r="(?:"+keywords.map {|k| "(?:"+k+")"}.join("|")+")"
			reg = %r{(?<kw>#{keywords_r})(?<re>\((?:(?>[^()]+)|\g<re>)*\))}
			if (m=reg.match(msg))
				arg=m[:re][1...m[:re].length-1]
				arg=keywords(arg,hash,**opts)
				args=arg.split(sep)
				key=keywords.find {|k| /#{k}/ =~ m[:kw]}
				r=hash[key].call(*args).to_s
				msg=m.pre_match+r+keywords(m.post_match,hash,**opts)
				msg=keywords(msg,hash,**opts) if opts[:recursive]
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
