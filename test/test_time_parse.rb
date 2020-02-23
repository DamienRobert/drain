require 'helper'
require 'dr/parse/time_parse'

describe DR::TimeParse do
	before do
		@tz=ENV['TZ']
		ENV['TZ']='GMT'
		class << Time
			alias _original_now now
			def now
				Time.new(2000)
			end
		end
	end
	after do
		ENV['TZ']=@tz
		class << Time
			alias now _original_now
		end
	end

	it "Can parse a range" do
		_(DR::TimeParse.parse("+100..tomorrow")).must_equal(
			Time.parse("2000-01-01 00:01:40")..Time.parse("2000-01-02 12:00:00")
		)
		_(DR::TimeParse.parse("now..in seven days")).must_equal(
			Time.parse("2000-01-01 00:00:00")..Time.parse("2000-01-08 00:00:00")
		)
	end

	it "Can parse a date" do
		_(DR::TimeParse.parse("today")).must_equal(Time.parse("2000-01-01-12:00:00"))
	end

	it "Can put a date in a range" do
		_(DR::TimeParse.parse("today", range: true)).must_equal(
			Time.parse("2000-01-01-00:00:00")..Time.parse("2000-01-02-00:00:00")
		)
	end
end

#with active_support: DR::TimeParse.parse("-3 years 2 minutes")
#=> 2011-08-22 20:01:34 +0200
