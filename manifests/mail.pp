# Install and configure mailserver
class role_waarneming::mail (
) {
  # Install postfix
  # Configure to listen only on local interfaces
  class { '::postfix':
    inet_interfaces => '127.0.0.1, [::1]',
  }
}
