PASSWORD = DevOps321
USER = ec2-user
DOMAIN = doubtfree.online

deploy:
	@echo "Deploying all services..."
	@for service in mongodb redis mysql rabbitmq catalogue user cart shipping payment dispatch frontend; do \
		$(MAKE) $$service; \
	done

%:
	@echo "Connecting to $@.$(DOMAIN)"
	@sshpass -p $(PASSWORD) ssh -o StrictHostKeyChecking=no $(USER)@$@.$(DOMAIN) "\
		cd /home/ec2-user && \
		if [ ! -d devops-shell-roboshop-instances ]; then \
			git clone https://github.com/vadalibhavya/devops-shell-roboshop-instances.git; \
		fi && \
		cd devops-shell-roboshop-instances && \
		git reset --hard HEAD && \
		git pull && \
		chmod +x $@.sh && \
		sudo bash $@.sh"
