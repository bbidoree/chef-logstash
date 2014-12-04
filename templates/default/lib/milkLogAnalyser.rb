# coding: utf-8

=begin
if $noFilter != true
require "logstash/filters/base"
require "logstash/namespace"
end
=end
#require 'pry'

class MilkLogAnalyzer
=begin
if $noFilter == true
	# dummy - no filter.
	class MilkLogAnalyzer::LogStash
		class MilkLogAnalyzer::LogStash::Event
		end
	end
end
=end

	#dangerVal def
	@@NOT_ERROR = -1
	@@NO_DANGER = 0
	@@DANGER_MONITORING = 10
	@@DANGER_WILL_FIX = 20
	@@DANGER = 30
	@@NEED_CHECK = 100
	@@UPDATE_LATER = 90

	@@NEED_DELETE = -11

	attr_accessor :analysisVer
	attr_accessor :analysisMsg
	attr_accessor :analysisMsgSub
	attr_accessor :dangerVal

	public
	def initialize(inObject)

		@logObject = inObject

		@analysisVer = 1
		@analysisMsg = "n"
		@analysisMsgSub = "n"
		@dangerVal = @@NEED_CHECK

		analyze()
	end

	private
	def analyze

		# get data
		type = @logObject["type"]
		logType = @logObject["logType"]
		category = @logObject["category"]

		#binding.pry

		# msg analysis
		if type == "serverLog"
			if logType == "RES"
				analyseServerResLog		

			elsif category == "_ERROR_LOGGER"
				analyseErrorLoggerLog

			else
				analyseEtcLog
				
			end

		elsif type == "sgmpLog"
			analyseSgmpLog	
	
		end

		# store result
		@logObject["analysisVer"] = @analysisVer
		@logObject["analysisMsg"] = @analysisMsg
		@logObject["analysisMsgSub"] = @analysisMsgSub
		@logObject["dangerVal"] = @dangerVal

	end

	###############################
	# trace res log.              #
	###############################
	private 
	def analyseServerResLog

		# get data
		resultCode = @logObject["resultCode"]
		extMsg = @logObject["extMsg"]
		remained = @logObject["remained"]


		# resultcode
		if resultCode == "0"
			@dangerVal = @@NOT_ERROR
			@analysisMsg = "success"

		elsif resultCode == "1001"
			@dangerVal = @@NO_DANGER
			@analysisMsg = "1001 - access token check fail"

		elsif resultCode == "1002"
			@dangerVal = @@NO_DANGER
			@analysisMsg = "1002 - access token time fail"

		elsif resultCode == "1102"

			if extMsg.include? "is mandatory field." or
				extMsg.include? "is not number field." or
				extMsg.include? "length is too long." or
				extMsg.include? "adjustment : trackPlays is null" or
				extMsg.include? "parameter value pattern is invalid." or
				extMsg.include? ".RadioController.history" then
				@dangerVal = @@NO_DANGER
				@analysisMsg = "1102 - invalid param"
				@analysisMsgSub = "mandatory field not include"

			elsif extMsg.include? "cannot find device user id from unique id"
				@dangerVal = @@NO_DANGER
				@analysisMsg = "1102 - invalid param"
				@analysisMsgSub = "not found unique id in myStationSync api"

			elsif extMsg.include? "updatePersonalStation(Unknown Source)"
				@dangerVal = @@NO_DANGER
				@analysisMsg = "1102 - invalid param"
				@analysisMsgSub = "not include detail msg - updatePersonalStation"

			elsif extMsg.include? "ErrMsg : data integrity violation exception"
				if extMsg.include? "Duplicate entry" 
					@dangerVal = @@DANGER
					@analysisMsg = "1102 - Duplicate entry"
					@analysisMsgSub = @logObject["apiPath"]
				elsif extMsg.include? "a foreign key constraint fails" 
					@dangerVal = @@DANGER
					@analysisMsg = "1102 - foreign key fails"
					@analysisMsgSub = @logObject["apiPath"]
				end

			elsif extMsg.include? "MultipartException: Could not parse multipart servlet request"
				@dangerVal = @@NO_DANGER
				@analysisMsg = "1102 - multipartException"
				@analysisMsgSub = @logObject["apiPath"]
			
			end


		elsif resultCode == "2001"
			@dangerVal = @@NO_DANGER
			@analysisMsg = "2001 - not support country"

		elsif resultCode == "3100"
			@dangerVal = @@NO_DANGER
			@analysisMsg = "3100 - no login user"

		elsif resultCode == "3101"
			if extMsg.include? "Cannot find auth token from pool"
				@dangerVal = @@DANGER_MONITORING
				@analysisMsg = "3101 - account token check fail"
				@analysisMsgSub = "LIC_4102, Cannot find auth token from pool"
			
			elsif extMsg.include? "502 Bad Gateway"
				@dangerVal = @@DANGER_MONITORING
				@analysisMsg = "3101 - account token check fail"
				@analysisMsgSub = "502 Bad Gateway"

			elsif extMsg.include? "java.net.SocketTimeoutException: Read timed out"
				@dangerVal = @@DANGER_MONITORING
				@analysisMsg = "3101 - account token check fail"
				@analysisMsgSub = "Read timed out"
		
			end

		elsif resultCode == "3200"
			if extMsg.include? "USR_3113" and 
			extMsg.include? "There is no user associated."
				@dangerVal = @@DANGER_MONITORING
				@analysisMsg = "3200 - account server error"
				@analysisMsgSub = "USR_3113, There is no user associated."
			end

		elsif resultCode == "4000"
			if extMsg.include? "seed list size 0" or
			extMsg.include? ".PersonalStationController.getPersonalStation" then
				@dangerVal = @@DANGER_MONITORING
				@analysisMsg = "4000 - delete personal Station"
				@analysisMsgSub = "maybe deleted personal station."

			end

		elsif resultCode == "4100"
			@dangerVal = @@NO_DANGER
			@analysisMsg = "4100 - pStation over 50"

		elsif resultCode == "4101"
			if extMsg.include? "resultCode is not 0 - resultCode : 4800"
				@dangerVal = @@NO_DANGER
				@analysisMsg = "4101 - can't use seed"
				@analysisMsgSub = "can't use personalStationSeed"
			end

		elsif resultCode == "5001"
			if extMsg.include? "===== callHttpRequest error =====connect timed out"
				@dangerVal = @@DANGER
				@analysisMsg = "5001 error"
				@analysisMsgSub = "connect timed out"

			elsif extMsg.include? "===== callHttpRequest error =====Read timed out"
				@dangerVal = @@DANGER
				@analysisMsg = "5001 error"
				@analysisMsgSub = "Read timed out"

			elsif extMsg.include? "- resultCode is not 0 -"
				@dangerVal = @@DANGER
				@analysisMsg = "5001 error"
				@analysisMsgSub = extMsg.match("(resultCode : \\S+)")[0]

			elsif extMsg.include? "- outgoing url has not setuped."
				@dangerVal = @@DANGER
				@analysisMsg = "5001 error"
				@analysisMsgSub = extMsg.match("[^◁▷]+")[0]

			end

		#######################
		# check 2000 error    #
		#######################
		elsif resultCode == "2000"
			if extMsg.include? "StringIndexOutOfBoundsException: String index out of range: -1"
				postBody = @logObject["postBody"]
				if postBody.include? "\"artistList\":[]"
					@dangerVal = @@DANGER_WILL_FIX
					@analysisMsg = "2000 - StringIndexOutOfBoundsException"
					@analysisMsgSub = "report api artist list is null"
				end

			elsif extMsg.include? "org.springframework.dao.CannotAcquireLockException"
				if extMsg.include? " Lock wait timeout exceeded"
					@dangerVal = @@DANGER_WILL_FIX
					@analysisMsg = "2000 - Lock wait timeout"
					@analysisMsgSub = extMsg.match("(.musicradio.store)\\S+(<br/>)")[0]
				end
			
			elsif extMsg.include? "java.io.IOException: Connection timed out"
				if extMsg.include? "at sun.nio.ch.FileDispatcherImpl.write0("
					@dangerVal = @@DANGER
					@analysisMsg = "2000 - connection timed out"
					@analysisMsgSub = "cause by - write fail."
				end

			elsif extMsg.include? "java.io.IOException: Broken pipe"
				if extMsg.include? "at sun.nio.ch.FileDispatcherImpl.write"
					@dangerVal = @@DANGER
					@analysisMsg = "2000 - Broken pipe"
					@analysisMsgSub = "cause by - write fail."
				end
			end
		
		else
			@dangerVal = @@NEED_CHECK
			@analysisMsg = "unknown error"

		end

	end

	###############################
	# error logger log.           #
	###############################
	private 
	def analyseErrorLoggerLog

		# get data
		remained = @logObject["remained"]

		# set data
		@logObject["logType"] = "errorLogger"


		if remained.include? "@@@@@ ERROR| /report/method/adjustment?"
			@dangerVal = @@NEED_DELETE  # delete
			@analysisMsg = "semi's adjustment msg"

		elsif remained.include? "@@@@@ ERROR| ■■■■■ bad license(token) sts code :" or
		remained.include? "@@@@@ ERROR| ■■■■■ bad profile(getUser) sts code" then
			@dangerVal = @@DANGER_MONITORING
			@analysisMsg = "account http res -not 200"

		elsif remained.include? "@@@@@ ERROR|  - soribada no login Id -"
			@dangerVal = @@DANGER_MONITORING
			@analysisMsg = "outgoing 4015 error"

		else
			@dangerVal = @@NEED_CHECK
			@analysisMsg = "unknown error"

		end

	end

	###############################
	# etc log.                    #
	###############################
	private 
	def analyseEtcLog

		# get data
		category = @logObject["category"]
		remained = @logObject["remained"]
		message = @logObject["message"]

		@logObject["logType"] = "etc"


		# unknown...
		if category == "io.undertow.request"
			if remained.include? "Blocking request failed HttpServerExchange"
				if remained.include? "java.io.IOException: UT000029: Channel was closed mid chunk"
					@dangerVal = @@DANGER
					@analysisMsg = "Channel was closed mid chunk"
					@analysisMsgSub = "maybe server res has been full"

				elsif remained.include? "java.io.IOException: Broken pipe"
					@dangerVal = @@DANGER
					@analysisMsg = "Broken pipe"
					@analysisMsgSub = "maybe server res has been full"

				end

			elsif remained.include? "ClassCastException: org.springframework.dao.DeadlockLoserDataAccessException cannot be cast to org.springframework.jdbc.BadSqlGrammarException"
				@dangerVal = @@DANGER
				@analysisMsg = "Deadlock"
				@analysisMsgSub = "Deadlock - ClassCastException"

			end

		elsif category.include? ".OutgoingServiceCallerTemplate"
			if remained.include? "===== callHttpRequest error ====="
				if remained.include? "connect timed out: java.net.SocketTimeoutException"
					@dangerVal = @@DANGER
					@analysisMsg = "connection timeout"
					@analysisMsgSub = "outgoing api"

				elsif remained.include? "Read timed out: java.net.SocketTimeoutException"
					@dangerVal = @@DANGER
					@analysisMsg = "read timeout"
					@analysisMsgSub = "outgoing api"

				end
			end

		elsif category == "stderr"
			@dangerVal = @@DANGER
			@analysisMsg = "stderr - unknown"

		elsif category.include? "ServiceExceptionResolver"
			if remained.include? "**** DataIntegrityViolationException"
				if message.include? "Duplicate entry "
					@dangerVal = @@DANGER
					@analysisMsg = "data integrity violation"
					@analysisMsgSub = "Duplicate entry"
			
				elsif message.include? "a foreign key constraint fails"
					@dangerVal = @@DANGER
					@analysisMsg = "data integrity violation"
					@analysisMsgSub = "a foreign key constraint fails"
				end
			end

		elsif category.include? "controller.ReportController"
			if remained.include? "■■■■ serverErrLog"
				if remained.include? "responseCode : 20" or
				remained.include? "\"resultCode\":"
					@dangerVal = @@NEED_DELETE  # delete
					@analysisMsg = "client resport serverError"
				else
					@dangerVal = @@DANGER_MONITORING
					@analysisMsg = "client resport serverError"
				end
			end

		# bean already defined - server restart...
		elsif category == "org.mybatis.spring.mapper.ClassPathMapperScanner"
			if remained.include? "Bean already defined with the same name!" 
				loglevel = @logObject["loglevel"]
				if loglevel == "WARN"
					@dangerVal = @@DANGER_MONITORING
					@analysisMsg = "bean already difined - server restart"
				end
			end


		elsif remained.include? "Request method 'GET' not supported"
			@dangerVal = @@DANGER_MONITORING
			@analysisMsg = "'GET' not supported"

		end

	end	


	###############################
	# sgmp log.                   #
	###############################
	private 
	def analyseSgmpLog

		# get value
		sgmpCode = @logObject["sgmpCode"]
		remained = @logObject["remained"]

