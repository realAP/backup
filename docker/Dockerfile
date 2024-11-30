FROM ubuntu:24.04

RUN apt update && apt install cron restic nextcloud-desktop-cmd ssh curl -y

# user permissions?
ADD backup.sh /bin
ADD entry.sh /bin
ADD manager.sh /bin
ADD nextcloud.sh /bin
ADD telegram.sh /bin
ADD create_ssh_config.sh /bin
RUN chmod 0744 /bin/backup.sh
RUN chmod 0744 /bin/entry.sh
RUN chmod 0744 /bin/manager.sh
RUN chmod 0744 /bin/nextcloud.sh
RUN chmod 0744 /bin/telegram.sh
RUN chmod 0744 /bin/create_ssh_config.sh

ENTRYPOINT ["entry.sh"]
