#!/bin/bash

# Update the package repository
sudo dnf update -y

# Install Nginx
sudo dnf install -y nginx

# Create directories for the services
sudo mkdir -p /usr/share/nginx/html/${service_name}
sudo mkdir -p /usr/share/nginx/html/${service_name}/again

# Create a Hello World page for /${service_name}
echo "<html>
<head><title>${service_name}</title></head>
<body>
<h1>Hello World from ${service_name}</h1>
<dl>
<dt>Domain</dt>
<dd>$(hostname -f)</dd>
</dl>
</body>
</html>" | sudo tee /usr/share/nginx/html/${service_name}/index.html

# Create a Hello World page for /${service_name}/again
echo "<html>
<head><title>${service_name} Again</title></head>
<body>
<h1>Hello Again from ${service_name}</h1>
<dl>
<dt>Domain</dt>
<dd>$(hostname -f)</dd>
</dl>
</body>
</html>" | sudo tee /usr/share/nginx/html/${service_name}/again/index.html

# Configure Nginx to serve the pages
sudo bash -c 'cat > /etc/nginx/conf.d/${service_name}.conf' <<EOF
server {
    listen 80;
    server_name localhost;

    location /${service_name} {
        alias /usr/share/nginx/html/${service_name};
        index index.html;
    }

    location /${service_name}/again {
        alias /usr/share/nginx/html/${service_name}/again;
        index index.html;
    }
}
EOF

# Remove the default server block to avoid conflicts
sudo rm /etc/nginx/conf.d/default.conf

# Start and enable Nginx to run on boot
sudo systemctl start nginx
sudo systemctl enable nginx

echo "Nginx has been installed and configured to serve the Hello World pages."
