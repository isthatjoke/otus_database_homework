#!/bin/bash

MEMBER=$(hostname -s)

echo "[$(date)] Patroni callback: Event=$1, Role=$2, Cluster=$3, Member=$MEMBER"

if [ "$1" = "on_role_change" ]; then
    echo "🔄 ROLE CHANGE: Member $MEMBER is now $2 in cluster $3"
    
    # Отправка в ntfy
    if command -v wget >/dev/null 2>&1; then
        NTFY_TOPIC="abbott_test_alerts"
        NTFY_URL="https://ntfy.sh"
        
        MESSAGE="PostgreSQL Failover
Cluster: $3
Node: $MEMBER
New Role: $2
Time: $(date)"
        
        wget -q -O /dev/null \
            --post-data="$MESSAGE" \
            --header="Title: 🐘 PostgreSQL Role Change" \
            --header="Priority: high" \
            --header="Tags: postgresql,database" \
            "$NTFY_URL/$NTFY_TOPIC" && \
        echo "📢 Notification sent to ntfy" || \
        echo "❌ Failed to send notification"
    else
        echo "❌ wget not available"
    fi
fi