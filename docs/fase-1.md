# Fase 1 — Métricas do sistema

Ambiente: Ubuntu no WSL2 (Windows)
## Logs
- **Comandos:** `journalctl`, `journalctl -n 50`, `journalctl -p err -b`, `journalctl -u nginx`, `journalctl --since "1 hour ago"`, `journalctl --disk-usage`, `ls -lh /var/log`
- **Resultado:**
  - O journal guarda logs desde 30/09, de vários boots, e ocupa 144 MB (quase todo o `/var/log`, que tem 147 MB)
  - 16 mensagens de erro no boot atual, todas no momento da inicialização do WSL
  - Nginx sobe automaticamente a cada boot desde 01/10, sem nenhum erro registrado
  - Os arquivos `syslog`, `kern.log` e `auth.log` são gerados pelo rsyslog e duplicam o conteúdo do journal
  - Os logs são rotacionados pelo logrotate (arquivos `.1` e `.gz`)
- **Veredito:** saudável. Nenhum dos erros encontrados representa um problema real; todos são ruídos conhecidos da virtualização do WSL.

### Ruídos conhecidos do WSL
Mensagens que aparecem normalmente e devem ser ignoradas pelo monitoramento:
- `systemd-resolved: Clock change detected. Flushing caches.` — a cada 30 segundos, causado pela sincronização do relógio com o Windows
- `wsl-pro-service: could not connect to Windows Agent` — serviço do Ubuntu Pro tentando se conectar a um agente não instalado no Windows
- `PCI: Fatal: No config space access function found` — o WSL não tem barramento PCI real
- `misc dxg: dxgk: ... Ioctl failed` — driver de acesso à GPU do Windows testando recursos inexistentes
- `virtiofs: Unknown parameter`, `/dev/sdf: Can't open blockdev` e `ld.wsl.conf failed` — montagem de discos do WSL e do Docker Desktop
- `getaddrinfo() failed: -5` — teste de rede feito antes de a rede estar pronta, no boot; só é problema se repetir depois da inicialização

### Permissões
- Arquivos como `auth.log` e `syslog` pertencem ao usuário `syslog` e ao grupo `adm`, com permissão `rw-r-----`: só o dono escreve, só o grupo `adm` lê, e outros usuários não têm acesso
- O script de monitoramento vai precisar de permissão de leitura nesses logs (rodando como root ou com o usuário no grupo `adm`)

### Arquivos de histórico
- `wtmp`: histórico de logins (comando `last`)
- `btmp`: tentativas de login que falharam (comando `sudo lastb`)
- `dpkg.log`: histórico de instalação e remoção de pacotes

### Pontos de atenção
- O journald não tem limite de tamanho configurado e pode crescer até 4 GB, ocupando espaço real do disco `C:`. Definir um limite (ex.: 500 MB) em `/etc/systemd/journald.conf.d/`
- O `wsl-pro-service` gera avisos repetidos sem utilidade, já que o Ubuntu Pro não é usado. Pode ser desativado com `sudo systemctl disable --now wsl-pro.service`
- O Nginx inicia automaticamente a cada boot. Se não estiver em uso, desativar com `sudo systemctl disable --now nginx`
## CPU
- **Comandos:** `nproc`, `uptime`, `top`
- **Resultado:** 16 núcleos; load average de 0.00 / 0.03 / 0.06 (1, 5 e 15 minutos); CPU 99,8% ociosa e 0% de espera por disco (`wa`)
- **Veredito:** saudável. O load average só indicaria sobrecarga acima de 16 (número de núcleos), e a ausência de espera por disco mostra que o armazenamento não é gargalo.

## Memória
- **Comandos:** `free -h`, `top`
- **Resultado:** 3,7 GB no total, 1,9 GB disponíveis (`available`); swap de 1 GB, sem uso
- **Veredito:** saudável, mas com pouca folga. Cerca de metade da memória está livre, e o swap sem uso indica que não houve falta de memória. Se o swap começar a ser usado, é sinal de que o limite do WSL precisa ser aumentado.

## Disco
- **Comandos:** `df -h`, `sudo du -sh /var/log`, `lsblk`
- **Resultado:** partição `/` com 2% de uso em um disco virtual de 1 TB; disco `C:` do Windows com 47% de uso e 242 GB livres; `/var/log` com 147 MB
- **Veredito:** saudável. O espaço real disponível é o do disco `C:`, que tem folga. Os logs ainda ocupam pouco espaço.

## Rede e portas abertas
- **Comandos:** `ip a`, `sudo ss -tulpn`
- **Resultado:**
  - Interface `eth0` com IP 172.29.81.84 (rede interna do WSL)
  - Interface `docker0` e três redes `br-*` criadas pelo Docker, todas inativas
  - Porta 80: Nginx escutando em todas as interfaces
  - Porta 10075: Postgres do projeto Aspire Shop, apenas em localhost
  - Portas 3307 e 3308: containers MySQL, em todas as interfaces
  - Portas 53 (DNS) e 323 (sincronização de horário): serviços do sistema, apenas em localhost
- **Veredito:** atenção. Há serviços expostos em todas as interfaces (Nginx e MySQL) e um container de um projeto cancelado ainda rodando.

## Particularidades do WSL
- A memória disponível para o Linux é limitada pelo WSL, e não corresponde à memória total do computador.
- O disco `/` de 1 TB é o tamanho máximo de um disco virtual armazenado no `C:` do Windows. O espaço real disponível é o do `C:`.
- O `/dev/loop0` aparece com 100% de uso por ser uma imagem somente leitura das ferramentas do Docker Desktop. Não é um problema, e esse tipo de sistema de arquivos (`loop`, `tmpfs`, `none`) deve ser ignorado pelo monitoramento para evitar alertas falsos.
- Projetos devem ficar na pasta pessoal do Linux (`~`), e não em `/mnt/c`, para evitar problemas de permissão e de quebra de linha nos scripts.

## Pontos de atenção encontrados
- Nginx instalado no Ubuntu escutando na porta 80 em todas as interfaces: verificar se está em uso; se não estiver, desativar.
- Postgres do Aspire Shop ainda rodando na porta 10075: remover o container, já que o projeto foi cancelado.
- MySQL nas portas 3307 e 3308 acessível por todas as interfaces: avaliar se precisa estar exposto ou se pode ficar restrito ao localhost.
- Dois motores Docker na mesma máquina (`dockerd` no Ubuntu e o Docker Desktop): investigar para evitar confusão sobre onde cada container está rodando.
