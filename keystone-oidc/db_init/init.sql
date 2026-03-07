-- Crea database di Iotronic e Keystone
CREATE DATABASE IF NOT EXISTS iotronic CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE IF NOT EXISTS keystone CHARACTER SET utf8 COLLATE utf8_general_ci;

-- Crea utenti
CREATE USER IF NOT EXISTS 'iotronic'@'%' IDENTIFIED BY 'unime';
CREATE USER IF NOT EXISTS 'keystone'@'%' IDENTIFIED BY 'unime';

-- Concedi privilegi
GRANT ALL PRIVILEGES ON iotronic.* TO 'iotronic'@'%';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%';
FLUSH PRIVILEGES;