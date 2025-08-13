locals {
  cloud_config = <<-EOT
    #cloud-config
    ${yamlencode({
  write_files = [
    {
      path        = "/etc/systemd/system/duckdns.service"
      permissions = "0644"
      owner       = "root"
      content     = <<-EOT1
                [Unit]
                Description=Start DuckDNS

                [Service]
                ExecStart=/usr/bin/docker run --rm -e SUBDOMAINS=${var.duckdns_subdomains} -e TOKEN=${var.duckdns_token} --name=duckdns lscr.io/linuxserver/duckdns:latest

                ExecStop=/usr/bin/docker stop duckdns
                ExecStopPost=/usr/bin/docker rm duckdns
                EOT1
    },
    {
      path        = "/etc/systemd/system/caddy.service"
      permissions = "0644"
      owner       = "root"
      content     = <<-EOT2
              [Unit]
              Description=Start Caddy

              [Service]
              ExecStart=/usr/bin/docker run --rm --network custom-bridge -p 443:443 --mount 'type=bind,source=/mnt/disks/data/caddy/Caddyfile,target=/etc/caddy/Caddyfile,readonly' --mount 'type=bind,source=/mnt/disks/data/caddy/data,target=/data' --mount 'type=bind,source=/mnt/disks/data/caddy/config,target=/config' --name=caddy caddy:alpine
              ExecStop=/usr/bin/docker stop caddy
              ExecStopPost=/usr/bin/docker rm caddy
              EOT2
    },
    {
      path        = "/etc/systemd/system/actual.service"
      permissions = "0644"
      owner       = "root"
      content     = <<-EOT3
                [Unit]
                Description=Start Actual

                [Service]
                ExecStart=/usr/bin/docker run --rm --network custom-bridge -p '[::1]:5006:5006' --mount 'type=bind,source=/mnt/disks/data/actual-data,target=/data' --name=actual_server actualbudget/actual-server:latest
                ExecStop=/usr/bin/docker stop actual_server
                ExecStopPost=/usr/bin/docker rm actual_server
                EOT3
    },
    {
      path        = "/tmp/Caddyfile"
      permissions = "0644"
      owner       = "root"
      content     = <<-EOT4
            ${var.actual_fqdn} {
                encode gzip zstd
                reverse_proxy actual_server:5006
            }
            EOT4
    },
    {
      path        = "/var/lib/cloud/scripts/per-instance/fs-prepare.sh"
      permissions = "0544"
      owner       = "root"
      content     = <<-EOT5
        #!/bin/bash
      
        mkfs.ext4 -L data -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/disk/by-id/google-persistent-disk-1
        mkdir -p /mnt/disks/data
        mount -t ext4 -o nodev,nosuid /dev/disk/by-id/google-persistent-disk-1 /mnt/disks/data
        mkdir -p /mnt/disks/data/caddy
        mkdir -p /mnt/disks/data/caddy/data
        mkdir -p /mnt/disks/data/caddy/config
        mkdir -p /mnt/disks/data/actual-data
        cp /tmp/Caddyfile /mnt/disks/data/caddy/Caddyfile
        EOT5
    },
    {
      path        = "/etc/systemd/system/bank_sync.service"
      permissions = "0644"
      owner       = "root"
      content     = <<-EOT6
                [Unit]
                Description=Start Bank Sync

                [Service]
                ExecStart=docker run -e ACTUAL_SERVER_URL="YOUR_SEVER_URL_SHOULD_INCLUDE_FINAL_BACKSLASH" -e ACTUAL_SERVER_PASSWORD='yourPassword' -e CRON_SCHEDULE="0 1 * * *" -e LOG_LEVEL="info" -e ACTUAL_BUDGET_SYNC_IDS="481d4273-bc76-47fb-8001-e8a26eb8912c[groupIdInMedatada.json]" -e TIMEZONE="UTC" -e RUN_ON_START="true" -e ENCRYPTION_PASSWORDS="" --name=bank_sync seriouslag/actual-auto-sync:latest
                ExecStop=/usr/bin/docker stop bank_sync
                ExecStopPost=/usr/bin/docker rm bank_sync
                EOT6
    }
  ]

  runcmd = [
    "docker network create custom-bridge",
    "systemctl daemon-reload",
    "systemctl start caddy.service",
    "systemctl start actual.service",
    "systemctl start duckdns.service",
    "systemctl start bank_sync.service"
  ]

  bootcmd = [
    "fsck.ext4 -tvy /dev/disk/by-id/google-persistent-disk-1",
    "mkdir -p /mnt/disks/data",
    "mount -t ext4 -o nodev,nosuid /dev/disk/by-id/google-persistent-disk-1 /mnt/disks/data",
    "mkdir -p /mnt/disks/data/caddy",
    "mkdir -p /mnt/disks/data/caddy/data",
    "mkdir -p /mnt/disks/data/caddy/config",
    "mkdir -p /mnt/disks/data/actual-data"
  ]
})}
  EOT
}
