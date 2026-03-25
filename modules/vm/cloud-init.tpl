#cloud-config
package_update: true
package_upgrade: true

packages:
  - nginx
  - curl
  - unzip
  - apt-transport-https

runcmd:
  # Install .NET 8 runtime
  - curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 8.0 --runtime aspnetcore --install-dir /usr/share/dotnet
  - ln -s /usr/share/dotnet/dotnet /usr/local/bin/dotnet

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

  # Create app directory
  - mkdir -p /opt/app
  - chown azureuser:azureuser /opt/app

  # GitHub Actions runner will be configured via GitHub UI after VM is created
  - mkdir -p /opt/actions-runner
  - chown azureuser:azureuser /opt/actions-runner