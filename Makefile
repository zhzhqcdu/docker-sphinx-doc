FIND_EXCLUDE_PATHS ?= -not -path './.*/*' -not -path './node_modules/*'
IMAGE_NAME ?= keimlink/sphinx-doc

.DEFAULT_GOAL := help

.PHONY: help
help:
	@grep -E '^[\.a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: build-latest
build-latest: ## Build latest image
	./bin/image.sh build $(IMAGE_NAME) latest

.PHONY: build-latex
build-latex: ## Build latex image
	./bin/image.sh build $(IMAGE_NAME) latex

.PHONY: build
build: build-latest build-latex ## Build all images
	docker images $(IMAGE_NAME)

.PHONY: lint
lint: ## Run lint checks
	docker run --interactive --rm --tty --volume $$(pwd):/home/node/src node:8.9.4-alpine \
		su - node -c 'cd src \
			&& yarn install \
			&& yarn eslint . --ext .js \
			&& yarn eclint check "**" "!*.swp" "!docs/**" "!yarn.lock" \
			&& yarn markdownlint "**.md"'
	find . $(FIND_EXCLUDE_PATHS) -name "*.sh" -exec \
		docker run --interactive --rm --tty --volume $$(pwd):/mnt koalaman/shellcheck-alpine:v0.4.7 {} +
	docker run --interactive --rm --tty --volume $$(pwd):/workdir boiyaa/yamllint:1.8.1 --strict .yamllint .

.PHONY: node
node: ## Run node container
	docker run --interactive --rm --tty --volume $$(pwd):/home/node/src node:8.9.4-alpine su - node

.PHONY: smoke-test-latest
smoke-test-latest: ## Run smoke tests for latest image
	./bin/image.sh test $(IMAGE_NAME) latest

.PHONY: smoke-test-latex
smoke-test-latex: ## Run smoke tests for latex image
	./bin/image.sh test $(IMAGE_NAME) latex

.PHONY: smoke-test
smoke-test: smoke-test-latest smoke-test-latex ## Run all smoke tests
