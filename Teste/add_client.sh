#!/bin/bash
# add_client.sh — Cria clientes automaticamente

if [ $# -lt 1 ]; then
    echo "Uso: sudo bash add_client.sh nomeCliente"
    exit 1
fi

CLIENT=$1
WG_IF="wg0"
WG_CONF="/etc/wireguard/$WG_IF.conf"

# IP automático
BASE="10.8.0."
LAST=$(shuf -i 2-254 -n 1)
CLIENT_IP="${BASE}${LAST}/32"

echo "Gerando chaves do cliente..."
CLIENT_PRIV=$(wg genkey)
CLIENT_PUB=$(echo "$CLIENT_PRIV" | wg pubkey)

SERVER_PUB=$(sudo wg show $WG_IF public-key)
SERVER_ENDPOINT="$(curl -s ifconfig.me):51820"

echo "Adicionando peer ao servidor..."
sudo bash -c "cat >> $WG_CONF" <<EOF

# $CLIENT
[Peer]
PublicKey = $CLIENT_PUB
AllowedIPs = $CLIENT_IP
EOF

sudo systemctl restart wg-quick@$WG_IF

CLIENT_FILE="${CLIENT}.conf"

echo "Criando arquivo de configuração do cliente ($CLIENT_FILE)..."
cat > $CLIENT_FILE <<EOF
[Interface]
PrivateKey = $CLIENT_PRIV
Address = $CLIENT_IP
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUB
Endpoint = $SERVER_ENDPOINT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 20
EOF

echo "Cliente criado!"
echo "Arquivo: $CLIENT_FILE"
echo "Use esse .conf no Windows, Linux, iPhone ou Android."
