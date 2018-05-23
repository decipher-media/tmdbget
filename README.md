tmdbget
=======

CLI tool to fetch movie/TV data for a single item from [TMDb](https://www.themoviedb.org/) and output to STDOUT in either JSON or YAML.

<img src="logo.png" width="400">

# Usage

The minimal example to get a result for a movie search:

```sh
ruby tmdbget.rb --apikey [TMDB APIKEY] 'The Terminator'
```

Would yield the result:
```json
{
  "The Terminator": {
    "vote_count": 5259,
    "id": 218,
    "video": false,
    "vote_average": 7.4,
    "title": "The Terminator",
		[...]
    "overview": "In the post-apocalyptic future, reigning tyrannical supercomputers teleport a cyborg assassin known as the \"Terminator\" back to 1984 to kill Sarah Connor, whose unborn son is destined to lead insurgents against 21st century mechanical hegemony. Meanwhile, the human-resistance movement dispatches a lone warrior to safeguard Sarah. Can he stop the virtually indestructible killing machine?",
    "release_date": "1984-10-26",
    "release_year": "1984"
  }
}
```

It is also possible to specify a year to narrow search, enable an interactive prompt (on STDERR, to not interfere with output redirection) for iffy titles, disable JSON pretty-print, or just go straight to YAML for readability. Just check the help output:

```sh
./tmdbget.rb -h
Fetch movie/TV data for a single item from TMDB and output to STDOUT in either JSON or YAML.
Usage: tmdbget.rb [options] <title>
    -h, --h                          Display this help output
    -y, --year YEAR                  Year of release. This may do nothing for TV search.
        --yaml                       Output in YAML for easier human-reading.
    -a, --append x,y,z               Additional requests from within the same namespace (like credits, images, recommendations) to deliver along with the results. 
See [https://developers.themoviedb.org/3/tv] and [https://developers.themoviedb.org/3/movies for a detailed list of options, or just specify "all".
    -k, --key KEY                    TMDB API key or the path to a file containing such a key.
    -i, --interactive                Enable in order to present search results for selection on STDERR, eventually printing the final selection to STDOUT.
    -m, --maxshow MAXSHOW            Limit search results. By default, returns all.
        --nopretty                   Disable pretty-printing of JSON output.
    -t, --tv                         Search TV instead of Movies.

```

# Installation

## Requirements

### In general

* [Ruby](https://www.ruby-lang.org/en/documentation/installation/)
* [TMDB API key](https://www.themoviedb.org/documentation/api)

### From the Gemfile

* [Faraday](https://github.com/lostisland/faraday)
* [Rubocop](https://github.com/bbatsov/rubocop) (for testing)

## Install

```sh
git clone https://github.com/decipher-media/tmdbget.git
cd tmdbget
bundle install
```

# Testing

One day...?

# Contributing

Taking pull requests at [https://github.com/decipher-media/tmdbget.git](https://github.com/decipher-media/tmdbget.git)

# Credits

By Christopher Peterson: [website](https://chrispeterson.info) | [twitter](https://www.twitter.com/cspete)

for Decipher Media: [website](https://deciphermedia.tv) | [github](https://github.com/decipher-media)

License
-------

Copyright (c) Christopher Peterson. [License](LICENSE).

