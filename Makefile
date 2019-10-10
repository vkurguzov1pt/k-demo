
.PHONY: help init apply deploy remove clean destroy dns_edit dns_revert

help:
	@echo "Run \033[1m'make deploy'\e[0m to deploy project"
	@echo "Run \033[1m'make dns_edit'\e[0m to add my-nginx.internal to /etc/hosts"
	@echo "Run \033[1m'make destroy'\e[0m to delete project"
	@@echo "Run \033[1m'make dns_revert'\e[0m to revert /etc/hosts state"

init:
	@cd terraform/subnets; terraform init && cd $$OLDPWD
	@cd terraform/security-groups; terraform init && cd $$OLDPWD
	@cd terraform/route53; terraform init && cd $$OLDPWD
	@cd terraform/alb; terraform init && cd $$OLDPWD
	@cd terraform/asg; terraform init && cd $$OLDPWD

apply:
	@cd terraform/subnets; terraform apply -auto-approve && cd $$OLDPWD
	@cd terraform/security-groups; terraform apply -auto-approve && cd $$OLDPWD
	@cd terraform/route53; terraform apply -auto-approve && cd $$OLDPWD
	@cd terraform/alb; terraform apply -auto-approve && cd $$OLDPWD
	@cd terraform/asg; terraform apply -auto-approve && cd $$OLDPWD

dns_edit:
	@sudo bash -c 'echo "$$(dig +short $$(cd terraform/alb && terraform output | grep alb | cut -d "=" -f2 | xargs) | head -n 1) my-nginx.internal" >> /etc/hosts'

deploy: init apply

remove:
	@cd terraform/asg; terraform destroy -auto-approve && cd $$OLDPWD
	@cd terraform/alb; terraform destroy -auto-approve && cd $$OLDPWD
	@cd terraform/route53; terraform destroy -auto-approve && cd $$OLDPWD
	@cd terraform/security-groups; terraform destroy -auto-approve && cd $$OLDPWD
	@cd terraform/subnets; terraform destroy -auto-approve && $$OLDPWD

clean:
	@find . -name ".terraform" -type d -exec rm -r {} +

dns_revert:
	@sudo bash -c 'sed -i "/my-nginx.internal/d" /etc/hosts'

destroy: remove clean
