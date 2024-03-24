#!/bin/bash

# 定义常量
RENDER_API_KEY="your_render_api_key"
SERVICE_ID="your_service_id"
CUSTOM_DOMAIN="sub.domain.com"
CLOUDFLARE_API_TOKEN="your_cloudflare_api_token"
ZONE_ID="your_cloudflare_zone_id"
CLOUDFLARE_RECORD_NAME="_sub._domain.com"

# 获取本机IPv6地址
LOCAL_IPV6=$(ip -6 addr show scope global | grep inet6 | awk '{print $2}' | cut -d/ -f1)

# 查询Render平台自定义域名的CNAME指向地址
function query_render_cname() {
  CNAME=$(curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
             "https://api.render.com/v1/services/$SERVICE_ID/custom-domains/$CUSTOM_DOMAIN" | \
             jq -r '.dnsRecords[] | select(.type == "CNAME") | .value')
}

# 添加或更新Render平台自定义域名的CNAME记录
function update_render_cname() {
  query_render_cname
  if [[ "$CNAME" != "$LOCAL_IPV6" ]]; then
    echo "Updating CNAME record for $CUSTOM_DOMAIN to $LOCAL_IPV6..."
    curl -X PUT -H "Authorization: Bearer $RENDER_API_KEY" \
         -H "Content-Type: application/json" \
         -d "{\"dnsRecords\":[{\"type\":\"CNAME\",\"value\":\"$LOCAL_IPV6\"}]}" \
         "https://api.render.com/v1/services/$SERVICE_ID/custom-domains/$CUSTOM_DOMAIN"
  else
    echo "CNAME record for $CUSTOM_DOMAIN is already up to date ($LOCAL_IPV6)."
  fi
}

# 删除Render平台自定义域名
function delete_render_domain() {
  echo "Deleting custom domain $CUSTOM_DOMAIN..."
  curl -X DELETE -H "Authorization: Bearer $RENDER_API_KEY" \
       "https://api.render.com/v1/services/$SERVICE_ID/custom-domains/$CUSTOM_DOMAIN"
}

# 查询模块
query_render_cname
echo "Current CNAME record for $CUSTOM_DOMAIN: $CNAME"

# 更新模块
update_render_cname

# 删除模块
# delete_render_domain  # Uncomment this line to actually perform the deletion
