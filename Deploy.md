# 1 - sing up/in  github.com

#  go to Profile Settings -> Developer settings -> Personal access tokens -> Tokens (classic) -> Generate new token -> Save token
# open Ubuntu terminal, create ~.netrc and fill it with login and passsword(token)
nano ~/.netrc

machine github.com
    login YOUR_GITHUB_USERNAME
    password YOUR_GENERATED_TOKEN

# Restrict acces to ~.netrc
chmod 600 ~/.netrc

# Check
git ls-remote https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME

# Setup git user
git config --global user.name "Ваше Имя"
git config --global user.email "ваш-email@example.com"

# 2 - Prepare local pc to deploy infra

# Setup Git
sudo apt install git

# Setup Sublime
sudo snap install sublime-text --classic

# Clone repository
cd ~
git clone https://github.com/hedge-in-fog/dev-infra.git
cd dev-infra

# Setup Docker by using official manual
https://docs.docker.com/engine/install/ubuntu/

# Proceed post-installation steps for Docker Engine
https://docs.docker.com/engine/install/linux-postinstall/

# 3 - Unroll on VPS. By using vps.md proceed steps from first up to step 3 "Reboot and Check" (included)

# 4 - Create `creds/creds.env`

# 5 -Create creds Creds for `Garage`

# 6 - Start Docker compose app
`docker compose build`
`docker compose up -d`

# 7 - Configure Jenkins
Setup Jenkins by using this tutorial
https://timeweb.cloud/tutorials/ci-cd/avtomatizaciya-nastrojki-jenkins-s-pomoshchyu-docker

# 7.1 - Go to service `127.0.0.1:8081`
```
docker exec -it jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword
```
It will return initial password. Paste admin password to login page.

# 7.2 - Install plugins

# 7.3 - Create admin user. Save password to secret place

# 7.4 - Create simplest pipelane
