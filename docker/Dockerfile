FROM ubuntu:24.04

RUN apt update && apt install cron restic nextcloud-desktop-cmd ssh curl postgresql-client -y

# user permissions?
ADD backup.sh /bin
ADD entry.sh /bin
ADD manager.sh /bin
ADD nextcloud.sh /bin
ADD prepare.sh /bin
ADD prepare_ssh.sh /bin
ADD telegram.sh /bin

RUN chmod 0744 /bin/backup.sh
RUN chmod 0744 /bin/entry.sh
RUN chmod 0744 /bin/manager.sh
RUN chmod 0744 /bin/nextcloud.sh
RUN chmod 0744 /bin/prepare.sh
RUN chmod 0744 /bin/prepare_ssh.sh
RUN chmod 0744 /bin/telegram.sh

ENTRYPOINT ["entry.sh"]
