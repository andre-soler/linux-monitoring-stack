# Fase 1 — Métricas do sistema

Ambiente: Ubuntu no WSL2 (Windows)

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
