resource "azurerm_kubernetes_cluster" "pc_compute" {
  name                      = "${var.maybe_versioned_prefix}-cluster"
  location                  = azurerm_resource_group.pc_compute.location
  resource_group_name       = azurerm_resource_group.pc_compute.name
  dns_prefix                = "${var.maybe_versioned_prefix}-cluster"
  kubernetes_version        = var.kubernetes_version
  sku_tier                  = "Standard"
  automatic_channel_upgrade = var.aks_automatic_channel_upgrade

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.pc_compute.id
  }

  # microsoft_defender {
  #   log_analytics_workspace_id = data.azurerm_key_vault_secret.microsoft_defender_log_analytics_workspace_id.value
  # }

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  # Just setting this to match the preview default. Maybe enable in the future.
  image_cleaner_enabled        = false
  image_cleaner_interval_hours = 48

  # Core node-pool
  default_node_pool {
    name            = "core"
    vm_size         = var.core_vm_size
    os_disk_size_gb = 100
    # Managed for staging, since A-series VM don't support Ephemeral
    os_disk_type        = var.core_os_disk_type
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 5
    vnet_subnet_id      = azurerm_subnet.node_subnet.id
    node_labels = {
      "hub.jupyter.org/node-purpose" = "core"
    }

    orchestrator_version = var.kubernetes_version
  }

  auto_scaler_profile {
    empty_bulk_delete_max       = "50"
    scale_down_unready          = "2m"
    scale_down_unneeded         = "2m"
    scale_down_delay_after_add  = "5m"
    skip_nodes_with_system_pods = false # ensures system pods don't keep GPU nodes alive
  }
  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "DEP"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user_pool" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.pc_compute.id
  vm_size               = var.user_vm_size
  enable_auto_scaling   = true
  os_disk_size_gb       = 200
  node_taints           = ["hub.jupyter.org_dedicated=user:NoSchedule"]
  vnet_subnet_id        = azurerm_subnet.node_subnet.id

  orchestrator_version = var.kubernetes_version
  node_labels = {
    "hub.jupyter.org/pool-name"    = "user-alpha-pool",
    "hub.jupyter.org/node-purpose" = "user",
  }

  min_count = var.user_pool_min_count
  max_count = 50

  zones = []

  tags = {
    Environment = "Production"
    ManagedBy   = "DEP"
  }

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }
}


resource "azurerm_kubernetes_cluster_node_pool" "user_pool_2x" {
  name                  = "user2x"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.pc_compute.id
  vm_size               = "Standard_E16s_v3"
  enable_auto_scaling   = true
  os_disk_size_gb       = 200
  node_taints           = ["hub.jupyter.org_dedicated=user:NoSchedule"]
  vnet_subnet_id        = azurerm_subnet.node_subnet.id

  orchestrator_version = var.kubernetes_version
  node_labels = {
    "hub.jupyter.org/pool-name"    = "user-alpha-pool-2x",
    "hub.jupyter.org/node-purpose" = "user",
  }

  min_count = var.user_pool_min_count
  max_count = 20

  zones = []

  tags = {
    Environment = "Production"
    ManagedBy   = "DEP"
  }

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "cpu_worker_pool" {
  name                  = "cpuworker2"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.pc_compute.id
  vm_size               = var.cpu_worker_vm_size
  enable_auto_scaling   = true
  os_disk_size_gb       = 128
  orchestrator_version  = var.kubernetes_version
  vnet_subnet_id        = azurerm_subnet.node_subnet.id
  priority              = "Spot"
  spot_max_price        = -1
  eviction_policy       = "Delete"

  node_labels = {
    "k8s.dask.org/dedicated"                = "worker",
    "pc.microsoft.com/workerkind"           = "cpu",
    "kubernetes.azure.com/scalesetpriority" = "spot"
  }

  node_taints = [
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule",
  ]

  min_count = var.cpu_worker_pool_min_count
  max_count = var.cpu_worker_max_count
  tags = {
    Environment = "Production"
    ManagedBy   = "DEP"
  }

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }
}


resource "azurerm_kubernetes_cluster_node_pool" "argo_worker_pool" {
  name                  = "argoworker"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.pc_compute.id
  vm_size               = var.cpu_worker_vm_size
  enable_auto_scaling   = true
  os_disk_size_gb       = 128
  orchestrator_version  = var.kubernetes_version
  vnet_subnet_id        = azurerm_subnet.node_subnet.id
  priority              = "Spot"
  spot_max_price        = -1
  eviction_policy       = "Delete"

  node_labels = {
    "digitalearthpacific.org/node-purpose" = "argo",
    "kubernetes.azure.com/scalesetpriority" = "spot"
  }
  node_taints = [
    "digitalearthpacific.org/node-purpose=argo:NoSchedule",
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule",
  ]

  min_count = var.cpu_worker_pool_min_count
  max_count = var.cpu_worker_max_count

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "argo_worker_pool_d4" {
  name                  = "argoworkerd4"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.pc_compute.id
  vm_size               = "Standard_D48s_v4"
  enable_auto_scaling   = true
  os_disk_size_gb       = 128
  orchestrator_version  = var.kubernetes_version
  vnet_subnet_id        = azurerm_subnet.node_subnet.id
  priority              = "Spot"
  spot_max_price        = -1
  eviction_policy       = "Delete"

  node_labels = {
    "digitalearthpacific.org/node-purpose" = "argo-d4",
    "kubernetes.azure.com/scalesetpriority" = "spot"
  }
  node_taints = [
    "digitalearthpacific.org/node-purpose=argo:NoSchedule",
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule",
  ]

  min_count = var.cpu_worker_pool_min_count
  max_count = var.cpu_worker_max_count

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }
}
