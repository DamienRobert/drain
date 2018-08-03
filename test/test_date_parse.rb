require 'helper'
require 'dr/parse/date_parse'

describe DR::DateRange do
	before do
		@daterange=DR::DateRange.parse("2014-01-02 -> 2014-01-03, 2014-01-05, 2014-02 -> :now")
	end

	it "Can parse dates" do
		@daterange.d.must_equal [["2014-01-02", "2014-01-03"], ["2014-01-05"], ["2014-02", :now]]
	end

	it "Can output a date range" do
		@daterange.to_s.must_equal "Jan. 2014 – Jan. 2014, Jan. 2014, Feb. 2014 – Present"
	end

	it "Can output a date range with full time information" do
		@daterange.to_s(output_date_length: :all).must_equal "02 Jan. 2014 – 03 Jan. 2014, 05 Jan. 2014, Feb. 2014 – Present"
	end

	it "Has time information" do
		@daterange.t[0].to_s.must_equal "[2014-01-02 00:00:00 +0100, 2014-01-03 00:00:00 +0100]".encode('US-ASCII')
	end
end
