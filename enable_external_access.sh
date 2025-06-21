#!/bin/bash
# Enable external access to Chrome debugging via socat

set -e

# Source utilities
source "lib/utils.sh"

echo "🌐 Enabling Chrome External Access"
echo "=================================="
echo ""

# Check if Chrome is running
if ! pgrep -f "remote-debugging-port=9222" > /dev/null; then
    log_error "Chrome is not running on port 9222"
    log_info "Start Chrome first: ./start.sh"
    exit 1
fi

# Test local Chrome connection
if ! curl -s http://localhost:9222/json/version > /dev/null; then
    log_error "Chrome debugging interface is not accessible locally"
    exit 1
fi

log_success "Chrome is running and accessible locally"

# Check if socat is installed
if ! command_exists socat; then
    log_info "Installing socat for port forwarding..."
    sudo apt update
    sudo apt install -y socat
    log_success "socat installed"
fi

# Choose external port
EXTERNAL_PORT=9223
while ! is_port_available $EXTERNAL_PORT; do
    log_warning "Port $EXTERNAL_PORT is in use, trying next port..."
    ((EXTERNAL_PORT++))
done

log_info "Using external port: $EXTERNAL_PORT"

# Kill any existing socat processes for Chrome
pkill -f "socat.*9222" 2>/dev/null || true
sleep 1

# Start socat port forwarding
log_info "Starting port forwarding: $EXTERNAL_PORT -> 9222"
socat TCP-LISTEN:$EXTERNAL_PORT,fork,reuseaddr TCP:127.0.0.1:9222 &
SOCAT_PID=$!

# Save socat PID
echo $SOCAT_PID > socat-chrome.pid
log_success "Port forwarding started (PID: $SOCAT_PID)"

# Wait for socat to start
sleep 2

# Test external access
log_info "Testing external access..."
if curl -s http://localhost:$EXTERNAL_PORT/json/version > /dev/null; then
    log_success "External access is working!"
    
    # Get server IP
    EXTERNAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "Unknown")
    
    echo ""
    echo "🎉 Chrome External Access Enabled!"
    echo "=================================="
    echo ""
    echo "Local Access:"
    echo "  http://localhost:9222"
    echo ""
    echo "External Access:"
    echo "  http://localhost:$EXTERNAL_PORT (from this server)"
    if [[ "$EXTERNAL_IP" != "Unknown" ]]; then
        echo "  http://$EXTERNAL_IP:$EXTERNAL_PORT (from other servers)"
    fi
    echo ""
    echo "Test Commands:"
    echo "  curl http://localhost:$EXTERNAL_PORT/json/version"
    if [[ "$EXTERNAL_IP" != "Unknown" ]]; then
        echo "  curl http://$EXTERNAL_IP:$EXTERNAL_PORT/json/version"
    fi
    echo ""
    echo "Management:"
    echo "  Stop forwarding: kill $SOCAT_PID"
    echo "  Check status: ./status.sh"
    echo ""
    
    # Test from external IP if possible
    if [[ "$EXTERNAL_IP" != "Unknown" ]]; then
        log_info "Testing external IP access..."
        if timeout 5 curl -s http://$EXTERNAL_IP:$EXTERNAL_PORT/json/version > /dev/null 2>&1; then
            log_success "External IP access confirmed!"
        else
            log_warning "External IP access may be blocked by firewall"
            log_info "Check firewall settings if external access doesn't work"
        fi
    fi
    
else
    log_error "External access test failed"
    kill $SOCAT_PID 2>/dev/null || true
    exit 1
fi
