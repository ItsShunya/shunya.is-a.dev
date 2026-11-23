HUGO ?= hugo
PORT ?= 1313

.PHONY: help init serve serve-prod build new clean

help:
	@echo "make init          - pull theme submodule"
	@echo "make serve         - local server with drafts/future/expired posts"
	@echo "make serve-prod    - local server, published content only"
	@echo "make build         - production build into ./public"
	@echo "make new name=foo  - new post bundle, prefixed with today's date"
	@echo "make clean         - remove generated files"

# first time after cloning
init:
	git submodule update --init --recursive

# what I use while writing
serve:
	$(HUGO) server --minify -D -E -F --port $(PORT)

# check what will actually go live
serve-prod:
	$(HUGO) server --minify --port $(PORT)

# same as CI, minus the baseURL
build:
	$(HUGO) --gc --minify

# e.g. make new name=my-post
new:
	@test -n "$(name)" || (echo "usage: make new name=my-post" && exit 1)
	$(HUGO) new content posts/$(shell date +%Y%m%d)-$(name)/index.md

clean:
	rm -rf public resources/_gen .hugo_build.lock
