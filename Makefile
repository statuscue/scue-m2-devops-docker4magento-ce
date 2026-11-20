include .env

up: ## Pull and start up containers
#	docker-compose pull
	docker-compose up -d --remove-orphans

down: stop ## Stop containers

start: ## Start containers without updating
	@docker-compose start

stop: ## Stop containers
	@docker-compose stop

# You can optionally pass an argument with the service name to prune single container
# 
#    prune mariadb : Prune `mariadb` container and remove its volumes.
#    prune mariadb solr : Prune `mariadb` and `solr` containers and remove their volumes.
prune: ## Remove containers and their volumes
	@echo "Removing containers for $(PROJECT_NAME)..."
	@docker-compose down -v $(filter-out $@,$(MAKECMDGOALS))

ps: ## List running containers
	@docker ps --filter name='$(PROJECT_NAME)*'

# You can optionally pass an argument with a service name to open a shell on the specified container
shell: ## Access container via shell. Default `php` container.
	docker exec -ti -e COLUMNS=$(shell tput cols) -e LINES=$(shell tput lines) $(shell docker ps --filter name='$(PROJECT_NAME)_$(or $(filter-out $@,$(MAKECMDGOALS)), 'php')' --format "{{ .ID }}") sh

# You can optinally pass an argument with the service name to limit logs
#
#    logs php : View `php` container logs.
#    logs nginx php : View `nginx` and `php` containers logs.
logs: ## View containers logs
	@docker-compose logs -f $(filter-out $@,$(MAKECMDGOALS))

magento: ## Magento CLI
	docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") bin/magento $(filter-out $@,$(MAKECMDGOALS))

n98: ## netz98/n98-magerun2 CLI
	docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") n98-magerun2 $(filter-out $@,$(MAKECMDGOALS)) --root-dir=$(MAGENTO_ROOT) --skip-core-commands 

install: up ## Install Magento 2
	docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") sh -c "\
	    composer config --global http-basic.repo.magento.com $(COMPOSER_MAGENTO_REPO_USERNAME) $(COMPOSER_MAGENTO_REPO_PASSWORD) && \
	    composer create-project --no-interaction --repository=https://repo.magento.com/ magento/project-community-edition=$(MAGENTO_VERSION) ~/magento2 && \
	    cp -a ~/magento2/. /var/www/html/ && \
	    rm -rf ~/magento2 && \
	    chmod u+x bin/magento && \
	    if [[ "$(MAGENTO_VERSION)" == "2.4.0" ]]; then \
	        bin/magento setup:install \
	            --base-url=http://$(PROJECT_BASE_URL):$(PROJECT_BASE_PORT)/ \
	            --db-host=$(DB_HOST) \
	            --db-name=$(DB_NAME) \
	            --db-user=$(DB_USER) \
	            --db-password=$(DB_PASSWORD) \
	            --admin-firstname=$(MAGENTO_ADMIN_FIRSTNAME) \
	            --admin-lastname=$(MAGENTO_ADMIN_LASTNAME) \
	            --admin-email=$(MAGENTO_ADMIN_EMAIL) \
	            --admin-user=$(MAGENTO_ADMIN_USER) \
	            --admin-password=$(MAGENTO_ADMIN_PASSWORD) \
	            --backend-frontname=$(MAGENTO_BACKEND_FRONTNAME) \
	            --language=$(MAGENTO_LANGUAGE) \
	            --currency=$(MAGENTO_CURRENCY) \
	            --timezone=$(MAGENTO_TIMEZONE) \
	            --use-rewrites=1 \
	            --search-engine=elasticsearch7 \
	            --elasticsearch-host=elasticsearch && \
	        bin/magento module:disable Magento_TwoFactorAuth --clear-static-content && \
	        bin/magento cache:flush; \
	    else \
	        bin/magento setup:install \
	            --base-url=http://$(PROJECT_BASE_URL):$(PROJECT_BASE_PORT)/ \
	            --db-host=$(DB_HOST) \
	            --db-name=$(DB_NAME) \
	            --db-user=$(DB_USER) \
	            --db-password=$(DB_PASSWORD) \
	            --admin-firstname=$(MAGENTO_ADMIN_FIRSTNAME) \
	            --admin-lastname=$(MAGENTO_ADMIN_LASTNAME) \
	            --admin-email=$(MAGENTO_ADMIN_EMAIL) \
	            --admin-user=$(MAGENTO_ADMIN_USER) \
	            --admin-password=$(MAGENTO_ADMIN_PASSWORD) \
	            --backend-frontname=$(MAGENTO_BACKEND_FRONTNAME) \
	            --language=$(MAGENTO_LANGUAGE) \
	            --currency=$(MAGENTO_CURRENCY) \
	            --timezone=$(MAGENTO_TIMEZONE) \
	            --use-rewrites=1 && \
	        bin/magento config:set catalog/search/engine elasticsearch6 && \
	        bin/magento config:set catalog/search/elasticsearch6_server_hostname elasticsearch && \
	        bin/magento indexer:reindex; \
	    fi && \
	    bin/magento config:set dev/image/default_adapter IMAGEMAGICK && \
	    bin/magento cache:clean config && \
	    bin/magento deploy:mode:set developer && \
	    bin/magento cache:disable layout block_html full_page"

.PHONY: up down start stop prune ps shell logs magento n98 install

.DEFAULT_GOAL := help
help: ## Print this help
	@grep -E '(^[0-9a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) \
		| sed -e 's/^.*Makefile://g' \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' \
		| sed -e 's/\[32m##/[33m/'
.PHONY: help

# https://stackoverflow.com/a/6273809/1826109
%:
	@:
