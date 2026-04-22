locals {
  # When the server is VNet-integrated via delegated subnet, public access must be disabled.
  public_network_access_enabled = var.delegated_subnet_id != null ? false : var.public_network_access_enabled

  tags = merge(
    { "managed-by" = "terraform" },
    var.tags
  )
}
