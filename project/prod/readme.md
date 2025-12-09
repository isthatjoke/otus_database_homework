- написание конфигурации для ansible
- создание файла с паролем для шифрования 
```bash
echo "pwd123" > .vault_pass.txt
chmod 600 ./.vault_pass.txt
```
- разделение файлов с переменными на обычный и секретный
- шифруем секретный файл
```bash
ansible-vault encrypt ./group_vars/all/vault.yml
```
- создание dockerfile.vm и docker-compose.yml
- запуск контейнеров
```bash
sudo docker compose up -d
```
- запускаем ansible
```bash
ansible-playbook -i ./inventory.yml ./deploy_servers.yml
```
