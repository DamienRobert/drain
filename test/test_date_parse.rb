require 'helper'
require 'dr/parse/date_parse'

describe DR::DateRange do
	before do
		@tz=ENV['TZ']
		ENV['TZ']='GMT'
		@daterange=DR::DateRange.parse("2014-01-02 -> 2014-01-03, 2014-01-05, 2014-02 -> :now")
	end
	after do
		ENV['TZ']=@tz
	end

	it "Can parse dates" do
		_(@daterange.d).must_equal [["2014-01-02", "2014-01-03"], ["2014-01-05"], ["2014-02", :now]]
	end

	it "Can output a date range" do
		_(@daterange.to_s).must_equal "Jan. 2014 – Jan. 2014, Jan. 2014, Feb. 2014 – Present"
	end

	it "Can output a date range with full time information" do
		_(@daterange.to_s(output_date_length: :all)).must_equal "02 Jan. 2014 – 03 Jan. 2014, 05 Jan. 2014, Feb. 2014 – Present"
	end

	it "Has time information" do
		_(@daterange.t[0].to_s).must_equal "[2014-01-02 00:00:00 +0000, 2014-01-03 00:00:00 +0000]".encode('US-ASCII')
	end
end
