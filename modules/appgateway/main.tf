# Public IP for App Gateway
resource "azurerm_public_ip" "appgateway" {
  name                = "${var.prefix}-appgateway-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [var.zone]
  tags                = var.tags
}

# WAF Policy
resource "azurerm_web_application_firewall_policy" "main" {
  name                = "${var.prefix}-waf-policy"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }

    managed_rule_set {
      type    = "Microsoft_BotManagerRuleSet"
      version = "1.0"
    }
  }

  custom_rules {
    name      = "RateLimitRule"
    priority  = 1
    rule_type = "RateLimitRule"
    action    = "Block"

    rate_limit_duration  = "OneMin"
    rate_limit_threshold = 100
    group_rate_limit_by  = "ClientAddr"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }
      operator           = "IPMatch"
      negation_condition = true
      match_values       = ["10.0.0.0/8"]
    }
  }

  custom_rules {
    name      = "BlockSQLiUserAgent"
    priority  = 2
    rule_type = "MatchRule"
    action    = "Block"

    match_conditions {
      match_variables {
        variable_name = "RequestHeaders"
        selector      = "User-Agent"
      }
      operator           = "Contains"
      negation_condition = false
      match_values       = ["sqlmap", "nikto", "nmap", "masscan"]
    }
  }

  custom_rules {
    name      = "BlockMaliciousPaths"
    priority  = 3
    rule_type = "MatchRule"
    action    = "Block"

    match_conditions {
      match_variables {
        variable_name = "RequestUri"
      }
      operator           = "Contains"
      negation_condition = false
      match_values       = ["/admin", "/wp-admin", "/.env", "/etc/passwd"]
    }
  }

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    max_request_body_size_in_kb = 128
    file_upload_limit_in_mb     = 100

    log_scrubbing {
      enabled = true
    }
  }
}

# App Gateway WAF v2 - Version HTTP seulement
resource "azurerm_application_gateway" "main" {
  name                = "${var.prefix}-appgateway"
  location            = var.location
  resource_group_name = var.resource_group_name
  zones               = [var.zone]
  tags                = var.tags

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "appgateway-ip-config"
    subnet_id = var.subnet_appgateway_id
  }

  frontend_ip_configuration {
    name                 = "appgateway-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgateway.id
  }

  frontend_ip_configuration {
    name                          = "appgateway-private-ip"
    subnet_id                     = var.subnet_appgateway_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.10" # Static private IP for DNAT from firewall
  }

  frontend_port {
    name = "port-80"
    port = 80
  }

  frontend_port {
    name = "port-443"
    port = 443
  }

  dynamic "ssl_certificate" {
    for_each = var.appgateway_pfx_path != "" ? [1] : []
    content {
      name     = "appgw-ssl-cert"
      data     = filebase64(var.appgateway_pfx_path)
      password = var.appgateway_pfx_password
    }
  }

  backend_address_pool {
    name         = "web-backend-pool"
    ip_addresses = [var.vm_private_ip]
  }

  backend_http_settings {
    name                  = "web-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = var.app_port
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "web-health-probe"
    host_name             = "localhost"

    connection_draining {
      enabled           = true
      drain_timeout_sec = 30
    }
  }

  probe {
    name                = "web-health-probe"
    protocol            = "Http"
    host                = "localhost"
    path                = "/"
    interval            = 30
    timeout             = 20
    unhealthy_threshold = 3

    match {
      status_code = ["200-399"]
    }
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "appgateway-frontend-ip"
    frontend_port_name             = "port-80"
    protocol                       = "Http"
    firewall_policy_id             = azurerm_web_application_firewall_policy.main.id
  }

  dynamic "http_listener" {
    for_each = var.appgateway_pfx_path != "" ? [1] : []
    content {
      name                           = "https-listener"
      frontend_ip_configuration_name = "appgateway-frontend-ip"
      frontend_port_name             = "port-443"
      protocol                       = "Https"
      ssl_certificate_name           = "appgw-ssl-cert"
      firewall_policy_id             = azurerm_web_application_firewall_policy.main.id
    }
  }

  dynamic "redirect_configuration" {
    for_each = var.appgateway_pfx_path != "" ? [1] : []
    content {
      name                 = "http-to-https-redirect"
      redirect_type        = "Permanent"
      target_listener_name = "https-listener"
      include_path         = true
      include_query_string = true
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.appgateway_pfx_path == "" ? [1] : []
    content {
      name                       = "http-to-backend"
      rule_type                  = "Basic"
      http_listener_name         = "http-listener"
      backend_address_pool_name  = "web-backend-pool"
      backend_http_settings_name = "web-http-settings"
      priority                   = 100
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.appgateway_pfx_path != "" ? [1] : []
    content {
      name                        = "http-redirect-to-https"
      rule_type                   = "Basic"
      http_listener_name          = "http-listener"
      redirect_configuration_name = "http-to-https-redirect"
      priority                    = 100
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.appgateway_pfx_path != "" ? [1] : []
    content {
      name                       = "https-to-backend"
      rule_type                  = "Basic"
      http_listener_name         = "https-listener"
      backend_address_pool_name  = "web-backend-pool"
      backend_http_settings_name = "web-http-settings"
      priority                   = 101
    }
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S"
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }
}