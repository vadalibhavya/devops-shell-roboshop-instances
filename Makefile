PASSWORD = DevOps321
USER = ec2-user
DOMAIN = doubtfree.online
SERVICES = mongodb redis mysql rabbitmq catalogue user cart shipping payment dispatch frontend

.PHONY: all $(SERVICES)

# Default: deploy all
all:
	@for service in $(SERVICES); do \
		echo "Connecting to $$service"; \
		sshpass -p "$(PASSWORD)" ssh -o StrictHostKeyChecking=no $(USER)@$$service.$(DOMAIN) 'bash -s' <<'EOF' ;\
cd /home/ec2-user ;\
if [ ! -d "devops-shell-roboshop-instances" ]; then \
  git clone https://github.com/vadalibhavya/devops-shell-roboshop-instances.git ;\
fi ;\
cd devops-shell-roboshop-instances ;\
git reset --hard HEAD ;\
git pull ;\
chmod +x $$service.sh ;\
sudo bash $$service.sh ;\
EOF \

done

# Dynamic target: run only one service, e.g., make user
$(SERVICES):
	@echo "Connecting to $@"
	@sshpass -p "$(PASSWORD)" ssh -o StrictHostKeyChecking=no $(USER)@$@.$(DOMAIN) 'bash -s' <<EOF
cd /home/ec2-user
if [ ! -d "devops-shell-roboshop-instances" ]; then
  git clone https://github.com/vadalibhavya/devops-shell-roboshop-instances.git
fi
cd devops-shell-roboshop-instances
git reset --hard HEAD
git pull
chmod +x $@.sh
sudo bash $@.sh
EOF
