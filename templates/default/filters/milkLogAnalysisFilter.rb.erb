# Call this file 'foo.rb' (in logstash/filters, as above)
require "logstash/filters/base"
require "logstash/namespace"
require "milkLogAnalyser.rb"

class LogStash::Filters::MilkLogAnalysisFilter < LogStash::Filters::Base

	# Setting the config_name here is required. This is how you
	# configure this filter from your logstash config.
	#
	# filter {
	#   foo { ... }
	# }
	config_name "milkLogAnalysisFilter"

	# New plugins should start life at milestone 1.
	milestone 1

	# Replace the message with this value.
	config :message, :validate => :string

	public
	def register
		# nothing to do
	end # def register

	public
	def filter(event)
		# return nothing unless there's an actual filter event
		return unless filter?(event)
#		if @message
			# Replace the event message with our message as configured in the
			# config file.
#			event["message"] = @message

			MilkLogAnalyzer.new(event) # all logics are in class initalizer


#		end
		# filter_matched should go in the last line of our successful code 
		filter_matched(event)
	end # def filter
end # class LogStash::Filters::Foo
