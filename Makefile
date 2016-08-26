BASE_IMG_NAME = bedrock_base
DEV_IMG_NAME = bedrock_dev
FINAL_IMG_NAME = bedrock_dev_final

default:
	@echo "You need to specify a subcommand."
	@exit 1

help:
	@echo "build           - build docker containers for dev"
	@echo "run             - docker-compose up the entire system for dev"
	@echo ""
	@echo "clean           - remove all build, test, coverage and Python artifacts"
	@echo "lint            - check style with flake8"
	@echo "test            - run unit tests"
	@echo "test-redirects  - run redirect tests"
	@echo "test-both 			 - run unit and redirect tests"
	@echo "test-image      - run tests on the code built into the docker image"
	@echo "lint-image      - check style of the code built into the docker image with flake8"
	@echo "docs            - generate Sphinx HTML documentation, including API docs"

.docker-build:
	${MAKE} build

.docker-build-final:
	${MAKE} build-final

build:
	docker build -f docker/dockerfiles/bedrock_base -t ${BASE_IMG_NAME} --pull .
	docker build -f docker/dockerfiles/bedrock_dev -t ${DEV_IMG_NAME} .
	touch .docker-build

build-final: .docker-build
	docker build -f docker/dockerfiles/bedrock_dev_final -t bedrock_dev_final .
	touch .docker-build-final

run: .docker-build
	docker run --env-file docker/dev.env -p 8000:8000 -v "$$PWD:/app" ${DEV_IMG_NAME}

django-shell: .docker-build
	docker run -it --env-file docker/dev.env -v "$$PWD:/app" ${DEV_IMG_NAME} "./manage.py shell"

shell: .docker-build
	docker run -it --env-file docker/dev.env -v "$$PWD:/app" ${DEV_IMG_NAME} bash

sync-all: .docker-build
	docker run --env-file docker/dev.env -p 8000:8000 -v "$$PWD:/app" ${DEV_IMG_NAME} "bin/sync_all"

clean:
	# python related things
	find . -name '*.egg-info' -exec rm -rf {} +
	find . -name '*.egg' -exec rm -f {} +
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -rf {} +

	# test related things
	-rm -f .coverage

	# docs files
	-rm -rf docs/_build/

	# state files
	-rm .docker-build

test: .docker-build
	docker run --env-file docker/test.env -v "$$PWD:/app" ${DEV_IMG_NAME} docker/run-tests.sh

test-image: .docker-build-final
	docker run --env-file docker/test.env ${FINAL_IMG_NAME} docker/run-tests.sh

docs:
	docker run --env-file docker/dev.env -v "$$PWD:/app" ${DEV_IMG_NAME} make -C docs/ clean && make -C docs/ html

.PHONY: default clean build build-final docs run test sync-all test-image shell django-shell
