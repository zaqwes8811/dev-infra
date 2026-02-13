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

# 2 - Prepare local pc to deploy infra

# Setup Git
sudo apt install git

# Setup Sublime
sudo snap install sublime-text --classic

# Clone repository
git clone https://github.com/<username>/<name-repository>

# Setup Docker by using official manual
https://docs.docker.com/engine/install/ubuntu/

# Proceed post-installation steps for Docker Engine
https://docs.docker.com/engine/install/linux-postinstall/

# 3 - Unroll on VPS. By using vps.md proceed steps from first up to "S3 Storage"

# 4 - Setup Jenkins by using this tutorial
https://timeweb.cloud/tutorials/ci-cd/avtomatizaciya-nastrojki-jenkins-s-pomoshchyu-docker