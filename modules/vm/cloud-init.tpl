#cloud-config
package_update: true
package_upgrade: true

packages:
  - nginx
  - curl
  - unzip
  - apt-transport-https
  - docker.io
  - docker-compose-v2

runcmd:
  # Enable Docker for application and self-hosted runner workloads
  - systemctl enable docker
  - systemctl restart docker
  - usermod -aG docker azureuser

  # Configure Nginx as reverse proxy
  - |
    cat > /etc/nginx/sites-available/default << 'EOF'
    server {
        listen 80;
        server_name _;

        location / {
            proxy_pass http://localhost:${app_port};
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection keep-alive;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }
    }
    EOF
  - nginx -t && systemctl restart nginx
  - systemctl enable nginx

  # Deploy OWASP Juice Shop (Docker container)
  - mkdir -p /opt/app
  - chown azureuser:azureuser /opt/app
  - |
    su - azureuser << 'RUNME'
    docker pull bkimminich/juice-shop:latest
    docker run -d \
      --name juice-shop \
      --restart unless-stopped \
      -p 127.0.0.1:${app_port}:3000 \
      bkimminich/juice-shop:latest
    RUNME

  # Install GitHub Actions runner
  - mkdir -p /opt/actions-runner
  - chown azureuser:azureuser /opt/actions-runner
  - |
    if [ -n "${runner_token}" ]; then
      export RUNNER_URL='${runner_url}'
      export RUNNER_TOKEN='${runner_token}'
      curl -fsSL -O https://raw.githubusercontent.com/Aym3nGharbi/pfa-infrastructure/main/scripts/install_github_runner.sh
      chmod +x install_github_runner.sh
      ./install_github_runner.sh
    else
      echo "No runner token provided; skipping GitHub Actions runner installation"
    fi