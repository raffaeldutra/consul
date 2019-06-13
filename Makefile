# COLORS
RED    := $(shell tput -Txterm setaf 1)
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
BLUE   := $(shell tput -Txterm setaf 4)
PURPLE := $(shell tput -Txterm setaf 5)
CYAN   := $(shell tput -Txterm setaf 6)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)

.PHONY : help
help :
	@echo "agent       : Inicializa Consul."
	@echo "bootstrap   : Gerando token."
	@echo "key-admin   : Key admin."
	@echo "key-read    : Key read policy."
	@echo "token-admin : Token administrative."
	@echo "token-read  : Token read."

# Caso OSX, o pwd não é o mesmo de Linux
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	pwd = ${PWD}
else
	pwd = $(shell pwd)
endif

token=$(shell cat admin.token)

agent:
	mkdir -p $(pwd)/consul.d/tokens
	$(pwd)/consul agent -dev -config-file=consul.d/acl.json

bootstrap:
	$(pwd)/consul acl bootstrap

members:
	$(pwd)/consul members

key-admin:
	$(pwd)/consul acl policy create \
	-name "Key-admin-policy" \
	-description "Policy for generating tokens with administrative access to keys" \
	-rules @consul.d/key_admin_policy.hcl \
	-token "${token}" > outputs/key-admin-policy.policy.output

key-read:
	$(pwd)/consul acl policy create \
	-name "Key-readonly-policy" \
	-description "Policy for generating tokens with readonly access to keys" \
	-rules @consul.d/key_readonly_policy.hcl \
	-token "${token}" > outputs/key-read.policy.output

token-admin:
	$(pwd)/consul acl token create \
	-description "Agent administrative token" \
	-policy-name "Key-admin-policy" \
	-token "${token}" > tokens/token-admin.token

token-read:
	$(pwd)/consul acl token create \
	-description "Agent readonly token" \
	-policy-name "Key-readonly-policy" \
	-token "${token}" > tokens/token-read.token

run:
	make bootstrap
	make key-admin
	make key-read
	make token-admin
	make token-read