#		if sgmpCode == "O1GE01"

		if remained.include? "resultCode is not 0 ("
			@dangerVal = @@DANGER_MONITORING
			@analysisMsg = remained.match("(resultCode is not 0 \\()\\S+(\\))")[0]

		elsif remained.include? "song api result size 0"
			@dangerVal = @@DANGER_MONITORING
			@analysisMsg = "song api result size 0"
			@analysisMsgSub = remained.match("(stationId : \\S+,)")[0]

		elsif remained.include? "Process error : Process Error"
				@dangerVal = @@DANGER

			if remained.include? "StringIndexOutOfBoundsException"
				@analysisMsg = "2000 error"
				@analysisMsgSub = "StringIndexOutOfBoundsException"

			elsif remained.include? "java.io.IOException: Broken pipe"
				@analysisMsg = "2000 error"
				@analysisMsgSub = "Broken pipe"

			end

		elsif remained.include? "connect timed out| callHttpRequest error"
			@dangerVal = @@DANGER
			@analysisMsg = "connect timed out"
			@analysisMsgSub = remained.match("(http://\\S+\\?)")[0]

		elsif remained.include? "Read timed out| callHttpRequest error"
			@dangerVal = @@DANGER
			@analysisMsg = "Read timed out"
			@analysisMsgSub = remained.match("(http://\\S+\\?)")[0]

		elsif 
			@dangerVal = @@NEED_CHECK
			@analysisMsg = "unknown sgmp"
		end
		
	end


	###############################
	# utils.                      #
	###############################
	private 
	def getLogValue(name)
		if @logObject.class == LogStash::Event
			return @logObject[name]

		elsif @logObject.class == Hashie::Mash
			return @logObject[name]

		end
	end

	def setLogValue(name, value)
		if @logObject.class == LogStash::Event
			@logObject[name] = value

		elsif @logObject.class == Hashie::Mash
			@logObject.name = value

		end
	end

end
