.PHONY: serve build clean install covers books movies music refresh-books refresh-movies refresh-music

# Default: run local dev server
serve:
	bundle exec jekyll serve

# Build site into _site (no server)
build:
	bundle exec jekyll build

# Build with incremental (faster rebuilds)
build-incremental:
	bundle exec jekyll build --incremental

# Remove generated site
clean:
	rm -rf _site

# Install Ruby dependencies
install:
	bundle install

# Full clean build
rebuild: clean build

# Serve with drafts visible
serve-drafts:
	bundle exec jekyll serve --drafts

# Serve on a different port (e.g. 4001)
serve-port:
	bundle exec jekyll serve --port 4001

# Fetch missing covers (run from repo root)
books:
	ruby scripts/fetch_book_covers.rb

movies:
	ruby scripts/fetch_movie_covers.rb

music:
	ruby scripts/fetch_music_covers.rb

# Fetch all covers
covers: books movies music

# Refetch all covers (overwrite existing)
refresh-books:
	REFRESH=1 ruby scripts/fetch_book_covers.rb

refresh-movies:
	REFRESH=1 ruby scripts/fetch_movie_covers.rb

refresh-music:
	REFRESH=1 ruby scripts/fetch_music_covers.rb
