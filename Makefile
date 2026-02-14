.PHONY: covers books movies music refresh-books refresh-movies refresh-music

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
