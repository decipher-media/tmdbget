#!/usr/bin/env ruby

require 'bundler/setup'

def trunc(str, lim, replace_end: '...')
  return str unless (str.size + replace_end.size) > lim
  newstr = str[0..lim - 1 - replace_end.size] + replace_end
  return newstr
end

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
def argparse
  require 'optparse'

  # Defaults
  args = Hash.new(nil)
  args = {
    'append' => '',
    'maxshow' => 4,
    'year' => '',
  }
  required = [
    'key',
  ]

  # rubocop:disable Metrics/BlockLength:
  parser = OptionParser.new do |opts|
    opts.banner = 'Fetch movie/TV data for a single item from TMDB and output to STDOUT in '\
    "either JSON or YAML.\n"\
    "Usage: #{$PROGRAM_NAME} [options] <title>"

    opts.on('-h', '--h',
            'Display this help output') do
      puts opts
      exit
    end

    opts.on('-y YEAR', '--year YEAR',
            'Year of release. This may do nothing for TV search.') do |year|
      args['year'] = year
    end

    opts.on('--yaml',
            'Output in YAML for easier human-reading.') do |yaml|
      args['yaml'] = yaml
    end

    opts.on('-a x,y,z', '--append x,y,z',
            'Additional requests from within the same namespace (like credits, images, '\
            "recommendations) to deliver along with the results. \n"\
            'See [https://developers.themoviedb.org/3/tv] and '\
            '[https://developers.themoviedb.org/3/movies for a detailed list of options, or just '\
            'specify "all".') do |append|
      args['append'] = append
    end

    opts.on('-k KEY', '--key KEY',
            'TMDB API key or the path to a file containing such a key.') do |key|
      args['key'] = if File.file?(key)
                      File.open(key) { |f| f.readline.chomp }
                    else
                      key
                    end
    end

    opts.on('-i', '--interactive',
            'Enable in order to present search results for selection on STDERR, eventually '\
            'printing the final selection to STDOUT.') do |interactive|
      args['interactive'] = interactive
    end

    opts.on('-m MAXSHOW', '--maxshow MAXSHOW',
            'Limit search results. By default, returns all.') do |maxshow|
      args['maxshow'] = maxshow.to_i
    end

    opts.on('--nopretty',
            'Disable pretty-printing of JSON output.') do |nopretty|
      args['nopretty'] = nopretty
    end

    opts.on('-t', '--tv',
            'Search TV instead of Movies.') do |tv|
      args['tv'] = tv
    end
  end
  # rubocop:enable Metrics/BlockLength:
  parser.parse!

  # Positional arguments
  if ARGV.size != 1
    STDERR.puts 'Missing positional arguments. Run with -h for usage.'
    exit 1
  else
    args['title'] = ARGV[0]
  end

  # Required options
  required.each do |optname|
    unless args[optname]
      STDERR.puts "Did not provide required argument '--#{optname}'. Run with -h for usage."
      exit 1
    end
  end

  return args
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength

def query_api(uri)
  require 'faraday'
  require 'json'

  begin
    response = Faraday.get(uri)
    jsondata = JSON.parse(response.body)
    if jsondata['status_code']
      STDERR.puts "THE API says: #{jsondata['status_message']}"
      exit 1
    end
  rescue Faraday::Error
    STDERR.puts 'Oh noes, API GET failed..'
    raise
  end

  return jsondata
end

def main
  require 'json'
  require 'cgi'

  Signal.trap('INT') do
    STDERR.puts 'Exiting...'
    exit 130
  end

  subresources = {
    'tv' => [
			'account_states',
			'alternative_titles',
			'changes',
			'content_ratings',
			'credits',
			'external_ids',
			'images',
			'keywords',
			'lists',
			'recommendations',
			'release_dates',
			'reviews',
			'screened_theatrically',
			'similar',
			'translations',
			'videos',
    ],
		'movie' => [
			'account_states',
			'alternative_titles',
			'changes',
			'credits',
			'external_ids',
			'images',
			'keywords',
			'release_dates',
			'videos',
			'translations',
			'recommendations',
			'similar',
			'reviews',
			'lists',
		],
  }

  args = argparse

  apikey = args['key']
  interactive = args['interactive']
  max_show = args['maxshow']
  nopretty = args['nopretty']
  searchtv = args['tv']
  title = args['title']
  yaml = args['yaml']
  year = args['year']

  if !searchtv
    querytype = 'movie'
    date_field = 'release_date'
    title_field = 'title'
  else
    querytype = 'tv'
    date_field = 'first_air_date'
    title_field = 'name'
  end
  append_resources = if args['append'] == 'all'
                       subresources[querytype].join(',')
                     else
                       args['append']
                     end

  uri = 'https://api.themoviedb.org/3/search/'\
        "#{querytype}?"\
        "api_key=#{apikey}"\
        "&query=#{CGI.escape(title)}"\
        "&year=#{CGI.escape(year)}"

  results = query_api(uri)['results'][0..max_show - 1]
  if results.empty?
    STDERR.puts 'Zero results returned.'
    exit 3
  end
  if interactive
    STDERR.puts 'Interactive mode selected. Showing top results...'
    STDERR.puts
    results.each_with_index do |data, idx|
      rel_date = data[date_field].split('-')[0]
      STDERR.puts "[#{idx + 1}] #{data[title_field]}: #{rel_date}"
      STDERR.puts "      \"#{trunc(data['overview'], 200)}\""
    end
    STDERR.puts
    STDERR.print 'Select a title by [index]: '
    sel_idx = STDIN.gets.chomp.to_i - 1
    selection_id = results[sel_idx]['id']
  else
    selection_id = results[0]['id']
  end

  # Get the final selection plus all specified subresources
  uri = "https://api.themoviedb.org/3/#{querytype}/#{selection_id}?"\
        "api_key=#{apikey}"\
        "&append_to_response=#{CGI.escape(append_resources)}"
  selection = query_api(uri)

  # Altering the final selection data structure
  # Add a new year-only date field
  selection['release_year'] = selection[date_field].split('-')[0]

  if yaml
    require 'yaml'
    puts YAML.dump(selection)
  elsif nopretty
    puts JSON.generate(selection)
  else
    puts JSON.pretty_generate(selection)
  end
end

main if $PROGRAM_NAME == __FILE__
