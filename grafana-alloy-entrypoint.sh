#!/bin/bash

# WORK_DIR="$(pwd)"
WORK_DIR="/configs"
SERVER_LABEL_HOSTNAME="$1"

# -----------------------------------------------------------------------------------------------------
# Start fresh every time
cat > "$WORK_DIR/agent.yml" << EOF
server:
  log_level: info

metrics:
  configs:
    - name: default
EOF

# -----------------------------------------------------------------------------------------------------
# Set metrics section
sed -e 's/^/      /' "$WORK_DIR/prometheus.yml" >> "$WORK_DIR/agent.yml"
if [ -s "$WORK_DIR/prometheus-remoteurl.yml" ]; then
  echo >> "$WORK_DIR/agent.yml"
  sed -e 's/^/  /' "$WORK_DIR/prometheus-remoteurl.yml" >> "$WORK_DIR/agent.yml"
fi

# -----------------------------------------------------------------------------------------------------
# Set logs section
echo >> "$WORK_DIR/agent.yml"
sed -e 's/^//' "$WORK_DIR/promtail.yml" >> "$WORK_DIR/agent.yml"
if [ -s "$WORK_DIR/promtail-lokiurl.yml" ]; then
  echo >> "$WORK_DIR/agent.yml"
  sed -e 's/^/    /' "$WORK_DIR/promtail-lokiurl.yml" >> "$WORK_DIR/agent.yml"
else
cat >> "$WORK_DIR/agent.yml" << EOF

  clients:
    - url: http://loki:3100/loki/api/v1/push
EOF
fi

# # -----------------------------------------------------------------------------------------------------
# # Set traces section
# echo >> "/agent.yml" && cat "/agent-traces-config.yml" >> "/agent.yml"

# # -----------------------------------------------------------------------------------------------------
# # Set intergrations section
# echo >> "/agent.yml" && cat "/agent-intergrations-config.yml" >> "/agent.yml"

# -----------------------------------------------------------------------------------------------------
sed -i "s/SERVER_LABEL_HOSTNAME/$SERVER_LABEL_HOSTNAME/" "$WORK_DIR/agent.yml"
exec /usr/bin/alloy run $WORK_DIR/agent.yml --config.format=static --server.http.listen-addr=0.0.0.0:12345 --storage.path=/data-alloy
