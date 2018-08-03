require 'dr/formatter/simple_formatter'

module DR
	module DateRangeParser
		extend self
		#in: 2014-01-02 -> 2014-01-03, 2014-01-05, 2014-02 -> :now
		#out: [[2014-01-02,2014-01-03],[2014-01-05],[2014-02,:now]]
		def parse(date)
			return date if date.kind_of?(self)
			r=[]
			dates = date.to_s.chomp.split(/,\s*/)
			dates.each do |d|
				r << d.split(/\s*->\s*/).map {|i| i == ":now" ? :now : i }
			end
			return DateRange.new(r)
		end
	end

	module DateOutput
		extend self
		#BUG: années bissextiles...
		Months_end={1 => 31, 2 => 28, 3 => 31, 4 => 30,
			5 => 31, 6 => 30, 7 => 31, 8 => 31,
			9 => 30, 10 => 31, 11 => 30, 12 => 31}

		# Convert a Date/string into a Time
		def to_time(datetime, complete_date: :first, **opts)
			require 'time'
			return Time.now if datetime == :now
			begin
				fallback=Time.new(0) #supply the missing components
				return Time.parse(datetime,fallback)
			rescue ArgumentError
				year,month,day,time=split_date(datetime)
				case complete_date
				when :first
					month="01" if month == nil
					day="01" if day == nil
					time="00:00:00" if day == nil
				when :last
					month="12" if month == nil
					day=Months_end[month.to_i].to_s if day == nil
					time="23:59:59" if day == nil
				end
				return Time.parse("#{year}-#{month}-#{day}T#{time}",fallback)
			end
		end

		#ex: split 2014-07-28T19:26:20+0200 into year,month,day,time
		def split_date(datetime)
			datetime=Time.now.iso8601 if datetime == :now
			date,time=datetime.to_s.split("T")
			year,month,day=date.split("-")
			return year,month,day,time
		end

		Months_names={en: {
			1 => 'January', 2 => 'February', 3 => 'March',
			4 => 'April', 5 => 'May', 6 => 'June',
			7 => 'July', 8 => 'August', 9 => 'September',
			10 => 'October', 11 => 'November', 12 => 'December'},
			fr: {
			1 => 'Janvier', 2 => 'Février', 3 => 'Mars',
			4 => 'Avril', 5 => 'Mai', 6 => 'Juin',
			7 => 'Juillet', 8 => 'Août', 9 => 'Septembre',
			10 => 'Octobre', 11 => 'Novembre', 12 => 'Décembre'}}

		private def abbr_month(month, lang: :en, **_opts)
			return month if month.length <= 4
			return month[0..2]+(lang==:en ? '.' : '')
		end

		# output_date_length: granularity :year/:month/:day/:all
		# output_date: :num, :string, :abbr
		def output_date(datetime, output_date: :abbr, output_date_length: :month,
			**opts)
			lang=opts[:lang]||:en
			year,month,day,time=split_date(datetime)
			month=nil if output_date_length==:year
			day=nil if output_date_length==:month
			time=nil if output_date_length==:day
			return Formatter.localize({en: 'Present', fr: 'Présent'},**opts) if datetime==:now
			r=year
			case output_date
			when :num
				month.nil? ? (return r) : r+="-"+month
				day.nil? ? (return r) : r+="-"+day
				time.nil? ? (return r) : r+="T"+time
			when :abbr,:string
				return r if month.nil?
				month_name=Months_names[lang][month.to_i]
				month_name=abbr_month(month_name) if output_date==:abbr
				r=month_name+" "+r
				return r if day.nil?
				r=day+" "+r
				return r if time.nil?
				r+=" "+time
			end
			r
		end
	end

	class DateRange
		extend DateRangeParser
		extend DateOutput

		attr_accessor :d, :t
		def initialize(d)
			@d=d
			@t=d.map do |range|
				case range.length
				when 1
					[DateRange.to_time(range[0], complete_date: :first),
					DateRange.to_time(range[0], complete_date: :last)]
				when 2
					[DateRange.to_time(range[0], complete_date: :first),
					DateRange.to_time(range[1], complete_date: :last)]
				else
					range.map {|i| DateRange.to_time(i)}
				end
			end
		end

		#sort_date_by :first or :last
		def <=>(d2, sort_date_by: :last,**_opts)
			d1=@t; d2=d2.t
			sel=lambda do |d|
				case sort_date_by
				when :last
					return d.map {|i| i.last}
				when :first
					return d.map {|i| i.first}
				end
			end
			best=lambda do |d|
				case sort_date_by
				when :last
					return d.max
				when :first
					return d.min
				end
			end
			b1=best.call(sel.call(d1))
			b2=best.call(sel.call(d2))
			return b1 <=> b2
		end

		def to_s(join: ", ", range_join: " – ", **opts)
			r=@d.map do |range|
				range.map do |d|
					DateRange.output_date(d,**opts)
				end.join(range_join)
			end.join(join)
			r.empty? ? nil : r
		end
	end
end
