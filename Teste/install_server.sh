#!/bin/bash
# install_server.sh — Simples, direto, para Debian 12

set -e

echo "Instalando WireGuard..."
sudo apt update
sudo apt install -y wireguard wireguard-tools

WG_IF="wg0"
WG_CONF="/etc/wireguard/$WG_IF.conf"
SERVER_IP="10.8.0.1/24"
WG_PORT=51820

echo "Gerando chaves do servidor..."
SERVER_PRIV=$(wg genkey)
SERVER_PUB=$(echo "$SERVER_PRIV" | wg pubkey)

echo "Habilitando IP Forward..."
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-wireguard.conf
sudo sysctl -p /etc/sysctl.d/99-wireguard.conf

# Detectar interface de rede (para NAT)
NET_IF=$(ip -o -4 route show to default | awk '{print $5}')

echo "Criando configuração do servidor..."
sudo bash -c "cat > $WG_CONF" <<EOF
[Interface]
Address = $SERVER_IP
ListenPort = $WG_PORT
PrivateKey = $SERVER_PRIV

PostUp = iptables -t nat -A POSTROUTING -o $NET_IF -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o $NET_IF -j MASQUERADE
EOF

sudo chmod 600 $WG_CONF
sudo systemctl enable wg-quick@$WG_IF
sudo systemctl start wg-quick@$WG_IF

echo ""
echo "Servidor WireGuard instalado!"
echo "Chave pública do servidor:"
echo "$SERVER_PUB"
echo ""
echo "Pronto para adicionar clientes com: sudo bash add_client.sh nomeCliente"
