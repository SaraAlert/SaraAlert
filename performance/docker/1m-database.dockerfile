FROM mariadb:10.5

RUN cp -r /var/lib/mysql /var/lib/mysql-no-volume

CMD ["--datadir", "/var/lib/mysql-no-volume"]
