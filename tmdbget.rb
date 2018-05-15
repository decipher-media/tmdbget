#!/usr/bin/env ruby

require 'bundler/setup'

def trunc(str, lim, replace_end: '...')
  return str unless (str.length + replace_end.length) > lim
  newstr = str[0..lim - 1 - replace_end.length] + replace_end
  return newstr
end

def argparse
  require 'optparse'

  # Defaults
  args = Hash.new(nil)
  args = {
    :maxshow => 4,
    :year => '',
  }
  required = [
    'key'
  ]

  parser = OptionParser.new do |opts|
    opts.banner = 'Fetch movie/TV data for a single item from TMDB and output to STDOUT in either '\
    "JSON or YAML.\n"\
    "Usage: #{$PROGRAMNAME} [options] <title>"

    opts.on('-h', '--h',
            'Display this help output'
           ) do |help|
      puts opts
      exit
    end

    opts.on('-y YEAR', '--year YEAR',
            'Year of release. This may do nothing for TV search.',
           ) do |year|
      args[:year] = year
    end

    opts.on('--yaml',
            'Output in YAML for easier human-reading.',
           ) do |yaml|
      args[:yaml] = yaml
    end

    opts.on('-k KEY', '--key KEY',
            'TMDB API key or the path to a file containing such a key.',
           ) do |key|
      if File.file?(key)
        keyval = File.open(key) { |f| f.readline.chomp }
      else
        keyval = key
      end
      args[:key] = keyval
    end

    opts.on('-i', '--interactive',
            'Enable in order to present search results for selection on STDERR, eventually '\
            'printing the final selection to STDOUT.',
           ) do |interactive|
      args[:interactive] = interactive
    end

    opts.on('-m MAXSHOW', '--maxshow MAXSHOW',
            'Limit search results. By default, returns all.',
           ) do |maxshow|
      args[:maxshow] = maxshow.to_i
    end

    opts.on('--nopretty',
            'Disable pretty-printing of JSON output.',
           ) do |nopretty|
      args[:nopretty] = nopretty
    end

    opts.on('-t', '--tv',
            'Search TV instead of Movies.',
           ) do |tv|
      args[:tv] = tv
    end
  end
  parser.parse!

  # Positional arguments
  if ARGV.length != 1
    puts 'Missing positional arguments. Run with -h for usage.'
    exit 1
  else
    args[:title] = ARGV[0]
  end

  # Required options
  required.each do |optname|
    if not args[optname.to_sym]
      puts "Did not provide required argument '--#{optname}'. Run with -h for usage."
      exit 1
    end
  end

  return args
end

def main
  require 'faraday'
  require 'json'
  require 'uri'

  Signal.trap('INT') do
    STDERR.puts 'Exiting...'
    exit 130
  end

  args = argparse

  apikey = args[:key]
  interactive = args[:interactive]
  max_show = args[:maxshow]
  nopretty = args[:nopretty]
  searchtv = args[:tv]
  title = args[:title]
  yaml = args[:yaml]
  year = args[:year]

  if not searchtv
    querytype = 'movie'
    date_field = 'release_date'
    title_field = 'title'
  else
    querytype = 'tv'
    date_field = 'first_air_date'
    title_field = 'name'
  end
  uri = 'https://api.themoviedb.org/3/search/'\
        "#{querytype}?"\
        "api_key=#{apikey}"\
        "&query=#{URI.encode(title)}"\
        "&year=#{URI.encode(year)}"
  begin
    response = Faraday.get(uri)
    jsondata = JSON.parse(response.body)
    if jsondata['status_code']
      STDERR.puts results['status_message']
      raise Faraday::Error
    end
    results = jsondata['results'][0..max_show-1]
  rescue Faraday::Error
    STDERR.puts 'Oh noes, API GET failed..'
    raise
  end

  if interactive
    STDERR.puts 'Interactive mode selected. Showing top results...'
    results.each_with_index do |data, idx|
      rel_date = data[date_field].split('-')[0]
      STDERR.puts "[#{idx + 1}] #{data[title_field]}: #{rel_date}"
      STDERR.puts "      \"#{trunc(data['overview'], 200)}\""
    end
    STDERR.print 'Select a title by [index]: '
    sel_idx = STDIN.gets.chomp.to_i - 1
    selection = results[sel_idx]
  else
    selection = results[0]
  end

  # Altering the final selection data structure
  # Add a new year-only date field
  selection['release_year'] = selection[date_field].split('-')[0]
  tmdb_title = selection[title_field]
  final_data = Hash.new
  final_data[tmdb_title] = selection

  if yaml
    require 'yaml'
    puts YAML.dump(final_data)
  else
    # else json
    if nopretty
      puts JSON.generate(final_data)
    else
      puts JSON.pretty_generate(final_data)
    end
  end
end

main if $PROGRAM_NAME == __FILE__
