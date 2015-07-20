# Bill.im uses Waterline for its database - if you have questions about this
# config file, please refer to https://github.com/balderdashy/waterline
module.exports = 
  adapters:
    default: require 'sails-disk'
    memory: require 'sails-memory'
    disk: require 'sails-disk'
    postgres: require 'sails-postgresql'
  connections:
    default:
      adapter: 'postgres'
      database: 'postgres',
      host: process.env.POSTGRES_1_PORT_5432_TCP_ADDR,
      user: 'postgres',
      password: process.env.POSTGRES_1_ENV_POSTGRES_PASSWORD,
      port: parseInt process.env.POSTGRES_1_PORT_5432_TCP_PORT,
      pool: false,
      ssl: false
  defaults:
    migrate: 'alter'
