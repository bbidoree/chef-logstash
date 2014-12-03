$noFilter = true

require 'elasticsearch'
require 'hashie'
require './milkLogAnalyser.rb'
require 'pry'


# set initialize value
maxUpdateSize = -1
isLoggingOrgData = false

searchPageSize = 100



# elastic search initialize.
client = Elasticsearch::Client.new log: true
client.transport.logger.level = Logger::WARN

# get target data total size
response = client.search body: 
{
    facets: {
        dangerVal: {
            terms: {
                field: 'dangerVal'
            }
        }
    }
}

mash = Hashie::Mash.new response

puts " ======================================"
puts " ======= facets about dangerVal ======="
puts " ======================================"
puts JSON.pretty_generate(mash.facets)

needCheckCount = 0
for term in mash.facets.dangerVal.terms
	if term.term! == 100
		needCheckCount = term.count!
	end
end

puts " ======= total count is #{needCheckCount} ======="
puts "\n\n\n\n\n"


#binding.pry

# get target data size 100
totalPrcCnt = 0
findNeedCheck = false
lastPageNum = needCheckCount/searchPageSize
for i in 0...lastPageNum

	response = client.search index: "logstash-*" , body: 
		{ 
			query: { 
				match: { 
					dangerVal: '100' 
				} 
			},
			from: (lastPageNum-i)*searchPageSize,
			size: searchPageSize
		}

	#puts " ======= process : #{i*searchPageSize} / #{needCheckCount} ========"


	mash = Hashie::Mash.new response	
#puts JSON.pretty_generate(mash)

	# use filter
	curPrcCnt = 0
	isPrint = false
	for searchItem in mash.hits.hits
		src = searchItem._source
		MilkLogAnalyzer.new(src)

		# temp... 
		if src.dangerVal == 100
			puts JSON.pretty_generate(searchItem)
			findNeedCheck = true
			break
		end

		if src.dangerVal != nil and src.dangerVal != 100
			client.index  index: searchItem._index, 
				type: searchItem._type, 
				id: searchItem._id, 
				body: src

			curPrcCnt = curPrcCnt + 1
			#puts "     ID : #{searchItem._id}"
		end
	end
	
	totalPrcCnt = totalPrcCnt + curPrcCnt
	puts "   -- reindexing : cur[#{curPrcCnt} / 100], total[ #{totalPrcCnt} / #{needCheckCount} ========"
	
	#temp
	if findNeedCheck
		break
	end

end







=begin

response = client.search index: '_search', body: { query: { match: { dangerVal: '100' } } }


mash = Hashie::Mash.new response

puts JSON.pretty_generate(mash)

########################
# index update 
########################

index = mash.hits.hits.first._index
type = mash.hits.hits.first._type
id = mash.hits.hits.first._id

sourceMash = mash.hits.hits.first._source

# task tnwjd
sourceMash.task = "kyani test ruby"


puts "index"
client.index  index: index, type: type, id: id, body: sourceMash.to_json

=end




