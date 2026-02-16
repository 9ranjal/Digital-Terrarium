.PHONY: serve build clean install

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
