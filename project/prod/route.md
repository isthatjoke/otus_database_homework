.
├── .vault_pass.txt
├── ancible.cfg
├── deploy_servers.yml
├── inventory.yml
├── group_vars/
├   └── all
├        ├── vars.yml
├        └── vault.yml
└── roles
     ├── etcd
     ├    ├── handlers
     ├    ├    └── main.yml
     ├    ├── tasks
     ├    ├    └── main.yml
     ├    └── templates
     ├         ├── etcd.conf.j2
     ├         └── etcd.service.j2
     ├── haproxy
     ├    ├── handlers
     ├    ├    └── main.yml
     ├    ├── tasks
     ├    ├    └── main.yml
     ├    └── templates
     ├         ├── haproxy.cfg.j2
     ├         └── haproxy.service.j2
     ├── postgres
     ├    ├── handlers
     ├    ├    └── main.yml
     ├    ├── tasks
     ├    ├    └── main.yml
     ├    └── templates
     ├         ├── patroni-notify.sh.j2
     ├         ├── patroni.service.j2
     ├         ├── patroni.yml.j2
     ├         └── patronictl.yml.j2
     └── setup
          ├── tasks
          ├    └── main.yml
          └── templates
              